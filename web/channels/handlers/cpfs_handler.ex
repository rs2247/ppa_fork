defmodule Ppa.CpfsHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  # import Ppa.Util.Sql
  # import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.CpfsHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_data(socket, params) do
    { initialDate, finalDate } = Ppa.PanelHandler.load_dates(params)
    university_id = params["value"]["id"]

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    query = "
SELECT DISTINCT ON (bu.cpf) bu.cpf,
                         o.id,
                         o.base_user_id,
                         bu.name as user_name,
                         cr.NAME course_name,
                         OF.discount_percentage,
                         cp.NAME campus_name,
                         cr.shift,
                         cr.kind,
                         cr.level
      FROM   #{qb_schema}orders o
             INNER JOIN #{qb_schema}base_users bu ON (bu.id = o.base_user_id)
             INNER JOIN #{qb_schema}cpf_hash_blocks_counters c
                    ON ( c.cpf = bu.cpf)
             INNER JOIN #{qb_schema}line_items li
                    ON ( li.order_id = o.id )
             INNER JOIN #{qb_schema}offers OF
                    ON ( OF.id = li.offer_id )
             INNER JOIN #{qb_schema}courses cr
                    ON ( cr.id = OF.course_id )
             INNER JOIN #{qb_schema}campuses cp
                    ON ( cp.id = cr.campus_id )
      WHERE  o.created_at BETWEEN '#{to_iso_date_format(initialDate)}' AND '#{to_iso_date_format(finalDate)}'
             AND of.university_id = #{university_id} AND c.university_id = #{university_id} AND c.created_at < '#{to_iso_date_format(finalDate)}'
             AND o.created_at <= c.updated_at AND c.created_at - interval '2 days' < o.created_at
      ORDER  BY cpf,
                o.created_at DESC;"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    reponse_map = %{
      cpf_list: resultset_map,
      n_block: resultset.num_rows
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      regions: region_options(),
      # locationTypes: Enum.filter(location_types(), &(&1.type != "campus")),
      # groupTypes: group_options(),
      # accountTypes: map_simple_name(account_type_options()),
      # groups: map_simple_name(groups()),
      # dealOwners: map_simple_name(deal_owners(capture_period_id)),
      # qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      # courses: courses,
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end

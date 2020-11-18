defmodule Ppa.BoPanelHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.BoPanelHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_load_bo_data(socket, params) do
    Logger.info "Ppa.BoPanelHandler::handle_load_bo_data# params: #{inspect params}"
    Tasks.async_handle((fn -> load_bo_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def load_bo_data(socket, %{"operation_id" => operation_id}) do
    query = "select content, date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, created_at))) created from bo_comments where bo_operation_id = #{operation_id} order by created_at"

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Logger.info "load_bo_data# resultset_map: #{inspect resultset_map}"

    comments = Enum.map(resultset_map, fn entry ->
      %{ content: entry["content"], created_at: format_local(entry["created"]) }
    end)

    reponse_map = %{
      comments: comments
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "boData", reponse_map)
  end

  def async_load_data(socket, params) do
    universities = map_ids(params["universities"])
    group_ids = map_ids(params["groups"])
    groups_ies_ids = groups_ies(group_ids)

    universities = universities ++ groups_ies_ids

    period_where = if is_nil(params["initialDate"]) or is_nil(params["finalDate"]) do
      ""
    else
      { initialDate, finalDate } = Ppa.PanelHandler.load_dates(params)
      "AND bo.created_at BETWEEN '#{to_iso_date_format(initialDate)}' AND '#{to_iso_date_format(finalDate)}'"
    end


    cpf = params["cpf"]
    cpf_where = if !is_nil(cpf) && cpf != "" do
      "AND regexp_replace(bo.cpf, '[^0-9]', '', 'g') = '#{cpf |> String.replace(~r/[^\d]/, "")}'"
    else
      ""
    end

    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    status = map_ids(params["status"])
    reasons = map_ids(params["reasons"])

    universities_where = and_if_not_empty(populate_or_omit_field("u.id", universities))
    kinds_where = and_if_not_empty(populate_or_omit_field("parent_k.id", kinds))
    levels_where = and_if_not_empty(populate_or_omit_field("parent_l.id", levels))
    status_where = and_if_not_empty(populate_or_omit_field("bo.status", quotes(status)))
    reasons_where = and_if_not_empty(populate_or_omit_field("bo.reason", quotes(reasons)))

    query = "
    SELECT
      bo.id,
      bo.related_type,
      u.id as university_id,
      u.name as university_name,
      eg.name as education_group,
      bo.status,
      bo.cpf,
      c.name as course,
      c.shift as shift,
      parent_l.name as level,
      parent_k.name as kind,
      cp.name as campus,
      date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, bo.created_at))) as creation_date,
      date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, bo.updated_at))) as update_date,
      br.description as reason,
      bfr.description as final_reason,
      bo.observations,
      deal_owners.account_type as carteira,
      au_udo.email as farmer,
      au_uqo.email as quali,
      bo.originator
     FROM   bo_operations bo
     INNER JOIN bo_reasons br
             ON (br.key = bo.reason)
     LEFT JOIN bo_final_reasons bfr
             ON (bfr.key = bo.final_reason)
     LEFT JOIN line_items li
             ON ( li.order_id = bo.related_id and bo.related_type = 'Order')
     LEFT join offers of
             ON (of.id = case when bo.related_type = 'Offer' then bo.related_id else li.offer_id end)
     LEFT join courses c
             ON (c.id = case when bo.related_type = 'Course' then bo.related_id else of.course_id end)
     LEFT join campuses cp
             ON (cp.id = case when bo.related_type = 'Campus' then bo.related_id else c.campus_id end )
     LEFT join universities u
             ON (u.id = case when bo.related_type = 'University' then bo.related_id else cp.university_id end)

     LEFT JOIN education_groups eg
             ON ( eg.id = u.education_group_id )
     LEFT JOIN levels l
             ON ( l.NAME = c.level
                  AND l.parent_id IS NOT NULL )
     LEFT JOIN kinds k
             ON ( k.NAME = c.kind
                  AND k.parent_id IS NOT NULL )
     LEFT JOIN levels parent_l
             ON ( parent_l.id = l.parent_id )
     LEFT JOIN kinds parent_k
             ON ( parent_k.id = k.parent_id )
     LEFT JOIN ( #{owners_product_line("university_deal_owners")} ) deal_owners on (
        deal_owners.university_id = u.id and
        k.parent_id = any(deal_owners.kinds) and
        l.parent_id = any(deal_owners.levels)
      )
    LEFT JOIN ( #{owners_product_line("university_quality_owners")} ) quality_owners on (
       quality_owners.university_id = u.id and
       k.parent_id = any(quality_owners.kinds) and
       l.parent_id = any(quality_owners.levels)
     )
     LEFT JOIN admin_users au_udo ON (au_udo.id = deal_owners.admin_user_id)
     LEFT JOIN admin_users au_uqo ON (au_uqo.id = quality_owners.admin_user_id)
     WHERE
        true
        #{period_where}
        #{universities_where}
        #{status_where}
        #{reasons_where}
        #{kinds_where}
        #{levels_where}
        #{cpf_where}"

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    resultset_response = Enum.map(resultset_map, fn entry ->
      entry
        |> Map.put("creation_date", format_local(entry["creation_date"]))
        |> Map.put("creation_date_raw", to_iso_date_format(entry["creation_date"]))
        |> Map.put("update_date", format_local(entry["update_date"]))
        |> Map.put("update_date_raw", to_iso_date_format(entry["update_date"]))
        |> Map.put("farmer", Ppa.AdminUser.pretty_name(entry["farmer"]))
        |> Map.put("quali", Ppa.AdminUser.pretty_name(entry["quali"]))
    end)

    reponse_map = %{
      bos: resultset_response
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def owners_product_line(table) do
    "select #{table}.id, #{table}.admin_user_id, #{table}.university_id, #{table}.account_type, array_agg(distinct pll.level_id) as levels, array_agg(distinct plk.kind_id) as kinds from
        #{table}
        LEFT JOIN product_lines pl
        ON        (pl.id = #{table}.product_line_id)
        LEFT JOIN product_lines_levels pll
        ON        (pll.product_line_id = pl.id)
        LEFT JOIN product_lines_kinds plk
        ON        (plk.product_line_id = pl.id)
        WHERE end_date IS NULL
        GROUP BY  #{table}.id"
  end

  def bo_reasons do
    query = from reason in "bo_reasons",
      select: %{ id: reason.key, name: reason.description },
      order_by: [ desc: reason.id]
    query |> Ppa.RepoQB.all
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      regions: region_options(),
      groups: map_simple_name(groups()),
      filters: filters,
      status: [
        %{ name: "Novo", id: "new" },
        %{ name: "Resolvido", id: "resolved" },
        %{ name: "Em Progresso", id: "in_progress" }
      ],
      reasons: bo_reasons(),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end

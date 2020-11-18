defmodule Ppa.PaidsHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  # import Math
  require Tasks

  @statuses %{
    "initiated" => "Processo Seletivo Pendente",
    "pre_registered" => "Agendamento Solicitado",
    "registered" => "Agendamento Confirmado",
    "approved" => "Aprovado",
    "failed" => "Reprovado",
    "pending_docs" => "Documentação pendente",
    "partially_submitted_docs" => "Documentação de bolso enviada",
    "submitted_docs" => "Documentação enviada",
    "rejected_docs" => "Documentação rejeitada",
    "rejected_enrollment" => "atrícula rejeitada",
    "awaiting_enrollment" => "Aguardando Matrícula",
    "enrolled" => "Matriculado",
    "dropping_out" => "Desistindo",
    "drop_out_confirmed" => "Desistência confirmada",
    "dropped_out" => "Desistente"
  }

  def handle_load_data(socket, params) do
    Logger.info "Ppa.PaidsHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_data(socket, params) do
    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    # end_where = " AND date(o.end) >= '#{to_iso_date_format(end_initial_date)}' AND date(o.end) <= '#{to_iso_date_format(end_final_date)}'"
    # start_where = " AND date(o.start) >= '#{to_iso_date_format(start_initial_date)}' AND date(o.start) <= '#{to_iso_date_format(start_final_date)}'"

    ies_ids = case params["type"] do
      "universities" -> map_ids(params["value"])
      "university" -> [params["value"]["id"]]
      "group" -> group_ies(params["value"]["id"])
    end

    levels_ids = map_ids(params["levels"])
    kinds_ids = map_ids(params["kinds"])
    semesters = map_ids(params["semesters"])

    levels_where = and_if_not_empty(populate_or_omit_field("l.parent_id", levels_ids))
    kinds_where = and_if_not_empty(populate_or_omit_field("k.parent_id", kinds_ids))
    semesters_where = and_if_not_empty(populate_or_omit_field("uo.enrollment_semester", quotes(semesters)))

    query = "
    SELECT
      c.id coupon_id, c.name coupon_name, c.cpf cpf,
      (ARRAY_AGG(p.normalized_phone))[1] telefone,
      (ARRAY_AGG(em.email))[1] email,
      o.price price, of.position,
      uo.full_price full_price, of.offered_price offered_price, of.discount_percentage discount_percentage,
      of.real_discount fixed_discount_percentage,
      of.commercial_discount punctuality_discount_percentage,
      of.regressive_commercial_discount regressive_discount,
      to_char(c.enabled_at, 'DD/MM/YYYY') enabled_at, co.id course_id, co.name name_course, co.kind kind,
      co.shift shift, co.level, co.max_periods, co.period_kind, uo.enrollment_semester enrollment_semester,
      ca.id campus_id, ca.name campus_name, ca.city campus_city, ca.state campus_state,
      u.id university_id, u.name university_name, u.full_name university_full_name,
      eg.name educational_group, fu.step as integration_step
    FROM coupons c
      LEFT JOIN offers of ON of.id = c.offer_id
      LEFT JOIN university_offers uo ON uo.id = of.university_offer_id
      LEFT JOIN courses co ON co.id = c.course_id
      LEFT JOIN levels l ON l.name = co.level and l.parent_id is not null
      LEFT JOIN kinds k ON k.name = co.kind and k.parent_id is not null
      LEFT JOIN campuses ca ON ca.id = co.campus_id
      LEFT JOIN universities u ON u.id = co.university_id
      LEFT JOIN education_groups eg ON eg.id = u.education_group_id
      LEFT JOIN orders o ON o.id = c.order_id
      LEFT JOIN base_users bu ON bu.id = o.base_user_id
      LEFT JOIN base_users_phones up ON bu.id = up.base_user_id
      LEFT JOIN phones p ON p.id = up.phone_id
      LEFT JOIN emails em ON em.base_user_id = bu.id
      LEFT JOIN follow_ups fu ON fu.order_id = c.order_id
      WHERE c.status='enabled'
        AND u.id in (#{Enum.join(ies_ids, ",")})
        #{levels_where}
        #{kinds_where}
        #{semesters_where}
        AND date(c.enabled_at) between '#{to_iso_date_format(initial_date)}' and '#{to_iso_date_format(final_date)}'
      GROUP BY c.id, o.id, co.id, ca.id, u.id, eg.id, of.id, uo.id, fu.id
      ORDER BY c.cpf
        "

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    resultset_map = Enum.map(resultset_map, fn entry ->
      entry
        |> Map.put("integration_step", @statuses[entry["integration_step"]])
    end)

    reponse_map = %{
      paids: resultset_map
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    next_capture_period = Ppa.CapturePeriod.next_capture_period(capture_period)

    semester_options = Enum.map([previous_capture_period.name, capture_period.name, next_capture_period.name], &(%{ name: &1, id: &1}))

    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      semester_options: semester_options,
      states: states_options(),
      regions: region_options(),
      # locationTypes: Enum.filter(location_types(), &(&1.type != "campus")),
      groupTypes: group_options(),
      # accountTypes: map_simple_name(account_type_options()),
      groups: map_simple_name(groups()),
      # dealOwners: map_simple_name(deal_owners(capture_period_id)),
      # qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      # courses: courses,
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end

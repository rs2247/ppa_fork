defmodule Ppa.OffersHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  # import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.OffersHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_export_data(socket, params) do
    Logger.info "Ppa.OffersHandler.handle_export_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_export_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_export_data(socket, params) do
    { resultset_map , rows_count } = execute_load_offers(params, socket.assigns.capture_period, nil)

    Logger.info "async_export_data# rows_count: #{rows_count}"

    data = Enum.map(resultset_map, fn row ->
      Enum.reduce(Map.keys(row), %{}, fn entry, acc ->
        Map.put(acc, entry, "#{row[entry]}")
      end)
    end)

    base_filename = "ofertas.xlsx"
    filename = to_charlist(base_filename)
    {_filename, xlsx} = Ppa.XLSMaker.from_map_list(data, [
      {"ID Curso", "course_id"},
      {"ID Oferta", "offer_id"},
      {"Curso", "course_name"},
      {"IES", "university_name"},
      {"Grupo", "group_name"},
      {"Nível", "level"},
      {"Modalidade", "kind"},
      {"Turno", "shift"},
      {"Campus ID", "campus_id"},
      {"Campus", "campus_name"},
      {"Cidade", "campus_city"},
      {"Estado", "campus_state"},
      {"Semestre", "semester"},
      {"Ativada", "enabled"},
      {"Visível", "visible"},
      {"Ocultar preços", "hide_prices"},
      {"Limitada", "limited"},
      {"Restrita", "restricted"},
      {"Início", "start_date"},
      {"Fim", "end_date"},
      {"Desconto", "discount_percentage"},
      {"Desconto Comercial", "commercial_discount"},
      {"Desconto Comercial Regressivo", "regressive_commercial_discount"},
      {"Campanha", "campaign"},
      {"Preço Cheio", "full_price"},
      {"Preço Oferecido", "offered_price"},
      {"Preços de pré-matrícula", "pre_enrollment_fees"},
      {"Total de Bolsas", "total_seats"},
      {"Pagos", "paid_seats"},
      {"Status", "status"},
      {"On Search", "show_on_main_search"},
      {"Position", "position"},
      {"Canal Aberto", "open_channel_type"},
    ], sheetname: "ofertas", filename: filename)

    encoded_xlsx = Base.encode64(xlsx)

    reponse_map = %{
      xlsx: encoded_xlsx,
      contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      filename: base_filename,
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableDownload", reponse_map)
  end

  def async_load_data(socket, params) do
    # start_initial_date = load_date_field(params, "startInitialDate")
    # start_final_date = load_date_field(params, "startFinalDate")

    { resultset_map, num_rows } = execute_load_offers(params, socket.assigns.capture_period, 5000)

    data_limit = if num_rows == 5000 do
      true
    else
      false
    end

    reponse_map = %{
      offers: resultset_map,
      data_limit: data_limit
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def execute_load_offers(params, capture_period_id, limit \\ 5000) do

    start_date = load_date_field(params, "dateStart")

    # end_initial_date = load_date_field(params, "endInitialDate")
    # end_final_date = load_date_field(params, "endFinalDate")

    semesters = params["semesters"]
    semesters_where = and_if_not_empty(populate_or_omit_field("uo.enrollment_semester", quotes(map_ids(semesters))))

    enabled = params["enabled"]
    enabled_where = if enabled, do: " AND o.enabled", else: ""

    restricted = params["restricted"]
    restricted_where = if restricted, do: " AND o.restricted", else: " AND not o.restricted"

    hidden = params["hidden"]
    hidden_where = if hidden, do: " AND NOT o.show_on_main_search", else: ""

    visible = params["visible"]
    visible_where = if visible, do: " AND o.visible", else: ""

    limit_clause = if is_nil(limit) do
      ""
    else
      " limit #{limit}"
    end

    # end_where = if is_nil(end_initial_date) or is_nil(end_final_date) do
    #   ""
    # else
    #   " AND date(o.end) >= '#{to_iso_date_format(end_initial_date)}' AND date(o.end) <= '#{to_iso_date_format(end_final_date)}'"
    # end

    start_where = if is_nil(start_date) do
      ""
    else
      " AND date(o.start) >= '#{to_iso_date_format(start_date)}'"
    end

    # start_where = if is_nil(start_initial_date) or is_nil(start_final_date) do
    #   ""
    # else
    #   " AND date(o.start) >= '#{to_iso_date_format(start_initial_date)}' AND date(o.start) <= '#{to_iso_date_format(start_final_date)}'"
    # end

    ies_ids = case params["type"] do
      "universities" -> map_ids(params["value"])
      "deal_owner_ies" -> deal_owner_ies(params["value"]["id"], capture_period_id)
      "university" -> [params["value"]["id"]]
      "group" -> group_ies(params["value"]["id"])
      "account_type" -> account_type_ies(params["value"]["id"], capture_period_id)
    end

    levels_ids = map_ids(params["levels"])
    kinds_ids = map_ids(params["kinds"])
    status = params["status"]["id"]

    levels_where = and_if_not_empty(populate_or_omit_field("l.parent_id", levels_ids))
    kinds_where = and_if_not_empty(populate_or_omit_field("k.parent_id", kinds_ids))
    status_where = and_if_not_empty(populate_or_omit_field("o.status", quote_field(status)))

    query = "
      select
        o.id as offer_id,
        c.id as course_id,
        u.name as university_name,
        cp.name as campus_name,
        c.name as course_name,
        date(o.start) as start_date,
        date(o.end) as end_date,
        o.enabled,
        o.visible,
        o.restricted,
        o.limited,
        o.discount_percentage,
        o.position,
        c.shift,
        c.kind,
        c.level,
        o.real_discount,
        uo.commercial_discount,
        o.regressive_commercial_discount,
        o.campaign,
        o.offered_price,
        uo.hide_prices,
        uo.full_price,
        uo.enrollment_semester semester,
        eg.name as group_name,
        c.campus_id,
        cp.city as campus_city,
        cp.state as campus_state,
        string_agg(distinct round(pef.value, 0)::text, ',') as pre_enrollment_fees,
        sb.total_seats,
        sb.paid_seats,
        o.status,
        o.show_on_main_search,
        uo.open_channel_type
      From
        offers o
        inner join university_offers uo on (uo.id = o.university_offer_id)
        inner join courses c on (c.id = o.course_id)
        inner join levels l on (l.name = c.level and l.parent_id is not null)
        inner join kinds k on (k.name = c.kind and k.parent_id is not null)
        inner join campuses cp on (cp.id = c.campus_id)
        inner join universities u on (u.id = cp.university_id)
        inner join seats_balances sb on (sb.id = o.seats_balance_id)
        left join education_groups eg on (eg.id = u.education_group_id)
        left join pre_enrollment_fees pef on (pef.offer_id = o.id and pef.enabled)
      where
        o.university_id in (#{Enum.join(ies_ids, ",")})
        #{enabled_where}
        #{restricted_where}
        #{visible_where}
        #{start_where}
        #{levels_where}
        #{kinds_where}
        #{status_where}
        #{hidden_where}
        #{semesters_where}
      group by o.id, c.id, cp.id, uo.id, u.id, eg.id, l.id, k.id, sb.id
      #{limit_clause}
        "

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    {
      Enum.map(resultset_map, fn entry ->
        entry
          |> Map.put("start_date", format_local(entry["start_date"]))
          |> Map.put("end_date", format_local(entry["end_date"]))
      end),
      resultset.num_rows }

  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidades", type: "universities"},
      %{ name: "IES do Farmer", type: "deal_owner_ies"},
      %{ name: "Carteira", type: "account_type"},
      %{ name: "Grupo", type: "group"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    next_capture_period = Ppa.CapturePeriod.next_capture_period(capture_period)

    semester_options = Enum.map([previous_capture_period.name, capture_period.name, next_capture_period.name], &(%{ name: &1, id: &1}))
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      regions: region_options(),
      semester_options: semester_options,
      # locationTypes: Enum.filter(location_types(), &(&1.type != "campus")),
      groupTypes: group_options(),
      accountTypes: map_simple_name(account_type_options()),
      groups: map_simple_name(groups()),
      dealOwners: map_simple_name(deal_owners(capture_period_id)),
      # qualityOwners: map_simple_name(quality_owners(capture_period_id)),
      # courses: courses,
      filters: filters
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end

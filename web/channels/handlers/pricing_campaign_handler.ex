defmodule Ppa.PricingCampaignHandler do
  use Ppa.Web, :handler
  require Logger
  # import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  # import Math
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.PricingCampaignHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_download_data(socket, params) do
    Logger.info "Ppa.PricingCampaignHandler.handle_download_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_download_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def select_current_fields() do
    query = "select * from configuracao_atual_campanha_precificacao"
    {:ok, resultset} = Ppa.RepoAnalytics.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)
    result_entry = List.first(resultset_map)

    fields = result_entry["fields"]
    fields_names = result_entry["fields_names"]
    export_fields = result_entry["export_fields"]

    fields_map = Enum.reduce(Enum.zip(fields, fields_names), %{}, fn { field, field_name }, acc ->
      Map.put(acc, field, field_name)
    end)

    { fields, fields_names, fields_map, export_fields }
  end

  def retrieve_data(params) do
    # se tiver um modelo de configuracao de campanha
    # pode buscar qual eh a tabela que precisa ler!

    # ou pode ler sempre a mesma tabela, ja que eh uma copia do analytics
    ies_ids = case params["type"] do
      # "universities" -> map_ids(params["value"])
      "university" -> [params["value"]["id"]]
      "group" -> group_ies(params["value"]["id"])
    end

    export_name = case params["type"] do
      "university" -> "ies_#{Ppa.RepoQB.get(Ppa.University, params["value"]["id"]).name}"
      "group" -> "grupo_#{Ppa.RepoQB.get(Ppa.EducationGroup, params["value"]["id"]).name}"
    end

    level = params["level"]
    Logger.info "level: #{inspect level}"
    export_name = case level do
      "1" -> "graduacao_" <> export_name
      "7" -> "pos_" <> export_name
      "12" -> "tecnico_" <> export_name
      "14" -> "outros_" <> export_name
    end

    level_where = and_if_not_empty(populate_or_omit_field("level_id", level))

    limiting_where = if is_nil(params["showData"]) do
      "and export"
    else
      ""
    end

    { fields, _fields_names, fields_map, export_fields } = select_current_fields()

    fields_selection = Enum.join(fields, ",")

    # Logger.info "fields_map# #{inspect fields_map}"

    query = "
      select
        #{fields_selection}
      from
        tabela_atual_campanha_precificacao
      where
        university_id in (#{Enum.join(ies_ids, ",")})
        #{level_where}
        #{limiting_where}"

    {:ok, resultset} = Ppa.RepoAnalytics.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    output_fields = if is_nil(params["showData"]) do
      export_fields
    else
      fields
    end

    { resultset_map, export_name, fields_map, output_fields }
  end

  def async_download_data(socket, params) do
    { data, export_name, fields_map, fields } = retrieve_data(params)

    fields_list = Enum.map(fields, &({fields_map[&1], &1}))
    Logger.info "fields_list: #{inspect fields_list}"

    data = Ppa.Util.Query.resultset_map_to_strings(data)

    if data == [] do
      Ppa.Endpoint.broadcast(socket.assigns.topic, "downloadNoData", %{})
    else

      base_filename = "cursos_#{export_name}.xlsx"
      filename = to_charlist(base_filename)

      # id_ies	nome_ies	nome_curso	nivel_curso	modalidade_curso	id_campus	nome_campus	estado	turno	status	tipo	ultimo_preco_cheio	ultimo_preco_oferecido	preco_minimo	preco_campanha

      {_filename, xlsx} = Ppa.XLSMaker.from_map_list(data, fields_list, sheetname: "cursos", filename: filename)

      encoded_xlsx = Base.encode64(xlsx)

      reponse_map = %{
        xlsx: encoded_xlsx,
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename: base_filename,
      }

      Ppa.Endpoint.broadcast(socket.assigns.topic, "downloadData", reponse_map)
    end
  end

  def async_load_data(socket, params) do
    { resultset_map, _title, fields_map, fields } = retrieve_data(Map.put(params, "showData", true))
    reponse_map = %{
      offers: resultset_map,
      fields_map: fields_map,
      fields: fields
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      # %{ name: "Universidades", type: "universities"},
    ]

    # capture_period_id = socket.assigns.capture_period
    # capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      # semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      # semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      # states: states_options(),
      # regions: region_options(),
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

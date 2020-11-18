defmodule Ppa.Util.Analisys.Ies do
#  import Ecto.Query
  import Ppa.Util.Analisys.Base
  import Ppa.Util.Timex
  require Logger

  defp campus_identification(campus_id) do
    campus = Ppa.RepoPpa.get(Ppa.Campus, campus_id)
    "Resultados no campus #{campus.name} (#{campus.city} - #{campus.state})"
  end

  def agregated_data(query, agregation) do # esta sempre agrupando por semana!
    data_query = "
    select
      date_trunc('week', date_set) date_agg,
      sum(initiated_orders) initiated_orders,
      sum(registered_orders) registered_orders,
      sum(commited_orders) commited_orders,
      sum(paid_orders) paid_orders,
      sum(refunded_orders) refunded_orders,
      sum(paid_follow_ups) paid_follow_ups,
      sum(refunded_follow_ups) refunded_follow_ups,
      sum(visits) visits,
      sum(total_revenue) total_revenue
    from
      (#{query}) d
    group by
      date_agg
    order by
      date_agg
    "

    Logger.info "data_query: #{inspect data_query}"

    Logger.info "QUERY ORDERS"

    {:ok, resultset} = Ppa.RepoPpa.query(data_query)
    # {:ok, resultset} = if Ppa.AgentDatabaseConfiguration.get_schemas do
    #   Ppa.RepoPpa.query(data_query)
    # else
    #   Ppa.RepoQB.query(data_query)
    # end
    Logger.info "ORDERS RESULTSET GOT"

    orders_dates_list = Enum.map(resultset.rows, fn row ->
      format_local(Enum.at(row, 0), "{0D}/{0M}") # DATA
    end)

    orders_initiated = Enum.map(resultset.rows, fn row ->
      Enum.at(row, 1)
    end)

    follow_ups_paid = Enum.map(resultset.rows, fn row ->
      Enum.at(row, 6)
    end)

    visits = Enum.map(resultset.rows, fn row ->
      Enum.at(row, 8)
    end)

    %{
      orders_dates: orders_dates_list,
      raw_data: %{
        paids: follow_ups_paid,
        initiateds: orders_initiated,
        visits: visits
      }
    }
  end

  def id_location_value(value) when is_map(value), do: value["id"]
  def id_location_value(value), do: value

  def type_location_value(value) when is_map(value), do: value["type"]
  def type_location_value(value), do: value

  def execute(params, topic) do
    Logger.info "Analisys.Ies.execute# params: #{inspect params}"
    admin_user_id = params["admin_id"]
    base_filter = Enum.at(params["baseFilters"], 0)
    Logger.info "base_filter: #{inspect base_filter} value: #{inspect base_filter["value"]}"
    if base_filter["type"] != "university" do
      Logger.info "NAO EH UNIVERSITY!"
    end
    university_id = base_filter["value"]["id"]
    # university_id = params["university_id"]
    capture_period_id = params["capture_period"]
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)

    admin_user = Ppa.RepoPpa.get(Ppa.AdminUser, admin_user_id)
    admin_name = if is_nil(admin_user.name) do
      Ppa.AdminUser.pretty_name(admin_user.email)
    else
      admin_user.name
    end

    levels = params["levels"]
    kinds = params["kinds"]
    location_type = params["locationType"]
    location_value = params["locationValue"]

    product_lines = cond do
      levels == [] and kinds == [] -> "todas as linhas de produto"
      levels == [] -> "#{Enum.join(Enum.map(kinds, &(&1["name"])), ",")}"
      kinds == [] -> "#{Enum.join(Enum.map(levels, &(&1["name"])), ",")}"
      true -> "#{Enum.join(Enum.map(levels, &(&1["name"])), ",")} #{Enum.join(Enum.map(kinds, &(&1["name"])), ",")}"
    end

    location = case location_type do
      "city" -> "na cidade #{location_value["id"]} - #{location_value["state"]}"
      "region" -> "na região #{type_location_value(location_value)}"
      "state" -> "no estado #{type_location_value(location_value)}"
      "campus" -> campus_identification(id_location_value(location_value))
      nil -> "em todas as localizações"
    end

    params = Map.put(params, "baseFilters", [%{ "type" => "university", "value" => %{ "id" => university_id } }])

    ies_info = Ppa.RepoPpa.get(Ppa.University, university_id)

    { :ok, final_date } = Elixir.Timex.Parse.DateTime.Parser.parse(params["finalDate"], "{ISO:Extended:Z}")
    { :ok, initial_date } = Elixir.Timex.Parse.DateTime.Parser.parse(params["initialDate"], "{ISO:Extended:Z}")


    days_diff = Timex.diff final_date, initial_date, :days

    aggregation = case days_diff do
      x when x in 0..28 -> nil
      x when x in 29..190 -> "week"
      _ -> "month"
    end

    full_filter_data = Ppa.PanelHandler.execute_filter(capture_period_id, params, "{0D}/{0M}")

    data_query = Ppa.PanelHandler.orders_filter_query(capture_period_id, params)

    filter_data = case aggregation do
      nil -> full_filter_data
      x -> agregated_data(data_query, x)
    end

    admin_email = String.to_charlist(admin_user.email)
    email_user = :string.substr(admin_email, 1, :string.str(admin_email, '@'))
    email = List.to_string(email_user) <> "queroeducacao.com"

    analysis_map = %{
      "INITIAL_TITLE" => "Resultados #{capture_period.name}",
      "IES_NAME" => ies_info.name,
      "IES_NAME_AND_DATE" => "#{ies_info.name} - #{Enum.at(Ppa.Util.Timex.months_names, Timex.today.month - 1)} - #{Timex.today.year}",
      "MONTH_YEAR" => "#{Enum.at(Ppa.Util.Timex.months_names, Timex.today.month - 1)} - #{Timex.today.year}",
      "USER_NAME" => admin_name,
      "USER_EMAIL" => email,
      "INDICATORS_TITLE" => "Indicadores do Funil no QB",
      "INDEXES_TITLE" => "Índices",
      "SOURCE_LINE_1" => "*Dados coletados no período de #{format_local(initial_date)} à #{format_local(final_date)},",
      "SOURCE_LINE_2" => "considerando #{product_lines} e #{location}",
      "CHART_CONVERSION" => %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#09b67c"],
          series: [ full_filter_data.conversion_rate ],
          labels: full_filter_data.orders_dates,
          legend_labels: ["Conversão"],
          x_axis_font_size: 20,
          y_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          y_axis_title: "Conversão (%)",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          legend_point_style: true,
          y_axis_begin_at_zero: false
        }, width: 830, height: 380
      },
      "CHART_INDEXES" => %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#ffc400", "#1cb0c7"],
          series: [ full_filter_data.atraction_rate, full_filter_data.success_rate ],
          labels: full_filter_data.orders_dates,
          legend_labels: ["Atratividade", "Sucesso"],
          x_axis_font_size: 20,
          y_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          y_axis_title: "Taxas (%)",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          legend_point_style: true,
          y_axis_begin_at_zero: false
        }, width: 830, height: 380
      },
      "CHART_PAIDS" => %{
        type: :chart,
        properties: %{
          type: :bar,
          colors: ["#09b67c"],
          series: [ filter_data.raw_data.paids ],
          labels: filter_data.orders_dates,
          legend_labels: ["Pagos"],
          draw_values: true,
          y_axis_title: "Pagos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          x_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          hide_y_axis: true,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
        }, width: 730, height: 380
      },
      "CHART_ORDERS" => %{
        type: :chart,
        properties: %{
          type: :bar,
          colors: ["#1cb0c7"],
          series: [ filter_data.raw_data.initiateds ],
          labels: filter_data.orders_dates,
          legend_labels: ["Ordens"],
          draw_values: true,
          y_axis_title: "Ordens",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          x_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          hide_y_axis: true,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
        }, width: 730, height: 380
      },
      "CHART_VISITS" => %{
        type: :chart,
        properties: %{
          type: :bar,
          colors: ["#ffc400"],
          series: [ filter_data.raw_data.visits ],
          labels: filter_data.orders_dates,
          legend_labels: ["Visitas"],
          draw_values: true,
          x_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          y_axis_title: "Visitas",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_y_axis: true,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
        }, width: 730, height: 380
      },
    }

    output = generate_presentation(analysis_map, "template_ies.pptx")

    Logger.info "output: #{output}"

    output_map = Poison.decode!(output)
    Logger.info "output_map: #{inspect output_map}"

    if output_map["sucess"] do
      Ppa.Endpoint.broadcast(topic, "analysisData", %{ filename: output_map["filename"], download_name: ies_info.name })
    else
      Ppa.Endpoint.broadcast(topic, "analysisError", %{})
    end
  end
end

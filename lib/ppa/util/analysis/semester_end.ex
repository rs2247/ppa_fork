defmodule Ppa.Util.Analisys.SemesterEnd do
  import Ecto.Query
  import Ppa.Util.Analisys.Base
  import Ppa.Util.Timex
  import Ppa.Util.Sql
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Ppa.Util.FiltersParser
  import Ppa.Util.Filters
  # import Ppa.Metrics
  import Math
  require Logger
  require Tasks

  @level_id_graduacao 1
  @level_id_pos_graduacao 7

  @kind_id_presencial 1
  @kind_id_ead 3
  @kind_id_semi_presencial 8

  @fator_pagamentos_graduacao 30
  @fator_pagamentos_pos_graduacao 14

  @referencia_taxa_atratividade 16.0
  @referencia_taxa_atratividade_pos 12.0
  @referencia_taxa_sucesso 10.0
  @referencia_taxa_sucesso_pos 18.0
  @referencia_taxa_conversao 1.6
  @referencia_taxa_conversao_pos 2.16

  def referencia_atratividade(level_id) do
    if String.to_integer(level_id) == @level_id_graduacao do
      @referencia_taxa_atratividade
    else
      @referencia_taxa_atratividade_pos
    end
  end

  def referencia_sucesso(level_id) do
    if String.to_integer(level_id) == @level_id_graduacao do
      @referencia_taxa_sucesso
    else
      @referencia_taxa_sucesso_pos
    end
  end

  def referencia_conversao(level_id) do
    if String.to_integer(level_id) == @level_id_graduacao do
      @referencia_taxa_conversao
    else
      @referencia_taxa_conversao_pos
    end
  end

  # def referencia_atratividade, do: @referencia_taxa_atratividade
  # def referencia_sucesso, do: @referencia_taxa_sucesso
  def referencia_conversao, do: @referencia_taxa_conversao

  @benchmark_crescimento_visitas 19.68
  @benchmark_crescimento_visitas_qap 87.0
  @benchmark_atratividade 23.0
  @benchmark_sucesso 15.0
  @benchmark_conversao 3.45

  @base_colors ["#35b6cc", "#fdc029", "#09b67c", "#bf265f", "#05869B", "#FC8400", "#006386"]

  def execute(params, topic) do
    Logger.info "Analisys.SemesterEnd.execute# params: #{inspect params}"

    if is_nil(params["version"]) do
      Logger.info "Analisys.SemesterEnd.execute# REQUEST SEM VERSAO"
    end

    case params["version"] do
      "2019.1" -> execute_2019_1(params, topic)
      "2019.2" -> execute_2019_2(params, topic)
      "2020.1" -> execute_2020_1(params, topic)

      nil -> execute_2019_2(params, topic)
    end
  end

  def get_base_info(params) do
    base_filter = Enum.at(params["baseFilters"], 0)
    if base_filter["type"] == "university" do
      university_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.University, university_id)
    else
      group_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.EducationGroup, group_id)
    end
  end

  def parse_ies_filter(params) do
    base_filter = Enum.at(params["baseFilters"], 0)
    case base_filter["type"] do
      "university" -> [ base_filter["value"]["id"] ]
      "group" -> group_ies(base_filter["value"]["id"])
    end
  end

  def product_line_data(params, capture_period, levels, kinds) do
    product_line_data_by_period(params, capture_period, capture_period.start, capture_period.end, levels, kinds)
  end

  def product_line_data_by_period(params, capture_period, period_start, period_end, levels, kinds) do
    Logger.info "product_line_data_by_period# period_start: #{inspect period_start} period_end: #{inspect period_end}"
    university_ids = parse_ies_filter(params)

    params = params
      |> Map.put("finalDate", period_end)
      |> Map.put("initialDate", period_start)
      |> Map.put("levels", levels)
      |> Map.put("kinds", kinds)

    filter_data_new = Ppa.Util.FiltersParser.parse_filters(params, capture_period.id)
    # Logger.info "filter_data: #{inspect filter_data} filter_data_new: #{inspect filter_data_new}"

    table_data = Ppa.DashboardHandler.table_filter(filter_data_new)

    Logger.info "table_data: #{inspect table_data}"

    final_limit = if Timex.compare(period_end, Timex.today) > 0 do
      "(now() - interval '1 day')::date"
    else
      "'#{to_iso_date_format(period_end)}'"
    end

    means_table_query = "
    select
        count(*) as all_follow_ups,
        sum(case when level_id = 1 then #{@fator_pagamentos_graduacao} else #{@fator_pagamentos_pos_graduacao} end * offered_price) as receita,
        round(avg(offered_price), 2) offered_medio,
        round(((sum(full_price) - sum(offered_price)) /  sum(full_price)) * 100) as desconto_medio,
        count(distinct course_id) as n_skus
    from (
      SELECT fu.id,
                             o.offered_price,
                             o.discount_percentage,
                             uo.max_payments,
                             uo.full_price,
                             l.parent_id as level_id,
                             k.parent_id as kind_id,
                             o.course_id
       FROM   follow_ups fu
             INNER JOIN offers o ON (o.id = fu.offer_id)
             INNER JOIN courses c ON (c.id = fu.course_id)
             INNER JOIN levels l ON (l.name = c.level and l.parent_id is not null)
             INNER JOIN kinds k ON (k.name = c.kind and k.parent_id is not null)
             INNER JOIN university_offers uo ON (uo.id = o.university_offer_id)
             INNER JOIN orders ord ON (ord.id = fu.order_id)
       WHERE
             fu.university_id in (#{Enum.join(university_ids, ",")}) and
             date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, fu.created_at))) >= '#{to_iso_date_format(period_start)}' and
             date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, fu.created_at))) <= #{final_limit}
             #{and_if_not_empty(populate_or_omit_field('l.parent_id', map_ids(levels)))}
             #{and_if_not_empty(populate_or_omit_field('k.parent_id', map_ids(kinds)))}
    ) as d"

    { :ok, means_table_resultset } = Ppa.RepoPpa.query(means_table_query)
    means_table_resultset_map = Ppa.Util.Query.resultset_to_map(means_table_resultset)

    [ means_table_data ] = means_table_resultset_map

    # orders_data
    #   |> Map.merge(velocimeter_data)
    #   |> Map.merge(means_table_data)

    table_data
      |> Map.merge(means_table_data)
  end

  def format_percent_spaced(nil), do: nil
  def format_percent_spaced(value), do: "#{value} %"

  def query_sazonalidade(capture_period_id) do
    "SELECT   date,
         avg(daily_contribution) OVER (ORDER BY date rows BETWEEN 6 PRECEDING AND      CURRENT row) AS daily_contribution
    FROM     daily_contributions
    WHERE    capture_period_id = #{capture_period_id} and product_line_id in (1, 10)"
  end

  def grad_chart(grad_ead_paid, grad_pres_paid, ead_label, pres_label, base_size) do
    if is_nil(ead_label) do
      pie_chart("Total Graduação: #{format_precision(grad_pres_paid)}", [Decimal.to_integer(grad_pres_paid)], ["Presencial"], base_size)
    else
      if is_nil(pres_label) do
        pie_chart("Total Graduação: #{format_precision(grad_ead_paid)}", [Decimal.to_integer(grad_ead_paid)], [ead_label], base_size)
      else
        pie_chart("Total Graduação: #{format_precision(Decimal.add(grad_ead_paid, grad_pres_paid))}", [Decimal.to_integer(grad_ead_paid), Decimal.to_integer(grad_pres_paid)], [ead_label, "Presencial"], base_size)
      end
    end
  end

  def pos_chart(pos_ead_paid, pos_pres_paid, ead_label, pres_label, base_size) do
    if is_nil(ead_label) do
      pie_chart("Total Pós: #{format_precision(pos_pres_paid)}",  [Decimal.to_integer(pos_pres_paid)], ["Presencial"], base_size)
    else
      if is_nil(pres_label) do
        pie_chart("Total Pós: #{format_precision(pos_ead_paid)}",  [Decimal.to_integer(pos_ead_paid)], [ead_label], base_size)
      else
        pie_chart("Total Pós: #{format_precision(Decimal.add(pos_ead_paid, pos_pres_paid))}",  [Decimal.to_integer(pos_ead_paid), Decimal.to_integer(pos_pres_paid)], [ead_label, "Presencial"], base_size)
      end
    end
  end

  def other_chart(others_ead_paid,others_pres_paid, ead_label, pres_label, base_size) do
    if is_nil(ead_label) do
      pie_chart("Total Outros: #{format_precision(others_pres_paid)}", [Decimal.to_integer(others_pres_paid)], ["Presencial"], base_size)
    else
      if is_nil(pres_label) do
        pie_chart("Total Outros: #{format_precision(others_ead_paid)}", [Decimal.to_integer(others_ead_paid)], [ead_label], base_size)
      else
        pie_chart("Total Outros: #{format_precision(Decimal.add(others_ead_paid, others_pres_paid))}", [Decimal.to_integer(others_ead_paid), Decimal.to_integer(others_pres_paid)], [ead_label, "Presencial"], base_size)
      end
    end
  end

  def pie_chart(title, chart_data, labels, base_size, colors \\ nil, cutout_percentage \\ 0, draw_values \\ true, draw_percentages \\ true, legend_point_style \\ false, legend_padding \\ 20, draw_values_font_size \\ 18, draw_values_sufix \\ nil, draw_values_horizontal_deslocation \\ nil, draw_values_hide_zeros \\ false, title_padding \\ 20) do
    colors = if is_nil(colors) do
      Enum.take(@base_colors, Enum.count(chart_data))
    else
      colors
    end
    { deslocation_flag, deslocation_offset } = if is_nil(draw_values_horizontal_deslocation) do
      { false, 0 }
    else
      { true, draw_values_horizontal_deslocation }
    end
    %{
      type: :chart,
      properties: %{
        type: :pie,
        colors: colors,
        data: chart_data,
        labels: labels,
        title: title,
        title_padding: title_padding,
        draw_values: draw_values,
        draw_percentages: draw_percentages,
        draw_values_font_size: draw_values_font_size,
        draw_values_locale: "pt-BR",
        legend_point_style: legend_point_style,
        # canvas_width: base_size * 2,
        canvas_width: base_size * 2,
        canvas_height: base_size * 2,
        cutout_percentage: cutout_percentage,
        legend_padding: legend_padding,
        draw_values_horizontal_deslocation: deslocation_flag,
        draw_values_horizontal_deslocation_offset: deslocation_offset,
        draw_values_hide_zeros: draw_values_hide_zeros,
        draw_values_sufix: draw_values_sufix
      }, width: base_size*1.5, height: base_size
    }
  end

  def lookup_leads(university_ids, _capture_period, kinds_ids, levels_ids, initial_date, final_date) do
    kinds_where = and_if_not_empty(populate_or_omit_field("k.parent_id", kinds_ids))
    levels_where = and_if_not_empty(populate_or_omit_field("l.parent_id", levels_ids))

    # qb_schema = "querobolsa_production."
    qb_schema = ""

    # auxiliar_schema = ""
    auxiliar_schema = "denormalized_views."

    query = "
    SELECT
      case when total_com_interesse = 0 then 0 else round(((fiel)::decimal / total_com_interesse) * 100, 2) end as p_fieis,
      case when total_com_interesse = 0 then 0 else round(((total_com_interesse - fiel)::decimal / total_com_interesse) * 100, 2) end as p_indecisos
    FROM (
      SELECT Count(*)   AS total_follow_ups,
             Count(CASE
                     WHEN ies_interesse <> '{NULL}' THEN 1
                   END) AS total_com_interesse,
             Count(CASE
                     WHEN ies_interesse <@ '{#{Enum.join(university_ids, ",")}}' THEN 1
                   END) AS fiel
      FROM   (SELECT fu.id,
                     Array_agg(DISTINCT id_ies) ies_interesse
              FROM   #{qb_schema}follow_ups fu
              INNER JOIN #{qb_schema}courses c ON (c.id = fu.course_id)
              INNER JOIN #{qb_schema}kinds k on (k.name = c.kind and k.parent_id is not null)
              INNER JOIN #{qb_schema}levels l on (l.name = c.level and l.parent_id is not null)
                     LEFT JOIN #{auxiliar_schema}competitors_flow_cache cfc
                            ON ( cfc.base_user_id = fu.user_id )
              WHERE  fu.university_id in (#{Enum.join(university_ids, ",")})
                     AND fu.created_at >= '#{to_iso_date_format(initial_date)}'
                     AND fu.created_at <= '#{to_iso_date_format(final_date)}'
                     AND id_ies is not null
                     #{kinds_where}
                     #{levels_where}
              GROUP  BY fu.id
              ORDER  BY 2 DESC) d) as dd; "

    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ lead_data ] = resultset_map
    { lead_data["p_fieis"], lead_data["p_indecisos"] }
  end

  def atratividade_data_ex(atratividade_atual, input_data, referencia_atratividade \\ @referencia_taxa_atratividade) do
    # Logger.info "atratividade_data_ex# atratividade_atual: #{atratividade_atual} @referencia_taxa_atratividade: #{@referencia_taxa_atratividade} CMP: #{Decimal.cmp(atratividade_atual, @referencia_taxa_atratividade)}"
    if Decimal.cmp(atratividade_atual, Decimal.from_float(referencia_atratividade)) == :gt do
      {
        atratividade_atual,
        input_data["initiated_orders"],
        :black
      }
    else
      potencial_value = Decimal.round(Decimal.mult(input_data["visits"], Decimal.from_float(referencia_atratividade / 100)), 0)
      {
        Decimal.from_float(referencia_atratividade),
        potencial_value,
        :red
      }
    end
  end

  def sucesso_data_ex(sucesso_atual, _conversao_atual, ordens_potencial, input_data, referencia_sucesso \\ @referencia_taxa_sucesso) do
    # Logger.info "sucesso_data_ex# sucesso_atual: #{sucesso_atual} @referencia_taxa_sucesso: #{@referencia_taxa_sucesso} CMP: #{Decimal.cmp(sucesso_atual, @referencia_taxa_sucesso)}"
    if Decimal.cmp(sucesso_atual, Decimal.from_float(referencia_sucesso)) == :gt do
      # Logger.info "sucesso_data_ex# SUCESSO OK ordens_potencial: #{ordens_potencial} ALL_FUPS: #{input_data["initiated_orders"]} CMP: #{Decimal.cmp(ordens_potencial, input_data["all_follow_ups"])}"
      { pagos_potencial, pagos_potencial_color, sucesso_color } = if Decimal.cmp(ordens_potencial, input_data["initiated_orders"]) == :eq do
        { input_data["all_follow_ups"], :black, :black }
      else
        pagos_projetado = Decimal.mult(ordens_potencial, Decimal.div(sucesso_atual , 100))
        pagos_projetado = Decimal.round(pagos_projetado, 0)
        { pagos_projetado, :red, :black }
      end
      { sucesso_atual, pagos_potencial, pagos_potencial_color, sucesso_color }
    else
      pagos_projetado = Decimal.mult(ordens_potencial, Decimal.from_float(referencia_sucesso / 100))
      pagos_projetado = Decimal.round(pagos_projetado, 0)
      { Decimal.from_float(referencia_sucesso), pagos_projetado, :red, :red }
    end
  end

  def check_qap(filter_data) do
    university_filters = populate_filters(filter_data.filters.custom_filters, %{ "university_id" => ""})
    query = "
    select
      count(*) as n_entries
    from
      university_billing_configurations
    where
      #{Enum.join(university_filters, " AND ")}
    "

    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    [ data ] = resultset_map

    data["n_entries"] > 0
  end

  def potencial_map(year_ago_semester, previous_semester, title, input_data, input_data_year_ago, sufix \\ "") do

    atratividade_anterior = divide_rate(input_data_year_ago["initiated_orders"], input_data_year_ago["visits"])
    atratividade_atual = divide_rate(input_data["initiated_orders"], input_data["visits"])

    {
      atratividade_potencial,
      ordens_potencial,
      ordens_potencial_color
    } = atratividade_data_ex(atratividade_atual, input_data)

    sucesso_anterior = divide_rate(input_data_year_ago["all_follow_ups"], input_data_year_ago["initiated_orders"])
    sucesso_atual = divide_rate(input_data["all_follow_ups"], input_data["initiated_orders"])

    conversao_anterior = divide_rate(input_data_year_ago["all_follow_ups"], input_data_year_ago["visits"])
    conversao_atual = divide_rate(input_data["all_follow_ups"], input_data["visits"])

    {
      sucesso_potencial,
      pagos_potencial,
      pagos_potencial_color,
      sucesso_potencial_color
    } = sucesso_data_ex(sucesso_atual, conversao_atual, ordens_potencial, input_data)

    {
      conversao_potencial,
      label_nao_realizado,
      nao_realizado
    } = if Decimal.cmp(pagos_potencial, input_data["all_follow_ups"]) == :gt do
      conversao_projetada = Decimal.mult(Decimal.div(pagos_potencial, input_data["visits"]), 100)

      pagos_diff = Decimal.add(pagos_potencial, Decimal.mult(input_data["all_follow_ups"], -1))
      current_mean_income = Decimal.div(input_data["receita"], input_data["all_follow_ups"])
      Logger.info "pagos_diff: #{pagos_diff} current_mean_income: #{current_mean_income}"

      delta_income = Decimal.mult(pagos_diff, current_mean_income)
      {
        conversao_projetada,
        %{ type: :text, color: :red, value: "Potencial Não Realizado (R$)" },
        %{ type: :text, color: :red, value: Number.Delimit.number_to_delimited(delta_income) }
      }
    else
      { conversao_atual, "", "" }
    end

    %{
      "TITULO_POTENCIAL_ALUNOS#{sufix}" => "Potencial de Alunos #{previous_semester} - #{title}",

      "POTENCIAL#{sufix}_SEM_1" => year_ago_semester,
      "POTENCIAL#{sufix}_SEM_2" => previous_semester,
      "POTENCIAL#{sufix}_SEM_3" => "#{previous_semester} Potencial*",

      "POTENCIAL#{sufix}_VISITAS_1" => "#{Number.Delimit.number_to_delimited(input_data_year_ago["visits"], [precision: 0])}",
      "POTENCIAL#{sufix}_VISITAS_2" => "#{Number.Delimit.number_to_delimited(input_data["visits"], [precision: 0])}",
      "POTENCIAL#{sufix}_VISITAS_3" => "#{Number.Delimit.number_to_delimited(input_data["visits"], [precision: 0])}",

      "POTENCIAL#{sufix}_ORDENS_1" => "#{Number.Delimit.number_to_delimited(input_data_year_ago["initiated_orders"], [precision: 0])}",
      "POTENCIAL#{sufix}_ORDENS_2" => "#{Number.Delimit.number_to_delimited(input_data["initiated_orders"], [precision: 0])}",
      "POTENCIAL#{sufix}_ORDENS_3" => %{ type: :text, color: ordens_potencial_color, value: Number.Delimit.number_to_delimited(ordens_potencial, [precision: 0]) },

      "POTENCIAL#{sufix}_PAGOS_1" => "#{Number.Delimit.number_to_delimited(input_data_year_ago["all_follow_ups"], [precision: 0])}",
      "POTENCIAL#{sufix}_PAGOS_2" => "#{Number.Delimit.number_to_delimited(input_data["all_follow_ups"], [precision: 0])}",
      "POTENCIAL#{sufix}_PAGOS_3" => %{ type: :text, color: pagos_potencial_color, value: Number.Delimit.number_to_delimited(pagos_potencial, [precision: 0]) },


      "POTENCIAL#{sufix}_ATRATIVIDADE_1" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(atratividade_anterior))}",
      "POTENCIAL#{sufix}_ATRATIVIDADE_2" => %{ type: :text, color: ordens_potencial_color, value: format_percent_spaced(Number.Delimit.number_to_delimited(atratividade_atual)) },
      "POTENCIAL#{sufix}_ATRATIVIDADE_3" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(atratividade_potencial))}",

      "POTENCIAL#{sufix}_SUCESSO_1" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(sucesso_anterior))}",
      "POTENCIAL#{sufix}_SUCESSO_2" => %{ type: :text, color: sucesso_potencial_color, value: format_percent_spaced(Number.Delimit.number_to_delimited(sucesso_atual)) },
      "POTENCIAL#{sufix}_SUCESSO_3" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(sucesso_potencial))}",

      "POTENCIAL#{sufix}_CONVERSAO_1" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(conversao_anterior))}",
      "POTENCIAL#{sufix}_CONVERSAO_2" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(conversao_atual))}",
      "POTENCIAL#{sufix}_CONVERSAO_3" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(conversao_potencial))}",

      "POTENCIAL#{sufix}_REALIZADO" => "#{Number.Delimit.number_to_delimited(input_data["receita"])}",
      "POTENCIAL#{sufix}_NAO_REALIZADO" => nao_realizado,

      "T_POTENCIAL#{sufix}_NAO_REALIZADO" => label_nao_realizado,
    }
  end

  def empty_product_line_data() do
    %{
      "all_follow_ups" => 0,
      "exchanged_follow_ups" => 0,
      "paid_follow_ups" => 0,
      "desconto_medio" => nil,
      "offered_medio" => nil,
      "n_skus" => nil
    }
  end

  def product_line_projection(params, capture_period, levels, kinds) do
    university_ids = parse_ies_filter(params)

    projection_levels_where = and_if_not_empty(populate_or_omit_field("level_id", map_ids(levels)))
    projection_kinds_where = and_if_not_empty(populate_or_omit_field("kind_id", map_ids(kinds)))

    projection_query = "
    select
      sum(base_projection)
    from
      parcerias.students_projections
    where
      capture_period_id = #{capture_period.id} and active
      and university_id in (#{Enum.join(university_ids, ",")})
      #{projection_levels_where}
      #{projection_kinds_where}
    "

    { :ok, projection_resultset } = Ppa.RepoPpa.query(projection_query)
    projection_resultset_map = Ppa.Util.Query.resultset_to_map(projection_resultset)

    [ projection_data ] = projection_resultset_map

    projection_data["sum"]
  end

  # especifico 2019.1
  def data_for_level(current_level_id, params, capture_period, previous_year_capture_period, next_capture_period, previous_capture_period) do

    levels = params["levels"]
    kinds = params["kinds"]

    levels_ids = map_ids(levels)
    kinds_ids = map_ids(kinds)

    pres_kinds = [%{ "id" => @kind_id_presencial }]
    ead_kinds = [%{ "id" => @kind_id_ead }, %{ "id" => @kind_id_semi_presencial }]
    pres_kinds_ids = MapSet.new(map_ids(pres_kinds))
    ead_kinds_ids = MapSet.new(map_ids(ead_kinds))

    Logger.info "data_for_level# levels_ids: #{inspect levels_ids} current_level_id: #{inspect current_level_id} kinds_ids: #{inspect kinds_ids}"

    if levels_ids == [] or Enum.member?(levels_ids, "#{current_level_id}") do
      Logger.info "data_for_level# SEM FILTRO DE LEVEL, OU ESTA CONTIDO NO FILTRO levels_ids: #{inspect levels_ids} current_level_id: #{inspect current_level_id}"
      { pres_kinds, ead_kinds } = if kinds_ids == [] do
        { pres_kinds, ead_kinds }
      else
        kinds_ids_set = MapSet.new(Enum.map(kinds_ids, &(String.to_integer(&1))))
        pres_intersection = MapSet.intersection(kinds_ids_set, pres_kinds_ids)
        ead_intersection = MapSet.intersection(kinds_ids_set, ead_kinds_ids)

        { Enum.map(pres_intersection, &(%{ "id" => &1})), Enum.map(ead_intersection, &(%{ "id" => &1})) }
      end

      pres_kinds = if pres_kinds == [], do: [%{"id"=>"-1"}], else: pres_kinds
      ead_kinds = if ead_kinds == [], do: [%{"id"=>"-1"}], else: ead_kinds
      {
        product_line_data(params, capture_period, [%{ "id" => current_level_id }], pres_kinds),
        product_line_data(params, capture_period, [%{ "id" => current_level_id }], ead_kinds),
        product_line_data(params, capture_period, [%{ "id" => current_level_id }], kinds),
        product_line_data(params, previous_year_capture_period, [%{ "id" => current_level_id }], kinds),
        product_line_data(params, previous_capture_period, [%{ "id" => current_level_id }], kinds),
        product_line_projection(params, next_capture_period, [%{ "id" => current_level_id }], kinds)
      }
    else
      Logger.info "data_for_level# NAO ESTA CONTIDO NO FILTRO levels_ids: #{inspect levels_ids} current_level_id: #{inspect current_level_id}"
      {
        empty_product_line_data(),
        empty_product_line_data(),
        empty_product_line_data(),
        empty_product_line_data(),
        empty_product_line_data(),
        nil
      }
    end
  end

  # especifico 2019.1
  def data_for_levels(current_level_ids, params, capture_period, previous_year_capture_period, next_capture_period, previous_capture_period) do

    levels = params["levels"]
    kinds = params["kinds"]

    levels_ids = map_ids(levels)
    kinds_ids = map_ids(kinds)

    pres_kinds = [%{ "id" => @kind_id_presencial }]
    ead_kinds = [%{ "id" => @kind_id_ead }, %{ "id" => @kind_id_semi_presencial }]
    pres_kinds_ids = MapSet.new(map_ids(pres_kinds))
    ead_kinds_ids = MapSet.new(map_ids(ead_kinds))

    current_level_ids_map = MapSet.new(current_level_ids)

    Logger.info "data_for_levels# levels_ids: #{inspect levels_ids} current_level_ids: #{inspect current_level_ids} kinds_ids: #{inspect kinds_ids}"


    if levels_ids == [] or Enum.any?(current_level_ids, &(Enum.member?(levels_ids, "#{&1}"))) do
      Logger.info "data_for_levels# SEM FILTRO DE LEVEL, OU ESTA CONTIDO NO FILTRO levels_ids: #{inspect levels_ids} current_level_ids: #{inspect current_level_ids}"
      { pres_kinds, ead_kinds, mapped_levels } = if kinds_ids == [] do
        Logger.info "data_for_levels# SEM FILTRO DE KINDS"
        { pres_kinds, ead_kinds, Enum.map(current_level_ids, &(%{ "id" => &1})) }
      else
        # preciso dos levels da interseccao
        # mas levels_ids = [] ou existe algo!
        # se levels_ids = []m nunca vai ter inteseccao!
        levels_ids_intersection = if levels_ids == [] do
          current_level_ids
        else
          levels_ids_set = MapSet.new(Enum.map(levels_ids, &(String.to_integer(&1))))
          MapSet.intersection(levels_ids_set, current_level_ids_map)
        end

        Logger.info "levels_ids_intersection: #{inspect levels_ids_intersection}"

        kinds_ids_set = MapSet.new(Enum.map(kinds_ids, &(String.to_integer(&1))))
        pres_intersection = MapSet.intersection(kinds_ids_set, pres_kinds_ids)
        ead_intersection = MapSet.intersection(kinds_ids_set, ead_kinds_ids)

        {
          Enum.map(pres_intersection, &(%{ "id" => &1})),
          Enum.map(ead_intersection, &(%{ "id" => &1})),
          Enum.map(levels_ids_intersection, &(%{ "id" => &1}))
        }
      end

      pres_kinds = if pres_kinds == [], do: [%{"id"=>"-1"}], else: pres_kinds
      ead_kinds = if ead_kinds == [], do: [%{"id"=>"-1"}], else: ead_kinds

      Logger.info "data_for_levels# FILTERS: pres_kinds: #{inspect pres_kinds} ead_kinds: #{inspect ead_kinds} mapped_levels: #{inspect mapped_levels} kinds: #{inspect kinds}"
      {
        product_line_data(params, capture_period, mapped_levels, pres_kinds),
        product_line_data(params, capture_period, mapped_levels, ead_kinds),
        product_line_data(params, capture_period, mapped_levels, kinds),
        product_line_data(params, previous_year_capture_period, mapped_levels, kinds),
        product_line_data(params, previous_capture_period, mapped_levels, kinds),
        product_line_projection(params, next_capture_period, mapped_levels, kinds)
      }
    else
      Logger.info "data_for_levels# NAO ESTA CONTIDO NO FILTRO levels_ids: #{inspect levels_ids} current_level_id: #{inspect current_level_ids}"
      {
        empty_product_line_data(),
        empty_product_line_data(),
        empty_product_line_data(),
        empty_product_line_data(),
        empty_product_line_data(),
        nil
      }
    end
  end

  def get_admin_info(admin_user_id) do
    admin_user = Ppa.RepoPpa.get(Ppa.AdminUser, admin_user_id)
    admin_name = if is_nil(admin_user.name) do
      Ppa.AdminUser.pretty_name(admin_user.email)
    else
      admin_user.name
    end
    admin_email = String.to_charlist(admin_user.email)
    email_user = :string.substr(admin_email, 1, :string.str(admin_email, '@'))
    adjusted_email = List.to_string(email_user) <> "queroeducacao.com"
    { admin_name, adjusted_email }
  end

  # especifico 2019.1
  def projection_map(current_data, previous_data, projection_value, index, sufix, previous_semester, current_semester, next_semester) do
    if is_nil(projection_value) do
      %{
        "#DELETE_SLIDE_#{index}" => %{ type: :delete_slide, slide_index: index - 1 }, # zero based
      }
    else
      colors = ["#fdc029", "#fdc029", "#35b6cc"]
      labels = [previous_semester, current_semester ]
      data = [previous_data["all_follow_ups"] , current_data["all_follow_ups"] ]

      Logger.info "projection_map# PREV: #{previous_data["all_follow_ups"]} PROJ: #{projection_value}"
      crescimento_organico = Decimal.round(Decimal.mult(previous_data["all_follow_ups"], Decimal.from_float(1.03)), 0)
      Logger.info "crescimento_organico: #{inspect crescimento_organico} PREV: #{previous_data["all_follow_ups"]}"

      { colors, data, labels, crescimento_map, final_projection_value } = if Decimal.cmp(projection_value, crescimento_organico) == :gt do
        Logger.info "projection_map# MOSTRA PROJECAO COM CAMPANHAS"
        # precisa de mais uma barra!

        crescimento_map = if Decimal.cmp(previous_data["all_follow_ups"], 0) == :eq do
          "-"
        else
          crescimento = Decimal.add(Decimal.mult(Decimal.div(projection_value, previous_data["all_follow_ups"]), 100), -100)

          cor_crescimento = if Decimal.cmp(crescimento, Decimal.new(0)) == :gt do
            :green
          else
            :red
          end
          %{ type: :text, color: cor_crescimento, value: format_percent_spaced(Number.Delimit.number_to_delimited(crescimento, [precision: 0])) }
        end

        {
          colors ++ ["#35b6cc"],
          data ++ [ Decimal.to_integer(crescimento_organico), projection_value],
          labels ++ ["#{next_semester} Orgânico",
          "#{next_semester} Potencial"],
          crescimento_map,
          projection_value
        }
      else
        Logger.info "projection_map# ORGANICO EH MAIOR QUE A PROJECAO"
        # mostra so o organico
        # aqui nunca tem crescimento!
        {
          colors,
          data ++ [ Decimal.to_integer(crescimento_organico) ],
          labels ++ [ next_semester ],
          %{ type: :text, color: :green, value: "3%" },
          Decimal.to_integer(crescimento_organico)
        }
      end

      %{
        "CAPTADOS_P#{sufix}" => "#{format_precision(current_data["all_follow_ups"])}",
        "PROJECAO_N#{sufix}" => "#{format_precision(final_projection_value)}",
        "CRESCIMENTO_YOY#{sufix}" => crescimento_map,
        "GRAFICO_PROJECAO_CAPTACAO#{sufix}" => %{
          type: :chart,
          properties: %{
            type: :bar,
            colors: colors,
            data: data,
            labels: labels,
            draw_values: true,
            draw_values_font_size: 28,
            draw_values_locale: "pt-BR",
            x_axis_font_size: 35,
            x_axis_font_color: "#000000",
            hide_y_axis: true,
            hide_legend: true,
            hide_x_axis_grid: true,
            hide_y_axis_grid: true,
            hide_y_axis_border: true,
            x_axis_title_padding: 20,
            bar_percentage: 0.5,
          }, width: 830, height: 350
        },
      }
    end
  end

  def reduce_stock_vendas(input) do
    Enum.reduce(input, %{}, fn (entry, acc) ->
      Map.put(acc, entry["status"], entry["percent"])
    end)
  end


  def reduce_stock_reasons(input) do
    Enum.reduce(input, %{ vendido: 0, nao_vendido: 0, mais_caro: 0, outros_motivos: 0, nao_vendido_na_praca: 0}, fn (entry, acc) ->
      { total, _ } = Integer.parse(entry["total"])
      com_vendas = case entry["vendas"] do
        "vendida" -> Map.put(acc, :vendido, acc.vendido + total)
        "nao_vendida" -> Map.put(acc, :nao_vendido, acc.nao_vendido + total)
      end
      case entry["status"] do
        "mais_caro" -> Map.put(com_vendas, :mais_caro, com_vendas.mais_caro + total)
        "outros_motivos" -> Map.put(com_vendas, :outros_motivos, com_vendas.outros_motivos + total)
        "nao_vendido_na_praca" -> Map.put(com_vendas, :nao_vendido_na_praca, com_vendas.nao_vendido_na_praca + total)
        "desconsiderar" -> com_vendas
      end
    end)
  end

  def taxes_colors(atratividade_atual, sucesso_atual, conversao_atual, referencia_atratividade \\ @referencia_taxa_atratividade, referencia_sucesso \\ @referencia_taxa_sucesso, referencia_conversao \\ @referencia_taxa_conversao) do
    Logger.info "taxes_colors# atratividade_atual: #{atratividade_atual} referencia_atratividade: #{referencia_atratividade} sucesso_atual: #{sucesso_atual} referencia_sucesso: #{referencia_sucesso} conversao_atual: #{conversao_atual} referencia_conversao: #{referencia_conversao}"
    cor_conversao = if is_nil(conversao_atual) do
      :red
    else
      if Decimal.cmp(conversao_atual, Decimal.from_float(referencia_conversao)) == :gt do
        "#0daf50"
      else
        "#c00000"
      end
    end

    cor_atratividade = if is_nil(atratividade_atual) do
      :red
    else
      if Decimal.cmp(atratividade_atual, Decimal.from_float(referencia_atratividade)) == :gt do
        "#0daf50"
      else
        "#c00000"
      end
    end

    # se nao tem taxa de sucesso vai fazer o que?
    cor_sucesso = if is_nil(sucesso_atual) do
      :black
    else
      if Decimal.cmp(sucesso_atual, Decimal.from_float(referencia_sucesso)) == :gt do
        "#0daf50"
      else
        "#c00000"
      end
    end

    { cor_atratividade, cor_sucesso, cor_conversao}
  end

  # especifico 2020.1
  def ratio_color (ratio) do
    if Decimal.cmp(ratio, 0) == :gt do :green else :red
    end
  end


  def not_sold_stock_report(reduced_reasons) do
    total = reduced_reasons.mais_caro + reduced_reasons.nao_vendido_na_praca + reduced_reasons.outros_motivos
    if total == 0 do
      { 0, 0, 0 }
    else
      percent_mais_caro = Decimal.from_float((reduced_reasons.mais_caro / total) * 100) |> Decimal.round(0)
      percent_nao_vendido_na_praca = Decimal.from_float((reduced_reasons.nao_vendido_na_praca / total) * 100) |> Decimal.round(0)
      percent_outros_motivos = Decimal.from_float((reduced_reasons.outros_motivos / total) * 100) |> Decimal.round(0)
      { percent_mais_caro, percent_nao_vendido_na_praca, percent_outros_motivos }
    end
  end

  def execute_2020_1(params,topic) do

    debug_mode_without_databricks = false

    start_time = :os.system_time(:milli_seconds) # marca de inico, nao tirar daqui!
    base_info = get_base_info(params)
    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    capture_period_id = params["capture_period"]
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)

    full_data = product_line_data(params, capture_period, extract_field_as_list(params["levels"]), params["kinds"])
    previous_year_full_data = product_line_data(params, previous_year_capture_period, extract_field_as_list(params["levels"]), params["kinds"])

    filter_data = Ppa.Util.FiltersParser.parse_filters(params, capture_period_id)

    Logger.info "FULL DATA CONTENT"
    # IO.inspect capture_period , label: "Capture period"
    # IO.inspect previous_year_capture_period , label: "Previous year capture period"
    IO.inspect previous_year_full_data , label: "Previous year full data"
    IO.inspect full_data, label: "Full data:"

    IO.inspect params, label: "Params:"

    kinds_filter = params["kinds"]
    levels_filter = params["levels"]

    IO.inspect levels_filter, label: "Levels filter:"
    IO.inspect levels_filter["id"], label: "Levels filter id:"
    IO.inspect referencia_atratividade(levels_filter["id"]), label: "NOVA REFERENCIA TAXA ATRATIVIDADE:"
    IO.inspect referencia_sucesso(levels_filter["id"]), label: "NOVA REFERENCIA TAXA SUCESSO:"

    # IO.inspect kinds_ids, label: "KINDS IDS!!"
    # IO.inspect levels_ids, label: "LEVELS IDS!!"
    ############  FUNIL ############

    atratividade_atual = divide_rate(full_data["initiated_orders"], full_data["visits"])
    atratividade_anterior = divide_rate(previous_year_full_data["initiated_orders"],previous_year_full_data["visits"])
    growth_atratividade = Decimal.sub(divide(atratividade_atual,atratividade_anterior),1)
    sucesso_atual = divide_rate(full_data["all_follow_ups"], full_data["initiated_orders"])
    sucesso_anterior = divide_rate(previous_year_full_data["all_follow_ups"], previous_year_full_data["initiated_orders"])
    growth_sucesso = Decimal.sub(divide(sucesso_atual,sucesso_anterior),1)
    conversao_atual = divide_rate(full_data["all_follow_ups"], full_data["visits"])
    conversao_anterior = divide_rate(previous_year_full_data["all_follow_ups"], previous_year_full_data["visits"])
    growth_conversao = Decimal.sub(divide(conversao_atual,conversao_anterior),1)

    ## MENSALIDADE/DESCONTO/RECEITA
    growth_offered = Decimal.sub(divide(full_data["offered_medio"],previous_year_full_data["offered_medio"]),1)
    growth_discount = Decimal.sub(divide(full_data["desconto_medio"],previous_year_full_data["desconto_medio"]),1)
    growth_revenue = Decimal.sub(divide(full_data["receita"],previous_year_full_data["receita"]),1)

    growth_visitas = Decimal.sub(divide(full_data["visits"],previous_year_full_data["visits"]),1)
    growth_ordens = Decimal.sub(divide(full_data["initiated_orders"],previous_year_full_data["initiated_orders"]),1)
    growth_pagos = Decimal.sub(divide(full_data["all_follow_ups"],previous_year_full_data["all_follow_ups"]),1)


    ############  POTENCIAL NAO REALIZADO ############

    potencial_map = Ppa.Util.Analisys.SemesterEnd2019_2.potencial_map_ex(full_data, previous_year_full_data,levels_filter["id"])
    IO.inspect potencial_map, label: "Potencial map: "
    nao_realizado_atratividade = if potencial_map.nao_realizado_atratividade == 0 do
      %{ type: :text, color: :black, value: "-"}
    else
      "R$ #{format_precision(potencial_map.nao_realizado_atratividade, 2)}"
    end
    nao_realizado_sucesso = if potencial_map.nao_realizado_sucesso == 0 do
      %{ type: :text, color: :black, value: "-"}
    else
      "R$ #{format_precision(potencial_map.nao_realizado_sucesso, 2)}"
    end
    nao_realizado_atratividade_ajustado = if potencial_map.nao_realizado_atratividade == 0, do: 0, else: potencial_map.nao_realizado_atratividade |> Decimal.round(2)
    nao_realizado_sucesso_ajustado = if potencial_map.nao_realizado_sucesso == 0, do: 0, else: potencial_map.nao_realizado_sucesso |> Decimal.round(2)
    nao_realizado_total_ajustado = decimal_add(nao_realizado_sucesso_ajustado, nao_realizado_atratividade_ajustado)
    realizado_formatado = "R$ #{format_precision(potencial_map.realizado, 2)}"
    # colors = ["#a8a8a9","#4c5c68","#262626"]
    colors = ["#a8a8a9","#ac8aff","#ffa266"]
    series = [[potencial_map.realizado, potencial_map.realizado], [nil, nao_realizado_atratividade_ajustado], [nil, nao_realizado_sucesso_ajustado]]
    labels = ["2020.1 (Receita)", "Potencial (Receita)"]
    grafico_potencial_captacao = %{
      type: :chart,
      properties: %{
        type: :bar,
        colors: colors,
        series: series,
        use_alternative_data_set: true,
        series_labels: [[realizado_formatado, realizado_formatado], ["",nao_realizado_atratividade],["",nao_realizado_sucesso]],
        labels: labels,
        legend_labels: ["Realizado", "GAP | Atratividade", "GAP | Sucesso"],
        draw_values: false,
        draw_values_in_middle: true,
        draw_values_font_size: 18,
        draw_values_font_color: "#ffffff",
        draw_values_locale: "pt-BR",
        x_axis_font_size: 12,
        x_axis_font_color: "#1f2d30",
        y_axis_font_size: 12,
        y_axis_font_color: "#1f2d30",
        legend_position: "right",
        # legend_box_width: "12",
        legend_box_width: "8",
        legend_reverse: true,
        # hide_y_axis: true,
        # hide_legend: true,
        hide_x_axis_grid: true,
        # hide_y_axis_grid: true,
        hide_y_axis_border: true,
        y_axis_begin_at_zero: false,
        x_axis_title_padding: 20,
        x_axis_stacked: true,
        y_axis_stacked: true,
        bar_percentage: 0.8,
        category_percentage: 1,
        formmatted_y_axes_locale: "pt-BR",
        formmatted_y_axes_prefix: "R$ ",
      # }, width: 450, height: 280
      # }, width: 405, height: 252
      # }, width: 365, height: 226
      }, width: 328, height: 205
    }



    ## CORES PARA O GRAFICO DE POTENCIAL
    cor_conversao = if is_nil(conversao_atual) do
      :red
    else
      # if Decimal.cmp(conversao_atual, Decimal.from_float(@referencia_taxa_conversao)) == :gt do
        if Decimal.cmp(conversao_atual, potencial_map.conversao_potencial) == :gt or Decimal.cmp(conversao_atual, potencial_map.conversao_potencial) == :eq do
        :green
      else
        :red
      end
    end

    cor_atratividade = if is_nil(atratividade_atual) do
      :red
    else
      # if Decimal.cmp(atratividade_atual, Decimal.from_float(potencial_map.atratividade_potencial)) == :gt or Decimal.cmp(atratividade_atual, Decimal.from_float(potencial_map.atratividade_potencial)) == :eq do
      if Decimal.cmp(atratividade_atual, potencial_map.atratividade_potencial) == :gt or Decimal.cmp(atratividade_atual, potencial_map.atratividade_potencial) == :eq do
        :green
      else
        :red
      end
    end

    # se nao tem taxa de sucesso vai fazer o que?
    cor_sucesso = if is_nil(sucesso_atual) do
      :black
    else
      if Decimal.cmp(sucesso_atual, potencial_map.sucesso_potencial) == :gt or Decimal.cmp(sucesso_atual,potencial_map.sucesso_potencial) == :eq  do
        :green
      else
        :red
      end
    end


    ############  STOCK SERIES ############

    base_filter = Enum.at(params["baseFilters"], 0)
    ies_info = if base_filter["type"] == "university" do
      university_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.University, university_id)
    else
      group_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.EducationGroup, group_id)
    end


    Logger.info "STOCK LOCATION MEANS PRESENCIAL"
    # { _, stock_means_praca } = Ppa.Util.Analisys.SemesterEnd2019_2.stock_location_means_presencial(filter_data)

    stock_params = params
      |> Map.put("courses", "all")
      |> Map.put("type", base_filter["type"])
      |> Map.put("value", base_filter["value"])
      # |> Map.put("kinds", Enum.map(presential_kind_partition_filter, &(%{"id"=>&1})))

    stock_means = Ppa.StockHandler.retrieve_means(capture_period_id, stock_params)

    stock_charts_height = 140
    stock_charts_width = 640


    stock_map = if is_nil(stock_means) do
      # delete todos os slides do estoque presencial, mas quais sao os indices agora?
      %{
        "#DELETE_SLIDE_8" => %{ type: :delete_slide, slide_index: 7 }, # zero based
        "#DELETE_SLIDE_9" => %{ type: :delete_slide, slide_index: 8 }, # zero based
      }
    else

      stock_chart_skus = %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#1cb0c7", "#ffc400", "#686868"],
          series: [ stock_means.count_sem, stock_means.count_sem2 ],
          labels: stock_means.dates,
          legend_labels: [capture_period.name, previous_year_capture_period.name],
          # x_axis_font_size: 20,
          # y_axis_font_size: 20,
          x_axis_font_size: 15,
          y_axis_font_size: 15,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          border_width: 2,
          # y_axis_title: "Cursos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          # legend_point_style: true,
          y_axis_begin_at_zero: true
        }, width: stock_charts_width, height: stock_charts_height
      }

      stock_chart_prices = %{
        type: :chart,
        properties: %{
          type: :line,
          colors: [ "#1cb0c7", "#ffc400","#686868"],
          # series: [ stock_means.prices, stock_means.prices2, stock_means_praca ],
          series: [ stock_means.prices, stock_means.prices2 ],
          labels: stock_means.dates,
          # legend_labels: [capture_period.name, previous_year_capture_period.name, "Praça"],
          legend_labels: [capture_period.name, previous_year_capture_period.name],
          # x_axis_font_size: 20,
          # y_axis_font_size: 20,
          x_axis_font_size: 15,
          y_axis_font_size: 15,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          border_width: 2,
          # y_axis_title: "Cursos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          # legend_point_style: true,
          y_axis_begin_at_zero: true
        }, width: stock_charts_width, height: stock_charts_height
      }

      %{
        "GRAFICO_EVOLUTIVO_ESTOQUE_SKUS_1" => stock_chart_skus,
        "GRAFICO_EVOLUTIVO_ESTOQUE_PRECO_1" => stock_chart_prices,
      }
    end


    ############  STOCK SOLD/UNSOLD ############


    #### STOCK REPORT REASONS

    # stock_task_presencial = Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.stock_report(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, presential_partition_filters, capture_period) end))
    # stock_task_presencial = Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.stock_report(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, filter_data.filters.custom_filters, capture_period) end))
    IO.inspect filter_data.filters.custom_filters, label: "FILTERS.CUSTOM_FILTERS"
    stock_task_presencial = Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.stock_report_2020_1(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, filter_data.filters.custom_filters, capture_period) end))

    stock_report = if is_nil(stock_task_presencial) do
      %{}
    else
      { stock_reasons_data_presencial, stock_vendas_presencial } = if debug_mode_without_databricks do
        {
          [
              %{"status" => "desconsiderar", "total" => "5589", "vendas" => "vendida"},

              %{"status" => "mais_caro", "total" => "53282", "vendas" => "nao_vendida"},
              %{"status" => "nao_vendido_na_praca", "total" => "0", "vendas" => "nao_vendida"},
              %{"status" => "outros_motivos", "total" => "28698", "vendas" => "nao_vendida"}
          ],
          [
            %{"status" => "abaixo_da_media", "percent" => "5"},
            %{"status" => "acima_da_media", "percent" => "5"},
            %{"status" => "n_vendido", "percent" => "90"}
          ]
        }
      else
        Logger.info "WAIT FOR STOCK QUERY ( Presencial )"
        Task.await(stock_task_presencial, 1800000)
      end

      reduced_stock_vendas_presencial = if is_nil(stock_vendas_presencial) do
        %{}
      else
        reduce_stock_vendas(stock_vendas_presencial)
      end
      reduced_stock_reasons_presencial = reduce_stock_reasons(stock_reasons_data_presencial)

      Logger.info "stock_vendas_presencial: #{inspect stock_vendas_presencial}"

      # chart_data = [
      #   reduced_stock_vendas_presencial["abaixo_media"],
      #   reduced_stock_vendas_presencial["acima_media"],
      #   reduced_stock_vendas_presencial["n_vendido"]
      # ]

      IO.inspect reduced_stock_vendas_presencial, label: "REDUCED STOCK VENDAS PRESENCIAL"

      # labels = ["Abaixo da média", "Acima da média", "Não vendidos"]
      # # colors = ["#1f85a0", "#4c5c68"]
      # colors = ["#ac8aff","#ffa266","#a8a8a9"]
      # stock_chart_pie_size = 200
      # # stock_chart = pie_chart("Estoque total", chart_data, labels, 280, colors, 80, true, false, true, 20, 20, "%", 50, true)
      # # stock_chart = pie_chart("Análise do estoque vendável", chart_data, labels, 280, colors, 80, true, false, true, 20, 20, "%", 50, true, 5)
      # stock_chart = pie_chart(nil, chart_data, labels, stock_chart_pie_size, colors, 80, true, false, true, 20, 20, "%", 50, true, 0)

      vendido_abaixo_media = if Map.has_key?(reduced_stock_vendas_presencial,"abaixo_media") do reduced_stock_vendas_presencial["abaixo_media"] else Decimal.from_float(0.0) end
      vendido_acima_media = if Map.has_key?(reduced_stock_vendas_presencial,"acima_media") do reduced_stock_vendas_presencial["acima_media"] else Decimal.from_float(0.0) end

      IO.inspect vendido_abaixo_media, label: "VENDIDO ABAIXO MEDIA"
      IO.inspect vendido_acima_media, label: "VENDIDO ACIMA MEDIA"

      chart_data = [
        # Decimal.add(reduced_stock_vendas_presencial["abaixo_media"],reduced_stock_vendas_presencial["acima_media"]),
        Decimal.add(vendido_abaixo_media,vendido_acima_media),
        reduced_stock_vendas_presencial["n_vendido"]
      ]

      IO.inspect chart_data, label: "CHART DATA STOCK CHART"

      labels = ["Vendidos", "Não vendidos"]
      colors = ["#ffa266","#a8a8a9"]
      stock_chart_pie_size = 200
      # stock_chart = pie_chart("Estoque total", chart_data, labels, 280, colors, 80, true, false, true, 20, 20, "%", 50, true)
      # stock_chart = pie_chart("Análise do estoque vendável", chart_data, labels, 280, colors, 80, true, false, true, 20, 20, "%", 50, true, 5)
      # stock_chart = pie_chart(nil, chart_data, labels, 180, colors, 80, true, false, true, 20, 20, "%", 50, true, 0)
      # stock_chart = pie_chart(nil, chart_data, labels, 180, colors, 80, true, false, true, 20, 12, "%", 50, true, 0)
      stock_chart = pie_chart(nil, chart_data, labels, 200, colors, 80, true, false, true, 50, 20, "%", 50, true, 0)



      { percent_mais_caro, percent_nao_vendido_na_praca, percent_outros_motivos} = not_sold_stock_report(reduced_stock_reasons_presencial)
      # colors = ["#1f85a0", "#d9d9d9", "#4c5c68"]
      colors = ["#ac8aff","#a8a8a9","#ffa266"]
      labels = ["Preço acima do vendido na praça", "Não vendido na praça", "Outros motivos"]
      chart_data = [percent_mais_caro, percent_nao_vendido_na_praca, percent_outros_motivos]

      IO.inspect chart_data, label: "CHART DATA UNSOLD STOCK CHART"

      # unsold_stock_chart = pie_chart("Estoque sem venda", chart_data, labels, 260, colors, 80, true, false, true, 20, 20, "%", 40, true)
      # unsold_stock_chart = pie_chart("Precificaçao do estoque\n não vendável", chart_data, labels, 260, colors, 80, true, false, true, 20, 20, "%", 40, true, 5)
      # unsold_stock_chart = pie_chart(nil, chart_data, labels, 220, colors, 80, true, false, true, 20, 20, "%", 40, true, 0)
      # unsold_stock_chart = pie_chart(nil, chart_data, labels, stock_chart_pie_size, colors, 80, true, false, true, 20, 20, "%", 40, true, 0)
      unsold_stock_chart = pie_chart(nil, chart_data, labels, stock_chart_pie_size, colors, 80, true, false, true, 25, 20, "%", 40, true, 0)

      %{
        "TITULO_ESTOQUE_1" => "Estoque vendável e não vendável - Presencial #{capture_period.name}",
        "GRAFICO_ESTOQUE_1" => stock_chart,
        "GRAFICO_ESTOQUE_ENCALHADO_1" => unsold_stock_chart
      }
    end





    ############  COMPETITORS DATA ############
    competitors_map = if base_filter["type"] == "university" do
      competitors_filters = %{
        "university_id" => ies_info.id,
        "initialDate" => initial_date,
        "finalDate" => final_date
      }
      competitors_filters = if kinds_filter == [] do
        competitors_filters
      else
        Map.put(competitors_filters, "kinds", kinds_filter)
      end

      competitors_filters = if levels_filter == [] do
        competitors_filters
      else
        Map.put(competitors_filters, "levels", [levels_filter])
      end

      # IO.inspect competitors_filters, label: "Competitors filters "

      competitors_flow_map = Ppa.CompetitorsHandler.retrieve_competitors_data(competitors_filters)
      # Logger.info "competitors_flow_map: #{inspect competitors_flow_map}"


      %{
        "GRAFICO_FLUXO_CONCORRENCIA" => %{
          type: :chart,
          properties: %{
            type: :bar,
            colors: ["#35b6cc"],
            series: [ competitors_flow_map.lose_counts ],
            labels: competitors_flow_map.lose_ies,
            hide_legend: true,
            hide_x_axis_grid: true,
            hide_y_axis_grid: true,
            x_axis_font_size: 13,
            y_axis_font_size: 13,
            x_auto_skip: false,
            x_axis_font_color: "#000000",
            y_axis_font_color: "#000000",
          # }, width: 850, height: 340
          }, width: 600, height: 250
        },

        "TITULO_FLUXO_CONCORRENCIA" => "#{competitors_flow_map.lose_sum} alunos perdidos para concorrência",
        "SUBTITULO_FLUXO_CONCORRENCIA" => "Número de alunos que se interessaram pela #{ies_info.name} mas compraram outra IES",
      }
    else
      %{
        "#DELETE_SLIDE_12" => %{ type: :delete_slide, slide_index: 11 }, # zero based
        "#DELETE_SLIDE_11" => %{ type: :delete_slide, slide_index: 10 }, # zero based
      }
    end



    ############  VENDAS POR DESCONTO ############
    # estamos considerando apenas a data inicial neste caso!
    { compare_initial_date, compare_final_date, custom_period } = if not (to_iso_date_format(initial_date) == to_iso_date_format(capture_period.start)) do
      # && to_iso_date_format(final_date) == to_iso_date_format(capture_period.end))
      Logger.info "PartialPresentation::execute# DATAS DIVERGEM"
      { initial_date, final_date, true } # -> vai so ate a data final mesmo? tem que deslocar algo?
    else
      Logger.info "PartialPresentation::execute# DATAS IGUAIS"
      { capture_period.start, capture_period.end, false }
    end

    kinds_ids = map_ids(kinds_filter)
    # levels_ids = map_ids(competitors_filters["levels"])
    levels_ids = map_ids([levels_filter])

    IO.inspect kinds_filter, label: "Kinds filter"
    IO.inspect levels_filter, label: "Levels filter"
    IO.inspect kinds_ids, label: "Kinds ids"
    IO.inspect levels_ids, label: "Level ids"


    # per_discount_map = sell_per_discount(params, kinds_ids, levels_ids, compare_initial_date, compare_final_date)
    per_discount_map = Ppa.Util.Analisys.PartialPresentation.sell_per_discount(params, kinds_ids, levels_ids, compare_initial_date, compare_final_date)

    Logger.info "per_discount_map: #{inspect per_discount_map}"

    discounts_counts = Enum.map(per_discount_map, &(&1["count"]))
    discounts_labels = Enum.map(per_discount_map, &("Desconto de #{&1["normalized_discount"]}%"))

    discounts_values = Enum.map(per_discount_map, &([&1["count"]]))
    discounts_values_sum = Enum.reduce(discounts_counts, 0, &(&1 + &2))

    discounts_values_percentages_values = Enum.map(per_discount_map, &([format_precision((&1["count"] / discounts_values_sum) * 100, 0)]))
    discounts_values_percentages = Enum.map(per_discount_map, &(["#{format_precision((&1["count"] / discounts_values_sum) * 100, 0)}%"]))

    Logger.info "discounts_values_percentages: #{inspect discounts_values_percentages}"

    max_pair = Enum.reduce(per_discount_map, %{ max: 0, max_key: -1 }, fn entry, acc ->
      if (entry["count"] > acc.max) do
        %{ max: entry["count"], max_key: entry["normalized_discount"]}
      else
        acc
      end
    end)

    faixa_desconto = "#{max_pair.max_key}% e #{Decimal.add(max_pair.max_key, 5)}%"
    # discount_result = List.first(discount_mean_ex(params, levels_ids, kinds_ids))
    discount_result = List.first(Ppa.Util.Analisys.PartialPresentation.discount_mean_ex(params, levels_ids, kinds_ids))

    media_desconto_ofertas = if is_nil(discount_result) do
      ""
    else
      "#{format_precision(discount_result["avg_discount"], 2)}%"
    end

    Logger.info "discounts_values: #{inspect discounts_values} discounts_values_sum: #{inspect discounts_values_sum} max_pair: #{inspect max_pair}"


    sell_per_discount_map = %{
      "GRAFICO_VENDAS_POR_DESCONTO" => %{
        type: :chart,
        properties: %{
          type: :horizontalBar,
          colors: ["#4876ca", "#ec711e", "#a8a8a8", "#ffc609", "#589de8", "#77b54f", "#385083", "#a7511f", "#35b6cc", "#006386", "#FC8400", "#54D5EA"],
          series: discounts_values_percentages_values,
          series_labels: discounts_values_percentages,
          use_alternative_data_set: true,
          legend_labels: discounts_labels,
          draw_values: true,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          x_axis_begin_at_zero: true,
          x_axis_stacked: true,
          y_axis_stacked: true,
          x_axis_font_size: 16,
          x_axis_font_color: "#000000",
        # }, width: 830, height: 300
        }, width: 600, height: 250
      },

      "LABEL_VENDAS_POR_DESCONTO" => "A faixa de desconto entre #{faixa_desconto} apresenta a maior quantidade de vendas. A média de desconto das ofertas ativas é de #{media_desconto_ofertas}",
    }


    #SAZONALIDADE
    sazonalidade_slide = if levels_filter["id"]=="1" do
      #grad
      %{
        "#DELETE_SLIDE_15" => %{ type: :delete_slide, slide_index: 14 }, # zero based
      }
    else
      #pos
      %{
        "#DELETE_SLIDE_14" => %{ type: :delete_slide, slide_index: 13 }, # zero based
      }
    end


    ### FINALIZACAO

    # # Preciso ter um unico level para conseguir montar corretamente os assuntos 3 e 4
    # titulo_estoque_presencial = "Estoque - #{level_name} Presencial"
    # titulo_estoque_ead = "Estoque - #{level_name} EaD"

    # assuntos_2 = "Visitas"
    # assuntos_3 = "Atratividade"
    # assuntos_4 = "Estoque"
    # assuntos_5 = "Sucesso"
    # assuntos_6 = "Planejamento #{simple_next_period}"

    IO.inspect nao_realizado_total_ajustado, label: "NAO REALIZADO AJUSTADO!!"

    analysis_map = %{
      "IES_NAME_AND_PERIOD" => "#{base_info.name} - #{capture_period.name}",
      "KINDS_NAME" => Enum.join( (for n <- params["kinds"], do: n["name"])," | "),
      "T_ATRAT" => %{ type: :text, color: cor_atratividade, value: format_percent_spaced(format_precision(atratividade_atual, 2)) },
      "T_ATRAT_BLACK" => %{ type: :text, value: format_percent_spaced(format_precision(atratividade_atual, 2)) },
      "T_SUC" => %{ type: :text, color: cor_sucesso, value: format_percent_spaced(format_precision(sucesso_atual, 2)) },
      "T_SUC_BLACK" => %{ type: :text, value: format_percent_spaced(format_precision(sucesso_atual, 2)) },
      "T_CONV" => %{ type: :text, color: cor_conversao, value: format_percent_spaced(format_precision(conversao_atual, 2)) },
      "T_CONV_BLACK" => %{ type: :text, value: format_percent_spaced(format_precision(conversao_atual, 2)) },
      "T_ATRAT_PREV" => %{ type: :text, value: format_percent_spaced(format_precision(atratividade_anterior, 2)) },
      "T_SUC_PREV" => %{ type: :text, value: format_percent_spaced(format_precision(sucesso_anterior, 2)) },
      "T_CONV_PREV" => %{ type: :text, value: format_percent_spaced(format_precision(conversao_anterior, 2)) },
      "GROWTH_ATRAT" => %{ type: :text, color: ratio_color(growth_atratividade), value: format_percent_spaced(format_precision(Decimal.mult(growth_atratividade,100), 2)) },
      "GROWTH_SUC" => %{ type: :text, color: ratio_color(growth_sucesso), value: format_percent_spaced(format_precision(Decimal.mult(growth_sucesso,100), 2)) },
      "GROWTH_CONV" => %{ type: :text, color: ratio_color(growth_conversao), value: format_percent_spaced(format_precision(Decimal.mult(growth_conversao,100), 2)) },

      "BENCH_ATRAT" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(referencia_atratividade(levels_filter["id"])))}",
      "BENCH_SUC" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(referencia_sucesso(levels_filter["id"])))}",
      "BENCH_CONV" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(referencia_conversao(levels_filter["id"])))}",



      "AVG_OFFERED" => "#{format_precision(full_data["offered_medio"],2)}",
      "AVG_OFFERED_PREV" => "#{format_precision(previous_year_full_data["offered_medio"],2)}",
      "GROWTH_OFFERED" => %{ type: :text, color: ratio_color(growth_offered), value: format_percent_spaced(format_precision(Decimal.mult(growth_offered,100), 2)) },
      "AVG_DISC" => "#{format_percent_spaced(full_data["desconto_medio"])}",
      "AVG_DISC_PREV" => "#{format_percent_spaced(previous_year_full_data["desconto_medio"])}",
      "GROWTH_DISCOUNT" => %{ type: :text, color: ratio_color(growth_discount), value: format_percent_spaced(format_precision(Decimal.mult(growth_discount,100), 2)) },
      "REVENUE" => "#{Number.Delimit.number_to_delimited(full_data["receita"])}",
      "REVENUE_PREV" => "#{Number.Delimit.number_to_delimited(previous_year_full_data["receita"])}",
      "GROWTH_REVENUE" => %{ type: :text, color: ratio_color(growth_revenue), value: format_percent_spaced(format_precision(Decimal.mult(growth_revenue,100), 2)) },

      "N_VISITAS" => "#{format_precision(full_data["visits"])}",
      "N_ORDENS" => "#{format_precision(full_data["initiated_orders"])}",
      "N_PAGOS" => "#{format_precision(full_data["all_follow_ups"])}",
      "N_VISITAS_PREV" => "#{format_precision(previous_year_full_data["visits"])}",
      "N_ORDENS_PREV" => "#{format_precision(previous_year_full_data["initiated_orders"])}",
      "N_PAGOS_PREV" => "#{format_precision(previous_year_full_data["all_follow_ups"])}",
      "GROWTH_VISITAS" => %{ type: :text, color: ratio_color(growth_visitas), value: format_percent_spaced(format_precision(Decimal.mult(growth_visitas,100), 2)) },
      "GROWTH_ORDENS" => %{ type: :text, color: ratio_color(growth_ordens), value: format_percent_spaced(format_precision(Decimal.mult(growth_ordens,100), 2)) },
      "GROWTH_PAGOS" => %{ type: :text, color: ratio_color(growth_pagos), value: format_percent_spaced(format_precision(Decimal.mult(growth_pagos,100), 2)) },

      "POT_ORDENS" => "#{format_precision(potencial_map.ordens_potencial)}",
      "POT_PAGOS" => "#{format_precision(potencial_map.pagos_potencial)}",
      "POT_ATRAT" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(potencial_map.atratividade_potencial))}",
      "POT_SUC" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(potencial_map.sucesso_potencial))}",
      "POT_CONV" => "#{format_percent_spaced(Number.Delimit.number_to_delimited(potencial_map.conversao_potencial))}",

      "REALIZADO" => "#{Number.Delimit.number_to_delimited(potencial_map.realizado)}",
      "POT_NAO_REALIZADO" => "#{Number.Delimit.number_to_delimited(nao_realizado_total_ajustado)}",


      "GRAFICO_POTENCIAL_CAPTACAO" => grafico_potencial_captacao,
    } |> Map.merge(stock_map)
      |> Map.merge(competitors_map)
      |> Map.merge(sell_per_discount_map)
      |> Map.merge(stock_report)
      |> Map.merge(sazonalidade_slide)




    output = generate_presentation(analysis_map, "template_final_2020_1.pptx")

    Logger.info "output: #{output}"

    output_map = Poison.decode!(output)
    Logger.info "output_map: #{inspect output_map}"

    if output_map["sucess"] do
      Ppa.Endpoint.broadcast(topic, "analysisData", %{ filename: output_map["filename"], download_name: base_info.name })
    else
      Ppa.Endpoint.broadcast(topic, "analysisError", %{})
    end

    final_time = :os.system_time(:milli_seconds)
    Logger.info "SemesterEnd::execute_2019_2# Broadcasted #{final_time - start_time} ms"

    Logger.info "END OF execute_2020_1"
  end

  def execute_2019_2(params, topic) do
    start_time = :os.system_time(:milli_seconds) # marca de inico, nao tirar daqui!

    # debug_mode_without_databricks = true
    debug_mode_without_databricks = false

    base_info = get_base_info(params)

    level_name = Ppa.RepoPpa.get(Ppa.Level, params["levels"]["id"]).name

    admin_user_id = params["admin_id"]
    { admin_name, adjusted_email } = get_admin_info(admin_user_id)

    capture_period_id = params["capture_period"]
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    next_capture_period = Ppa.CapturePeriod.next_capture_period(capture_period)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)


    simple_period = Ppa.CapturePeriod.simple_name(capture_period)
    simple_next_period = Ppa.CapturePeriod.simple_name(next_capture_period)

    filter_data = Ppa.Util.FiltersParser.parse_filters(params, capture_period_id)
    Logger.info "filters: #{inspect filter_data}"


    ### COMPARATIVO DE SUCESSO ###

    base_sucesso = Ppa.Util.Analisys.SemesterEnd2019_2.comparativo_sucesso_graduacao(nil)

    sucesso_dates = Enum.map(base_sucesso, &(format_local(&1["date"])))
    serie_sucesso_base = Enum.map(base_sucesso, &(&1["sucesso"]))

    university_ids = parse_ies_filter(params)
    sucesso_ies = Ppa.Util.Analisys.SemesterEnd2019_2.comparativo_sucesso_graduacao(university_ids)

    serie_sucesso_ies = Enum.map(sucesso_ies, &(&1["sucesso"]))

    Logger.info "sucesso_ies: #{inspect sucesso_ies}"
    Logger.info "base_sucesso: #{inspect base_sucesso}"
    Logger.info "sucesso_dates: #{inspect sucesso_dates} serie_sucesso_ies: #{inspect serie_sucesso_ies} serie_sucesso_base: #{inspect serie_sucesso_base}"

    success_chart = %{
      type: :chart,
      properties: %{
        type: :line,
        colors: ["#1cb0c7", "#ffc400"],
        series: [ serie_sucesso_ies, serie_sucesso_base ],
        labels: sucesso_dates,
        legend_labels: [base_info.name, "Referência"],
        # draw_values: true,
        x_axis_font_size: 20,
        x_axis_font_color: "#1f2d30",
        y_axis_font_size: 20,
        y_axis_font_color: "#1f2d30",
        y_axis_title: "Taxa Sucesso (%)",
        y_axis_title_font_size: 25,
        x_axis_title_font_size: 25,
        # hide_y_axis: true,
        hide_y_axis_border: true,
        hide_legend: false,
        hide_x_axis_grid: true,
        hide_y_axis_grid: true,
        y_axis_title_padding: 20,
        x_axis_title_padding: 20,
        bar_percentage: 0.85,
        category_percentage: 0.45,
      }, width: 400, height: 200
    }


    #### FUNIL ###
    # atual, previous_semester, previous_year
    full_data = product_line_data(params, capture_period, extract_field_as_list(params["levels"]), params["kinds"])
    previous_semester_full_data = product_line_data(params, previous_capture_period, extract_field_as_list(params["levels"]), params["kinds"])
    previous_year_full_data = product_line_data(params, previous_year_capture_period, extract_field_as_list(params["levels"]), params["kinds"])

    total_paid = full_data["all_follow_ups"]
    initiated_orders = full_data["initiated_orders"]
    visits = full_data["visits"]
    visits_previous_year = previous_year_full_data["visits"]
    # visits_previous_semester = previous_semester_full_data["visits"] # ???

    total_paid_previous_semester = previous_semester_full_data["all_follow_ups"]


    # Logger.info "full_data: #{inspect full_data}"
    # Logger.info "previous_semester_full_data: #{inspect previous_semester_full_data}"
    # Logger.info "previous_year_full_data: #{inspect previous_year_full_data}"
    IO.inspect previous_year_full_data , label: "Previous year full data"
    IO.inspect full_data, label: "Full data:"


    # visits_growth = if Decimal.cmp(visits_previous_year, 0) == :eq do
    #   0
    # else
    #   Decimal.add(Decimal.div(visits, visits_previous_year), -1)
    # end
    # Logger.info "visits_growth: #{inspect visits_growth}"

    # desandou ...

    crescimento_visitas_site = Decimal.div(Decimal.from_float(@benchmark_crescimento_visitas), 100)
    crescimento_visitas_qap = Decimal.div(Decimal.from_float(@benchmark_crescimento_visitas_qap), 100)


    # reembolsos = Decimal.add(full_data["exchanged_follow_ups"], full_data["refunded_follow_ups"])
    reembolsos = Decimal.add(full_data["exchanged_follow_ups"], full_data["refunds"])
    # bos = full_data["opened_bos"]
    bos = full_data["bos"]


    # reembolsos_anterior = Decimal.add(previous_year_full_data["exchanged_follow_ups"], previous_year_full_data["refunded_follow_ups"])
    reembolsos_anterior = Decimal.add(previous_year_full_data["exchanged_follow_ups"], previous_year_full_data["refunds"])
    # bos_anterior = previous_year_full_data["opened_bos"]
    bos_anterior = previous_year_full_data["bos"]


    # ====================


    # TASKS NO DATABRICKS

    # >>>>>>>>>>>>>>>>>>
    lead_task = if debug_mode_without_databricks do
      true
    else
      Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.lead_fidelity(filter_data) end))
    end


    #### QUEBRA DE PRESENCIAL / SEMI - EAD

    levels_filter = map_ids(extract_field_as_list(params["levels"]))
    kinds_filter = map_ids(params["kinds"])

    other_kinds_query = from k in Ppa.Kind,
      where: fragment("? is null ", k.parent_id) and k.id not in ^[@kind_id_presencial],
      select: k.id
    other_kinds = Enum.map(Ppa.RepoPpa.all(other_kinds_query), &("#{&1}"))


    presential_set = MapSet.new(["#{@kind_id_presencial}"])
    others_set = MapSet.new(other_kinds)

    Logger.info "kinds_filter: #{inspect kinds_filter} presential_set: #{inspect presential_set} others_set: #{inspect others_set}"

    # faz a intersecao entre os filtros e a quebra presencial / semi
    { presential_set_filtered, others_set_filtered } = if kinds_filter == [] do
      { presential_set, others_set }
    else
      kinds_filter_set = MapSet.new(kinds_filter)

      presential_intersection = MapSet.intersection(presential_set, kinds_filter_set)
      others_intersection = MapSet.intersection(others_set, kinds_filter_set)

      Logger.info "presential_intersection: #{inspect presential_intersection} others_intersection: #{inspect others_intersection}"

      { presential_intersection, others_intersection }
    end

    Logger.info "presential_set_filtered: #{inspect presential_set_filtered} others_set_filtered: #{inspect others_set_filtered}"

    presential_kind_partition_filter = Enum.map(presential_set_filtered, &(&1))
    other_kinds_partition_filter = Enum.map(others_set_filtered, &(&1))

    Logger.info "base_custom: #{inspect filter_data.filters.custom_filters}"

    presential_partition_filters = replace_fields_values(filter_data.filters.custom_filters, %{"kind_id" => presential_kind_partition_filter})

    Logger.info "presential_partition_filters: #{inspect presential_partition_filters}"

    other_kinds_partition_filters = replace_fields_values(filter_data.filters.custom_filters, %{"kind_id" => other_kinds_partition_filter})

    Logger.info "other_kinds_partition_filters: #{inspect other_kinds_partition_filters}"


    has_presential_kind = ( presential_kind_partition_filter != [] )
    has_ead_kind = ( other_kinds_partition_filter != [] )

    # if presential_kind_partition_filter == [] do
    #   Logger.info "SEM PRESENCIAL"
    # end
    #
    # if other_kinds_partition_filter == [] do
    #   Logger.info "SEM OUTROS"
    # end


    base_filter = Enum.at(params["baseFilters"], 0)


    ############################################################################
    ##############################   PRESENCIAL         ###############################
    ############################################################################

    # pq precisa de dados presencial / ead?

    # nao seria so os dados de estoque?


    { _presential_data, _prev_presential_data, stock_task_presencial, stock_means_praca_presencial, _projecao_presencial, stock_means_presencial } = if not has_presential_kind do
      Logger.info "SEM PRESENCIAL"
      { empty_product_line_data(), empty_product_line_data(), nil, nil, nil, nil }
    else

      # essas quebras de dados que nao sao necessarias?
      # presential_data = product_line_data(params, capture_period, extract_field_as_list(params["levels"]), Enum.map(presential_kind_partition_filter, &(%{"id"=>&1})))
      # prev_presential_data = product_line_data(params, previous_capture_period, extract_field_as_list(params["levels"]), Enum.map(presential_kind_partition_filter, &(%{"id"=>&1})))


      stock_task_presencial = if debug_mode_without_databricks do
        true
      else
        Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.stock_report(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, presential_partition_filters, capture_period) end))
      end

      Logger.info "STOCK LOCATION MEANS PRESENCIAL"
      { _, stock_means_praca_presencial } = Ppa.Util.Analisys.SemesterEnd2019_2.stock_location_means_presencial(filter_data)

      # projecao_presencial = Ppa.Util.Analisys.SemesterEnd2019_2.product_line_projection_ex(params, next_capture_period, levels_filter, presential_kind_partition_filter)


      ##### STOCK SERIES
      # quando vai deletar os slides de ead e semi?
      # quando o filtro excluir eles!

      stock_params_presencial = params
        |> Map.put("courses", "all")
        |> Map.put("type", base_filter["type"])
        |> Map.put("value", base_filter["value"])
        |> Map.put("kinds", Enum.map(presential_kind_partition_filter, &(%{"id"=>&1})))

      stock_means_presencial = Ppa.StockHandler.retrieve_means(capture_period_id, stock_params_presencial)


      { nil, nil, stock_task_presencial, stock_means_praca_presencial, nil, stock_means_presencial }
    end

    # SEMESTRE ATUAL
    # total_paid_presencial = presential_data["all_follow_ups"]

    # SEMESTRE IMEDIATAMENTE ANTERIOR
    # total_paid_presencial_prev = prev_presential_data["all_follow_ups"]
    # mensalidade_presencial_prev = prev_presential_data["offered_medio"]

    # n_skus_presencial_prev = prev_presential_data["n_skus"]


    ############################################################################
    ##############################   EAD         ###############################
    ############################################################################


    { _ead_data, _prev_ead_data, stock_task_ead, stock_means_praca_ead, _projecao_outros, stock_means_ead } = if not has_ead_kind do
      Logger.info "SEM OUTROS"
      { empty_product_line_data(), empty_product_line_data(), nil, nil, nil, nil }
    else
      # se o other_kinds tiver vazio, vai pegar tudo aqui! ENTAO NAO PODE FAZER ESSE FILTRO!
      # ead_data = product_line_data(params, capture_period, extract_field_as_list(params["levels"]), Enum.map(other_kinds_partition_filter, &(%{"id"=>&1})))
      # prev_ead_data = product_line_data(params, previous_capture_period, extract_field_as_list(params["levels"]), Enum.map(other_kinds_partition_filter, &(%{"id"=>&1})))

      stock_task_ead = if debug_mode_without_databricks do
        true
      else
        Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.stock_report(filter_data.base_filters.initialDate, filter_data.base_filters.finalDate, other_kinds_partition_filters, capture_period) end))
      end

      Logger.info "STOCK LOCATION MEANS EAD"
      { _, stock_means_praca_ead } = Ppa.Util.Analisys.SemesterEnd2019_2.stock_location_means_ead(filter_data)

      # projecao_outros = Ppa.Util.Analisys.SemesterEnd2019_2.product_line_projection_ex(params, next_capture_period, levels_filter, other_kinds_partition_filter)

      stock_params_ead = params
        |> Map.put("courses", "all")
        |> Map.put("type", base_filter["type"])
        |> Map.put("value", base_filter["value"])
        |> Map.put("kinds", Enum.map(other_kinds_partition_filter, &(%{"id"=>&1}))) # sempre vai buscar os dados do ead e semi! mas se tiver filtrado de forma diferente?

      stock_means_ead = Ppa.StockHandler.retrieve_means(capture_period_id, stock_params_ead)

      { nil, nil, stock_task_ead, stock_means_praca_ead, nil, stock_means_ead }
    end

    # SEMESTRE ATUAL
    # total_paid_ead = ead_data["all_follow_ups"]
    #
    # # SEMESTRE IMEDIATAMENTE ANTERIOR
    # total_paid_ead_prev = prev_ead_data["all_follow_ups"]
    # mensalidade_ead_prev = prev_ead_data["offered_medio"]
    # n_skus_ead_prev = prev_ead_data["n_skus"]
    #
    # Logger.info "ead_data: #{inspect ead_data}"

    # mensalidade_presencial_prev_year = prev_year_presential_data["offered_medio"]
    # mensalidade_ead_prev_year = prev_year_ead_data["offered_medio"]

    # como levantar os dados de pagos e mensalidade e desconto medio?

    # >>>>>>>>>>>>>>>>>>

    # precisa quebrar os kinds!

    # qual eh a interseccao dos filtros com esses dois?
    # isso pode determinar se tem que deletar slides!

    # presential_kind_partition_filter
    # other_kinds_partition_filter

    # presential_filters = filter_data.filters.custom_filters
    # se tem kind_id, tem que fazer a interseccao
    # se nao for vazio pode usar o presencial




    # lead_fidelity_data =
    # Logger.info "lead_fidelity_data: #{inspect lead_fidelity_data}"


    # Logger.info "stock_means_praca_ead: #{inspect stock_means_praca_ead}"


    # Logger.info "projecao_presencial: #{inspect projecao_presencial}"
    # Logger.info "projecao_outros: #{inspect projecao_outros}"



    stock_charts_height = 170


    presential_stock_map = if is_nil(stock_means_presencial) do
      # delete todos os slides do estoque presencial, mas quais sao os indices agora?
      %{
        # "#DELETE_SLIDE_6" => %{ type: :delete_slide, slide_index: 6 }, # zero based
        # "#DELETE_SLIDE_7" => %{ type: :delete_slide, slide_index: 7 }, # zero based
        # "#DELETE_SLIDE_8" => %{ type: :delete_slide, slide_index: 8 }, # zero based

        "#DELETE_SLIDE_11" => %{ type: :delete_slide, slide_index: 10 }, # zero based
        "#DELETE_SLIDE_12" => %{ type: :delete_slide, slide_index: 11 }, # zero based
      }
    else

      stock_chart_skus_presencial = %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#1cb0c7", "#ffc400", "#686868"],
          series: [ stock_means_presencial.count_sem, stock_means_presencial.count_sem2 ],
          labels: stock_means_presencial.dates,
          legend_labels: [capture_period.name, previous_year_capture_period.name],
          x_axis_font_size: 20,
          y_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          border_width: 2,
          # y_axis_title: "Cursos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          # legend_point_style: true,
          y_axis_begin_at_zero: false
        }, width: 830, height: stock_charts_height
      }

      stock_chart_prices_presencial = %{
        type: :chart,
        properties: %{
          type: :line,
          colors: [ "#1cb0c7", "#ffc400","#686868"],
          series: [ stock_means_presencial.prices, stock_means_presencial.prices2, stock_means_praca_presencial ],
          labels: stock_means_presencial.dates,
          legend_labels: [capture_period.name, previous_year_capture_period.name, "Praça"],
          x_axis_font_size: 20,
          y_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          border_width: 2,
          # y_axis_title: "Cursos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          # legend_point_style: true,
          y_axis_begin_at_zero: false
        }, width: 830, height: stock_charts_height
      }

      %{
        "GRAFICO_EVOLUTIVO_ESTOQUE_SKUS_1" => stock_chart_skus_presencial,
        "GRAFICO_EVOLUTIVO_ESTOQUE_PRECO_1" => stock_chart_prices_presencial,
      }
    end

    ead_stock_map = if is_nil(stock_means_ead) do
      %{
        # "#DELETE_SLIDE_9" => %{ type: :delete_slide, slide_index: 8 }, # zero based
        # "#DELETE_SLIDE_10" => %{ type: :delete_slide, slide_index: 9 }, # zero based
        # "#DELETE_SLIDE_11" => %{ type: :delete_slide, slide_index: 10 }, # zero based

        "#DELETE_SLIDE_13" => %{ type: :delete_slide, slide_index: 12 }, # zero based
        "#DELETE_SLIDE_14" => %{ type: :delete_slide, slide_index: 13 }, # zero based
      }
    else

      stock_chart_skus_ead = %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#1cb0c7", "#ffc400"],
          series: [ stock_means_ead.count_sem, stock_means_ead.count_sem2 ],
          labels: stock_means_ead.dates,
          legend_labels: [capture_period.name, previous_year_capture_period.name],
          x_axis_font_size: 20,
          y_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          border_width: 2,
          # y_axis_title: "Cursos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          # legend_point_style: true,
          y_axis_begin_at_zero: false
        }, width: 830, height: stock_charts_height
      }

      stock_chart_prices_ead = %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#1cb0c7", "#ffc400", "#686868"],
          series: [ stock_means_ead.prices, stock_means_ead.prices2, stock_means_praca_ead ],
          labels: stock_means_ead.dates,
          legend_labels: [capture_period.name, previous_year_capture_period.name, "Brasil" ],
          x_axis_font_size: 20,
          y_axis_font_size: 20,
          x_axis_font_color: "#1f2d30",
          y_axis_font_color: "#1f2d30",
          border_width: 2,
          # y_axis_title: "Cursos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          # legend_point_style: true,
          y_axis_begin_at_zero: false
        }, width: 830, height: stock_charts_height
      }

      %{
        "GRAFICO_EVOLUTIVO_ESTOQUE_SKUS_2" => stock_chart_skus_ead,
        "GRAFICO_EVOLUTIVO_ESTOQUE_PRECO_2" => stock_chart_prices_ead,
      }
    end

    #### SEARCH_SHOWS

    # current_visits = Ppa.Util.Analisys.SemesterEnd2019_2.visits_per_week(filter_data)
    # previous_visits = Ppa.Util.Analisys.SemesterEnd2019_2.visits_per_week(filter_data)

    search_shows_params = params
      |> Map.put("type", base_filter["type"])
      |> Map.put("value", base_filter["value"])

    search_shows_data = Ppa.SearchShowsPanelHandler.exec_load_comparing_data(capture_period.id, search_shows_params)

    Logger.info "search_shows_data: #{inspect search_shows_data}"

    visits_chart = %{
      type: :chart,
      properties: %{
        type: :bar,
        colors: ["#1cb0c7", "#ffc400"],
        series: [ search_shows_data.shows, search_shows_data.previous_shows ],
        labels: search_shows_data.dates,
        legend_labels: [capture_period.name, previous_year_capture_period.name],
        # draw_values: true,
        x_axis_font_size: 20,
        x_axis_font_color: "#1f2d30",
        y_axis_font_size: 20,
        y_axis_font_color: "#1f2d30",
        y_axis_title: "Nº de Exibições",
        y_axis_title_font_size: 25,
        x_axis_title_font_size: 25,
        # hide_y_axis: true,
        hide_y_axis_border: true,
        hide_legend: false,
        hide_x_axis_grid: true,
        hide_y_axis_grid: true,
        y_axis_title_padding: 20,
        x_axis_title_padding: 20,
        bar_percentage: 0.85,
        category_percentage: 0.45,
      }, width: 730, height: 200
    }

    visits_chart_small = %{
      type: :chart,
      properties: visits_chart.properties,
      width: 400, height: 200
    }

    Logger.info "bos: #{inspect bos} bos_anterior: #{inspect bos_anterior}"

    bo_var = round_format_percent(yoy(bos, bos_anterior))
    refund_var = round_format_percent(yoy(reembolsos, reembolsos_anterior))

    #### WAIT FOR LONG RUNNING QUERIES ####

    # visits_lead_task = if not debug_mode_without_databricks do
    #   Task.async((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.lookup_visits_fidelity(filter_data) end))
    # end

    lead_fidelity_data = if debug_mode_without_databricks do
      %{"buscas_ies" => "7205", "buscas_sem_ies" => "3973", "fiel" => "1995", "indeciso" => "2958", "parcialmente_fiel" => "5210", "parcialmente_indeciso" => "1015", "venda_total" => "11178"}
    else
      Logger.info "WAIT FOR FIDELITY QUERY"
      Task.await(lead_task, 1800000)
    end


    visits_lead_task = if debug_mode_without_databricks do
      nil
    else
      Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.lookup_visits_fidelity(filter_data) end))
    end

    orders_lead_task = if debug_mode_without_databricks do
      nil
    else
      Tasks.async_handle((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.lookup_orders_fidelity(filter_data) end))
    end

    # a fidelidade dos pagos eh definida pelos fieis da adicionalidade!
    # paids_lead_task = Task.async((fn -> Ppa.Util.Analisys.SemesterEnd2019_2.lookup_paids_fidelity(filter_data) end))


    #### LEAD FIDELITY ( ADICIONALIDADE )

    Logger.info "lead_fidelity_data: #{inspect lead_fidelity_data}"


    { fiel, _ } = Integer.parse(lead_fidelity_data["fiel"])
    { parcialmente_fiel, _ } = Integer.parse(lead_fidelity_data["parcialmente_fiel"])
    { parcialmente_indeciso, _ } = Integer.parse(lead_fidelity_data["parcialmente_indeciso"])
    { indeciso, _ } = Integer.parse(lead_fidelity_data["indeciso"])

    # total usado pra calcular percentuais!
    { total, _ } = Integer.parse(lead_fidelity_data["venda_total"])


    # buscaram_marca = fiel + parcialmente_fiel
    # buscaram_sem_marca = parcialmente_indeciso + indeciso


    {
      label_adc_fiel,
      label_adc_indeciso,
      sublabel_adc_fiel,
      sublabel_adc_indeciso,
      parcialmente_fiel,
      parcialmente_indeciso,
      label_indeciso_1,
      label_indeciso_2
    } = if parcialmente_fiel >= parcialmente_indeciso do
      Logger.info ">>>>> SLIDE INVERTIDO"
      {
        "Visitaram apenas sua marca",
        "Visitaram diversas marcas",
        "Buscaram sua marca",
        "Buscaram sem marca",
        parcialmente_indeciso,
        parcialmente_fiel,
        "Indeciso pelo Custo Benefício",
        "Indeciso pela Marca"
      }
    else
      Logger.info ">>>>> SLIDE PADRAO"
      {
        "Buscaram sua marca",
        "Buscara sem marca",
        "Visitaram apenas sua marca",
        "Visitaram outras marcas também",
        parcialmente_fiel,
        parcialmente_indeciso,
        "Indeciso pela Marca",
        "Indeciso pelo Custo Benefício"
      }
    end


    map_adicionalidade = if total == 0 do
      %{}
    else

      percentual_fiel = Decimal.from_float(fiel / total)
      percentual_parcialmente_fiel = Decimal.from_float(parcialmente_fiel / total)
      percentual_parcialmente_indeciso = Decimal.from_float(parcialmente_indeciso / total)
      percentual_indeciso = Decimal.from_float(indeciso / total)


      Logger.info "percentual_indeciso: #{inspect percentual_indeciso}"

      percentual_fiel_formatted = if fiel == 0, do: "", else: round_format_percent(percentual_fiel)
      percentual_parcialmente_fiel_formatted = if parcialmente_fiel == 0, do: "", else: round_format_percent(percentual_parcialmente_fiel)
      percentual_parcialmente_indeciso_formatted = if parcialmente_indeciso == 0, do: "", else: round_format_percent(percentual_parcialmente_indeciso)
      percentual_indeciso_formatted = if indeciso == 0, do: "", else: round_format_percent(percentual_indeciso)


      # draw values com draw percentagens so funciona se sempre quiser desenhar os valores e os percentuais
        # como nao queremos desenhar os valores, so os percentuais, vamos usar draw_values com use_alternative_data_set

      fiel_ajustado = Decimal.mult(total_paid, percentual_fiel) |> Decimal.round
      parcialmente_fiel_ajustado = Decimal.mult(total_paid, percentual_parcialmente_fiel) |> Decimal.round
      indeciso_ajustado = Decimal.mult(total_paid, percentual_indeciso) |> Decimal.round
      parcialmente_indeciso_ajustado = Decimal.add(total_paid, Decimal.mult(fiel_ajustado, -1))
        |> Decimal.add(Decimal.mult(parcialmente_fiel_ajustado, -1))
        |> Decimal.add(Decimal.mult(indeciso_ajustado, -1))


      map_adicionalidade = %{
        "N_FIEL" => "#{format_precision(fiel_ajustado)}",
        "N_P_FIEL" => "#{format_precision(parcialmente_fiel_ajustado)}",
        "N_INDECISO" => "#{format_precision(indeciso_ajustado)}",
        "N_P_INDECISO" => "#{format_precision(parcialmente_indeciso_ajustado)}",

        "LABEL_ADC_FIEL" => label_adc_fiel,
        "LABEL_ADC_INDECISO" => label_adc_indeciso,

        "SUBLABEL_ADC_FIEL" => sublabel_adc_fiel,
        "SUBLABEL_ADC_INDECISO" => sublabel_adc_indeciso,


        "GRAFICO_ADICIONALIDADE" => %{
          type: :chart,
          properties: %{
            type: :horizontalBar,
            colors: ["#5bc0be", "#377ba3", "#255c7b", "#163c50"],
            # colors: ["#163c50", "#255c7b", "#377ba3", "#5bc0be"],
            # colors: ["#163c50", "#255c7b", "#377ba3", "#28acc3"],
            # series: [[fiel], [parcialmente_fiel], [parcialmente_indeciso], [indeciso]],
            series: [[percentual_fiel], [percentual_parcialmente_fiel], [percentual_parcialmente_indeciso], [percentual_indeciso]],
            series_labels: [[percentual_fiel_formatted], [percentual_parcialmente_fiel_formatted], [percentual_parcialmente_indeciso_formatted],[percentual_indeciso_formatted]],
            use_alternative_data_set: true,
            legend_labels: ["Fiel", label_indeciso_1, label_indeciso_2, "Totalmente Indeciso"],
            legend_point_style: true,
            draw_values: true,
            draw_values_in_middle: true,
            draw_values_font_size: 30,
            draw_values_font_color: "#ffffff",
            hide_x_axis: true,
            hide_x_axis_grid: true,
            hide_y_axis_grid: true,
            hide_x_axis_border: true,
            hide_y_axis_border: true,
            x_axis_begin_at_zero: true,
            x_axis_stacked: true,
            y_axis_stacked: true,
            x_axis_font_size: 16,
            x_axis_font_color: "#1f2d30",
            legend_padding: 50,
          }, width: 800, height: 100
        }
      }



      #### DIVISAO DO FUNIL  ( FIEIS / INDECISOS ) #####

      visits_lead_data = if is_nil(visits_lead_task) do
        %{fiel: "534", total: "9768"}
      else
        Task.await(visits_lead_task, 1800000)
      end

      # ESTA ESPERANDO PELAS TASKS AQUI MESMO! NAO PERDE TEMPO ASSIM?

      orders_lead_data = if is_nil(orders_lead_task) do
        %{fiel: "170", total: "2003"}
      else
        Task.await(orders_lead_task, 1800000)
      end
      # paids_lead_data = Task.await(paids_lead_task, 1800000)

      Logger.info "visits_lead_data: #{inspect visits_lead_data}"

      Logger.info "orders_lead_data: #{inspect orders_lead_data}"

      # Logger.info "paids_lead_data: #{inspect paids_lead_data}"

      { visitas_fiel, _ } = Integer.parse(visits_lead_data.fiel)
      { visitas_total, _ } = Integer.parse(visits_lead_data.total)

      { ordens_fiel, _ } = Integer.parse(orders_lead_data.fiel)
      { ordens_total, _ } = Integer.parse(orders_lead_data.total)

      # { pagos_fiel, _ } = Integer.parse(paids_lead_data.fiel)
      # { pagos_total, _ } = Integer.parse(paids_lead_data.total)

      percentual_visitas_fiel = Decimal.div(visitas_fiel, visitas_total)
      percentual_ordens_fiel = Decimal.div(ordens_fiel, ordens_total)
      # percentual_pagos_fiel = Decimal.div(pagos_fiel, pagos_total)
      percentual_pagos_fiel = percentual_fiel # usando o percentual fiel da divisao dos pagos!
      # mas esta usando o desse semestre?

      percentual_visitas_indeciso = Decimal.add(1, Decimal.mult(percentual_visitas_fiel, -1))

      Logger.info "percentual_visitas_indeciso: #{percentual_visitas_indeciso} percentual_visitas_fiel: #{percentual_visitas_fiel}"

      # QUEBRA O FUNIL PELOS PERCENTAIS DE FIDELIDADE
      # ( para ter coerencia com o valor de pagos total do quero alunos)

      # FIEIS

      visits_fiel = Decimal.mult(visits, percentual_visitas_fiel) |> Decimal.round
      initiated_orders_fiel = Decimal.mult(initiated_orders, percentual_ordens_fiel) |> Decimal.round
      total_paid_fiel = Decimal.mult(total_paid, percentual_pagos_fiel) |> Decimal.round


      # fazendo o ajuste do semestre anterior pela mesma relacao
      total_paid_fiel_previous_semester = Decimal.mult(total_paid_previous_semester, percentual_pagos_fiel) |> Decimal.round
      total_paid_indeciso_previous_semester = Decimal.add(total_paid_previous_semester, Decimal.mult(total_paid_fiel_previous_semester, -1))


      Logger.info "total_paid_previous_semester: #{total_paid_previous_semester} total_paid_fiel_previous_semester: #{total_paid_fiel_previous_semester} percentual_pagos_fiel: #{percentual_pagos_fiel}"


      # INDECISOS
      visits_indeciso = Decimal.add(visits, Decimal.mult(visits_fiel, -1))
      initiated_orders_indeciso = Decimal.add(initiated_orders, Decimal.mult(initiated_orders_fiel, -1))
      total_paid_indeciso = Decimal.add(total_paid, Decimal.mult(total_paid_fiel, -1))

      # calculo do potencial fiel desse semestre, com base no semestre do ano passado ( prev_year )

      has_qap = check_qap(filter_data)
      Logger.info "has_qap: #{inspect has_qap}"


      # existem duas divisoes

      # POTENCIAL -> vai para o funil de potencial do semestre da apresentacao 2019.2 no atual

      # E

      # PROJECAO POTENCIAL -> vai para a projecao do proximo semestre 2020.1

      ##### POTENCIAL #####

      # este daqui tem um teste ali em baixo, nao vai sair zerado
      visitas_potencial_fiel_calculado =
          Decimal.mult(visits_previous_year, percentual_visitas_fiel)   # visitas do ano anterior, mas o ano anterior eh o ano referente ao semestre atual!
            |> Decimal.mult(Decimal.add(crescimento_visitas_site, 1))
            |> Decimal.round

      # calculo do potencial indeciso desse semestre, com base no semestre do ano passado ( prev_year )
      visitas_potencial_indeciso_calculado = if Decimal.cmp(visits_previous_year, 0) == :eq do
        # pq tem esse teste aqui? -> pq o potencial do indeciso que nao tem qap eh sempre ter qap
        crescimento = if has_qap do
          Decimal.div(Decimal.from_float(@benchmark_crescimento_visitas), 100)
        else
          Decimal.div(Decimal.from_float(@benchmark_crescimento_visitas_qap), 100)
        end

        Logger.info "visits_previous_year ZERADO crescimento: #{crescimento} visits: #{visits} percentual_visitas_indeciso: #{percentual_visitas_indeciso}"

        Decimal.mult(visits, percentual_visitas_indeciso)
          |> Decimal.mult(Decimal.add(crescimento, 1))
          |> Decimal.round
      else
        # mas se o ano anterior nao eh zerado nao faz essa diferenca de crescimento?
        Decimal.mult(visits_previous_year, percentual_visitas_indeciso)
          |> Decimal.mult(Decimal.add(crescimento_visitas_site, 1))
          |> Decimal.round
      end

      Logger.info "visitas_potencial_fiel_calculado: #{visitas_potencial_fiel_calculado} visitas_fiel: #{visitas_fiel} visitas_potencial_indeciso_calculado: #{visitas_potencial_indeciso_calculado} visits_indeciso: #{visits_indeciso}"

      # o fiel eh sempre sem qap
      # nao vamos considerar efeito de qap sobre o fiel!
      visitas_potencial_fiel = if Decimal.cmp(visits_fiel, visitas_potencial_fiel_calculado) == :gt do
        visits_fiel
      else
        visitas_potencial_fiel_calculado
      end

      # aqui diz que eh sem qap, mas se visits_previous_year = 0 e nao tem QAP -> entao ja foi aplicado crescimento QAP sobre as visitas atuais!


      # o indeciso tem sem e com qap, tem que escolher depois de levantar has_qap qual vai usar
      visits_potencial_indeciso_sem_qap = if Decimal.cmp(visits_indeciso, visitas_potencial_indeciso_calculado) == :gt do
        visits_indeciso
      else
        visitas_potencial_indeciso_calculado
      end


      # potencial de indeciso com qap, com base no semestre do ano passado
        # mas se nao tem visitas do ano passado? -> usa as visitas do ano atual mesmo!

        # se esta em 2019.2  -> visits_previous_year = 2018.2 -> nao eh esse semestre que queremos!
      visits_potencial_indeciso_com_qap = if Decimal.cmp(visits_previous_year, 0) == :eq do
        Decimal.mult(visits, percentual_visitas_indeciso)
          |> Decimal.mult(Decimal.add(Decimal.div(Decimal.from_float(@benchmark_crescimento_visitas_qap), 100), 1))
          |> Decimal.round
      else
        visits_previous_year
        |> Decimal.mult(Decimal.add(crescimento_visitas_qap, 1))
        |> Decimal.mult(percentual_visitas_indeciso)
      end


      # TAXAS E POTENCIAIS DO FUNIL
      atratividade_fiel = Decimal.div(initiated_orders_fiel, visits_fiel)
      sucesso_fiel = Decimal.div(total_paid_fiel, initiated_orders_fiel)
      conversao_fiel = Decimal.div(total_paid_fiel, visits_fiel)

      Logger.info "visitas_potencial_fiel: #{visitas_potencial_fiel} atratividade_fiel: #{atratividade_fiel}"

      atratividade_indeciso = Decimal.div(initiated_orders_indeciso, visits_indeciso)
      sucesso_indeciso = Decimal.div(total_paid_indeciso, initiated_orders_indeciso)
      conversao_indeciso = Decimal.div(total_paid_indeciso, visits_indeciso)

      atratividade_fiel_potencial = if Decimal.cmp(atratividade_fiel, Decimal.div(Decimal.from_float(@benchmark_atratividade), 100)) == :gt do
        atratividade_fiel
      else
        Decimal.div(Decimal.from_float(@benchmark_atratividade), 100)
      end

      atratividade_indeciso_potencial = if Decimal.cmp(atratividade_indeciso, Decimal.div(Decimal.from_float(@benchmark_atratividade), 100)) == :gt do
        atratividade_indeciso
      else
        Decimal.div(Decimal.from_float(@benchmark_atratividade), 100)
      end

      sucesso_fiel_potencial = if Decimal.cmp(sucesso_fiel, Decimal.div(Decimal.from_float(@benchmark_sucesso), 100)) == :gt do
        sucesso_fiel
      else
        Decimal.div(Decimal.from_float(@benchmark_sucesso), 100)
      end

      sucesso_indeciso_potencial = if Decimal.cmp(sucesso_indeciso, Decimal.div(Decimal.from_float(@benchmark_sucesso), 100)) == :gt do
        sucesso_indeciso
      else
        Decimal.div(Decimal.from_float(@benchmark_sucesso), 100)
      end

      conversao_fiel_potencial = Decimal.mult(sucesso_fiel_potencial, atratividade_fiel_potencial)
      conversao_indeciso_potencial = Decimal.mult(sucesso_indeciso_potencial, atratividade_indeciso_potencial)

      # FUNIL POTENCIAL FIEL
      initiated_orders_potencial_fiel = Decimal.mult(visitas_potencial_fiel, atratividade_fiel_potencial)
      total_paid_potencial_fiel = Decimal.mult(initiated_orders_potencial_fiel, sucesso_fiel_potencial)




      # visitas_potencial_indeciso_projecao_qap =
      # 18.2 X relacao indeciso x crescimento qap

      # visits_potencial_indeciso -> se ja tem qap


      visits_potencial_indeciso = if has_qap do
        visits_potencial_indeciso_sem_qap
      else
        visits_potencial_indeciso_com_qap
      end


      initiated_orders_potencial_indeciso = Decimal.mult(visits_potencial_indeciso, atratividade_indeciso_potencial)
      total_paid_potencial_indeciso = Decimal.mult(initiated_orders_potencial_indeciso, sucesso_indeciso_potencial)

      { cor_atratividade_f, cor_sucesso_f, cor_conversao_f } = taxes_colors(Decimal.mult(atratividade_fiel, 100), Decimal.mult(sucesso_fiel, 100), Decimal.mult(conversao_fiel, 100), @benchmark_atratividade, @benchmark_sucesso, @benchmark_conversao)
      { cor_atratividade_i, cor_sucesso_i, cor_conversao_i } = taxes_colors(Decimal.mult(atratividade_indeciso, 100), Decimal.mult(sucesso_indeciso, 100), Decimal.mult(conversao_indeciso, 100), @benchmark_atratividade, @benchmark_sucesso, @benchmark_conversao)

      Logger.info "cor_atratividade_f: #{cor_atratividade_f} cor_sucesso_f: #{cor_sucesso_f} cor_conversao_f: #{cor_conversao_f}"

      legenda_potencial_indeciso = if has_qap do
        "Considerando o crescimento de visitas do site de 19%"
      else
        "Considerando crescimento de visitas de 87% com adesão ao Quero Pago"
      end

      map_funil_fiel_indeciso = %{
        "N_VISITAS_F" => "#{format_precision(visits_fiel)}",
        "N_ORDENS_F" => "#{format_precision(initiated_orders_fiel)}",
        "N_PAGOS_F" => "#{format_precision(total_paid_fiel)}",

        "N_VISITAS_F_P" => "#{format_precision(visitas_potencial_fiel)}",
        "N_ORDENS_F_P" => "#{format_precision(initiated_orders_potencial_fiel)}",
        "N_PAGOS_F_P" => "#{format_precision(total_paid_potencial_fiel)}",

        "N_VISITAS_I" => "#{format_precision(visits_indeciso)}",
        "N_ORDENS_I" => "#{format_precision(initiated_orders_indeciso)}",
        "N_PAGOS_I" => "#{format_precision(total_paid_indeciso)}",

        "N_VISITAS_I_P" => "#{format_precision(visits_potencial_indeciso)}",
        "N_ORDENS_I_P" => "#{format_precision(initiated_orders_potencial_indeciso)}",
        "N_PAGOS_I_P" => "#{format_precision(total_paid_potencial_indeciso)}",

        # round_format_percent -> nao faz o delimit!
        # deveria fazer sempre?

        "ATRATIVIDADE_F" => %{ type: :text, color: cor_atratividade_f, value: round_format_percent(atratividade_fiel, 2) },
        "SUCESSO_F" => %{ type: :text, color: cor_sucesso_f, value: round_format_percent(sucesso_fiel, 2) },
        "CONVERSAO_F" => %{ type: :text, color: cor_conversao_f, value: round_format_percent(conversao_fiel, 2) },

        "ATRATIVIDADE_I" => %{ type: :text, color: cor_atratividade_i, value: round_format_percent(atratividade_indeciso, 2) },
        "SUCESSO_I" => %{ type: :text, color: cor_sucesso_i, value: round_format_percent(sucesso_indeciso, 2) },
        "CONVERSAO_I" => %{ type: :text, color: cor_conversao_i, value: round_format_percent(conversao_indeciso, 2) },

        "ATRATIVIDADE_F_P" => %{ type: :text, color: cor_atratividade_f, value: round_format_percent(atratividade_fiel_potencial, 2) },
        "SUCESSO_F_P" => %{ type: :text, color: cor_sucesso_f, value: round_format_percent(sucesso_fiel_potencial, 2) },
        "CONVERSAO_F_P" => %{ type: :text, color: cor_conversao_f, value: round_format_percent(conversao_fiel_potencial, 2) },

        "ATRATIVIDADE_I_P" => %{ type: :text, color: cor_atratividade_i, value: round_format_percent(atratividade_indeciso_potencial, 2) },
        "SUCESSO_I_P" => %{ type: :text, color: cor_sucesso_i, value: round_format_percent(sucesso_indeciso_potencial, 2) },
        "CONVERSAO_I_P" => %{ type: :text, color: cor_conversao_i, value: round_format_percent(conversao_indeciso_potencial, 2) },

        "LEGENDA_POTENCIAL_INDECISO" => legenda_potencial_indeciso,
      }

      # PQ TA GERANDO ISSO?
      # QUANDO QUE ISSO SAI SEM DADOS?
      # projecao nao tem mais quebra de linha de produto
      # precisa levantar toda a projecao do filtro
      projecao_total = Ppa.Util.Analisys.SemesterEnd2019_2.product_line_projection_ex(params, next_capture_period, levels_filter, kinds_filter)

      Logger.info "projecao_total: #{inspect projecao_total}"

      # projecao_total.base_projection -> fieis do ano anterior

      # precisa melhorar a relacao de fiel_indeciso que mostra aqui!
      # senao vai continaur mostrando merda!

      { map_projection, projection_table_map } = if is_nil(projecao_total.base_projection) or is_nil(projecao_total.max_projection) do
        { %{}, %{} }
      else


        projection_series = [
          # [total_paid_fiel_previous_semester, total_paid_fiel, total_paid_fiel_previous_semester, pagos_projecao_potencial_fiel], # FIEL
          [total_paid_fiel_previous_semester, total_paid_fiel, projecao_total.base_projection, projecao_total.base_projection], # FIEL
          # [total_paid_indeciso_previous_semester, total_paid_indeciso, nil, pagos_projecao_potencial_indeciso] # INDECISO
          [total_paid_indeciso_previous_semester, total_paid_indeciso, nil, projecao_total.max_projection - projecao_total.base_projection] # INDECISO
        ]

        # potencial_total = Decimal.add(pagos_projecao_potencial_indeciso, pagos_projecao_potencial_fiel) |> Decimal.round
        # NAO TEM MAIS QUEBRA EAD PRESENCIAL
        # TEM QUEBRA FIEL INDECISO


        projection_table_map = %{
          "YOY_ORG" => round_format_percent(yoy(projecao_total.base_projection, total_paid_previous_semester)),
          "PROJ_ORG" => format_precision(projecao_total.base_projection),
          # "YOY_POTENCIAL" => round_format_percent(yoy(potencial_total, Decimal.add(total_paid_fiel_previous_semester, total_paid_indeciso_previous_semester))),
          "YOY_POTENCIAL" => round_format_percent(yoy(projecao_total.max_projection, total_paid_previous_semester)),
          # "PROJ_POTENCIAL" => format_precision(potencial_total),
          "PROJ_POTENCIAL" => format_precision(projecao_total.max_projection),
        }


        projection_legend_labels = ["Fiel", "Indeciso"]

        projection_labels = ["2019.1", "2019.2", "Orgânico","Potencial"]

        projection_chart =  %{
          type: :chart,
          properties: %{
            type: :bar,
            colors: ["#1985a1", "#003d52"],
            labels: projection_labels,
            series: projection_series,
            legend_labels: projection_legend_labels, # ["Presencial", "Ead + Semi"],
            hide_x_axis_grid: true,
            hide_y_axis_grid: true,
            hide_y_axis_border: true,
            x_axis_font_size: 25,
            x_axis_font_color: "#1f2d30",
            y_axis_font_size: 25,
            y_axis_font_color: "#1f2d30"
          }, width: 500, height: 200
        }

        legenda_potencial = if has_qap do
          "Considerando que a IES captura o crescimento de visitas projetado do site de 19%, e as melhores taxas entre o benchmark e o resultado da IES em 2019.2"
        else
          "Considerando que a IES captura o crescimento de visitas projetado de 87% com adesão ao QP, e as melhores taxas entre o benchmark e o resultado da IES em 2019.2"
        end

        map_projection = %{
          "GRAFICO_PROJECAO" => projection_chart,
          "LEGENDA_POTENCIAL_PROJECAO" => "Projeção Potencial: " <> legenda_potencial
        }

        { map_projection, projection_table_map }
      end


      map_funil_fiel_indeciso
        |> Map.merge(map_adicionalidade)
        |> Map.merge(map_projection)
        |> Map.merge(projection_table_map)

    end

    #### STOCK REPORT REASONS

    # stock_reasons_data_presencial = [%{"status" => "desconsiderar", "total" => "5589", "vendas" => "vendida"}, %{"status" => "mais_caro", "total" => "53282", "vendas" => "nao_vendida"}, %{"status" => "nao_vendido_na_praca", "total" => "903", "vendas" => "nao_vendida"}, %{"status" => "outros_motivos", "total" => "28698", "vendas" => "nao_vendida"}]
    # stock_reasons_data_ead = [%{"status" => "desconsiderar", "total" => "5589", "vendas" => "vendida"}, %{"status" => "mais_caro", "total" => "53282", "vendas" => "nao_vendida"}, %{"status" => "nao_vendido_na_praca", "total" => "903", "vendas" => "nao_vendida"}, %{"status" => "outros_motivos", "total" => "28698", "vendas" => "nao_vendida"}]


    stock_report_presential = if is_nil(stock_task_presencial) do
      %{}
    else
      { stock_reasons_data_presencial, stock_vendas_presencial } = if debug_mode_without_databricks do
        {
          [
              %{"status" => "desconsiderar", "total" => "5589", "vendas" => "vendida"},

              %{"status" => "mais_caro", "total" => "53282", "vendas" => "nao_vendida"},
              %{"status" => "nao_vendido_na_praca", "total" => "0", "vendas" => "nao_vendida"},
              %{"status" => "outros_motivos", "total" => "28698", "vendas" => "nao_vendida"}
          ],
          [
            %{"status" => "abaixo_da_media", "percent" => "5"},
            %{"status" => "acima_da_media", "percent" => "5"},
            %{"status" => "n_vendido", "percent" => "90"}
          ]
        }
      else
        Logger.info "WAIT FOR STOCK QUERY ( Presencial )"
        Task.await(stock_task_presencial, 1800000)
      end

      reduced_stock_vendas_presencial = if is_nil(stock_vendas_presencial) do
        %{}
      else
        reduce_stock_vendas(stock_vendas_presencial)
      end
      reduced_stock_reasons_presencial = reduce_stock_reasons(stock_reasons_data_presencial)

      Logger.info "stock_vendas_presencial: #{inspect stock_vendas_presencial}"

      chart_data = [
        reduced_stock_vendas_presencial["abaixo_media"],
        reduced_stock_vendas_presencial["acima_media"],
        reduced_stock_vendas_presencial["n_vendido"]
      ]

      labels = ["Abaixo da média", "Acima da média", "Não vendidos"]
      colors = ["#1f85a0", "#4c5c68"]
      # stock_chart = pie_chart("Estoque total", chart_data, labels, 280, colors, 80, true, false, true, 20, 20, "%", 50, true)
      # stock_chart = pie_chart("Análise do estoque vendável", chart_data, labels, 280, colors, 80, true, false, true, 20, 20, "%", 50, true, 5)
      stock_chart = pie_chart(nil, chart_data, labels, 240, colors, 80, true, false, true, 20, 20, "%", 50, true, 0)

      { percent_mais_caro, percent_nao_vendido_na_praca, percent_outros_motivos} = not_sold_stock_report(reduced_stock_reasons_presencial)
      colors = ["#1f85a0", "#d9d9d9", "#4c5c68"]
      labels = ["Preço acima do vendido na praça", "Não vendido na praça", "Outros motivos"]
      chart_data = [percent_mais_caro, percent_nao_vendido_na_praca, percent_outros_motivos]

      # unsold_stock_chart = pie_chart("Estoque sem venda", chart_data, labels, 260, colors, 80, true, false, true, 20, 20, "%", 40, true)
      # unsold_stock_chart = pie_chart("Precificaçao do estoque\n não vendável", chart_data, labels, 260, colors, 80, true, false, true, 20, 20, "%", 40, true, 5)
      unsold_stock_chart = pie_chart(nil, chart_data, labels, 220, colors, 80, true, false, true, 20, 20, "%", 40, true, 0)

      %{
        "TITULO_ESTOQUE_1" => "Estoque vendável e não vendável - Presencial #{capture_period.name}",
        "GRAFICO_ESTOQUE_1" => stock_chart,
        "GRAFICO_ESTOQUE_ENCALHADO_1" => unsold_stock_chart
      }
    end

    stock_report_ead = if is_nil(stock_task_ead) do
      %{}
    else

      { stock_reasons_data_ead, stock_vendas_ead }  = if debug_mode_without_databricks do
        # [%{"status" => "desconsiderar", "total" => "5589", "vendas" => "vendida"}, %{"status" => "mais_caro", "total" => "53282", "vendas" => "nao_vendida"}, %{"status" => "nao_vendido_na_praca", "total" => "903", "vendas" => "nao_vendida"}, %{"status" => "outros_motivos", "total" => "28698", "vendas" => "nao_vendida"}]
        {
          [
            %{"status" => "desconsiderar", "total" => "2", "vendas" => "vendida"},
            %{"status" => "outros_motivos", "total" => "50", "vendas" => "nao_vendida"}
          ],
          [
            %{"status" => "abaixo_da_media", "percent" => "10"},
            %{"status" => "acima_da_media", "percent" => "10"},
            %{"status" => "n_vendido", "percent" => "80"}
          ]
        }
      else
        Logger.info "WAIT FOR STOCK QUERY ( EAD )"
        Task.await(stock_task_ead, 1800000)
      end

      Logger.info "stock_vendas_ead: #{inspect stock_vendas_ead}"
      Logger.info "stock_reasons_data_ead: #{inspect stock_reasons_data_ead}"

      reduced_stock_vendas_ead = if is_nil(stock_vendas_ead) do
        %{}
      else
        reduce_stock_vendas(stock_vendas_ead)
      end

      reduced_stock_reasons_ead = reduce_stock_reasons(stock_reasons_data_ead)


      chart_data = [
        reduced_stock_vendas_ead["abaixo_media"],
        reduced_stock_vendas_ead["acima_media"],
        reduced_stock_vendas_ead["n_vendido"]
      ]


      labels = ["Abaixo da média", "Acima da média", "Não vendidos"]
      colors = ["#1f85a0", "#4c5c68"]
      # stock_chart_ead = pie_chart("Estoque total", chart_data, labels, 240, colors, 80, true, false, true, 20, 20, "%", 50, true)
      stock_chart_ead = pie_chart(nil, chart_data, labels, 240, colors, 80, true, false, true, 20, 20, "%", 50, true, 0)

      { percent_mais_caro_ead, percent_nao_vendido_na_praca_ead, percent_outros_motivos_ead} = not_sold_stock_report(reduced_stock_reasons_ead)

      chart_data = [percent_mais_caro_ead, percent_nao_vendido_na_praca_ead, percent_outros_motivos_ead]
      colors = ["#1f85a0", "#d9d9d9", "#4c5c68"]
      labels = ["Preço acima do vendido na praça", "Não vendido na praça", "Outros motivos"]

      # unsold_stock_chart_ead = pie_chart("Estoque sem venda", chart_data, labels, 220, colors, 80, true, false, true, 20, 20, "%", 40, true)
      unsold_stock_chart_ead = pie_chart(nil, chart_data, labels, 220, colors, 80, true, false, true, 20, 20, "%", 40, true, 0)

      %{
        "TITULO_ESTOQUE_2" => "Estoque vendável e não vendável - Ead e Semi #{capture_period.name}",
        "GRAFICO_ESTOQUE_2" => stock_chart_ead,
        "GRAFICO_ESTOQUE_ENCALHADO_2" => unsold_stock_chart_ead,
      }
    end


    # SLIDES DE OTIMIZACAO DE TAXAS
    # ( informacoes de bo e reembolsos )


    # bo_var = format_percent_spaced(Decimal.mult(Decimal.add(Decimal.div(bos , bos_anterior), - 1), 100))
    # refund_var = format_percent_spaced(Decimal.mult(Decimal.add(Decimal.div(reembolsos , reembolsos_anterior), - 1), 100))
    bo_var_color = if Decimal.cmp(bos, bos_anterior) == :gt, do: "#c00000", else: "#0daf50"
    refund_var_color = if Decimal.cmp(reembolsos, reembolsos_anterior) == :gt, do: "#c00000", else: "#0daf50"


    ### FINALIZACAO

    # Preciso ter um unico level para conseguir montar corretamente os assuntos 3 e 4
    titulo_estoque_presencial = "Estoque - #{level_name} Presencial"
    titulo_estoque_ead = "Estoque - #{level_name} EaD"


    assuntos_2 = "Visitas"
    assuntos_3 = "Atratividade"
    assuntos_4 = "Estoque"
    assuntos_5 = "Sucesso"
    assuntos_6 = "Planejamento #{simple_next_period}"


    analysis_map = %{
      "INITIAL_TITLE" => "Resultados da Captação",
      "IES_NAME" => base_info.name,
      "PERIOD" => capture_period.name,
      "PERIOD_SIMPLE" => simple_period,
      "IES_NAME_AND_PERIOD" => "#{base_info.name} - #{capture_period.name}",

      "P_PERIOD" => previous_year_capture_period.name,

      "USER_NAME" => admin_name,
      "USER_EMAIL" => adjusted_email,

      "ASSUNTOS_1" => "Resultados #{simple_period}",
      "ASSUNTOS_2" => assuntos_2,
      "ASSUNTOS_3" => assuntos_3,
      "ASSUNTOS_4" => assuntos_4,
      "ASSUNTOS_5" => assuntos_5,
      "ASSUNTOS_6" => assuntos_6,

      "TITULO_ESTOQUE_PRESENCIAL" => titulo_estoque_presencial,
      "TITULO_ESTOQUE_EAD" => titulo_estoque_ead,

      "TITULO_ADICIONALIDADE" => "Adicionalidade #{simple_period}",


      "TITULO_PLANEJAMENTO" => "Planejamento #{next_capture_period.name}",

      "TITULO_SLIDE_PLANEJAMENTO" => "Planejamento da Captação #{next_capture_period.name}",

      "N_PAGOS" => "#{format_precision(total_paid)}",


      "CAPTADOS_TOTAL" => "#{format_precision(total_paid)}",

      "MENSALIDADE_MEDIA_TOTAL" => "R$ #{format_precision(full_data["offered_medio"])}",
      "DESCONTO_MEDIO_TOTAL" => "#{format_percent_spaced(full_data["desconto_medio"])}",

      "N_REEMBOLSOS" => "#{format_precision(reembolsos)}",
      "N_BOS" => "#{format_precision(bos)}",

      "BOS_P_PERIOD" => "#{format_precision(bos_anterior)}",
      "REEMB_P_PERIOD" => "#{format_precision(reembolsos_anterior)}",

      "VARIACAO_BOS" => %{ type: :text, color: bo_var_color, value: bo_var },
      "VARIACAO_REEMBOLSOS" => %{ type: :text, color: refund_var_color, value: refund_var },


      "GRAFICO_RANKEAMENTO" => visits_chart,
      "GRAFICO_RANKEAMENTO_PEQUENO" => visits_chart_small,

      "GRAFICO_SUCESSO" => success_chart,



      "PAGOS_PREV_TOTAL" => "#{format_precision(previous_semester_full_data["all_follow_ups"])}",
      "SKUS_PREV_TOTAL" => "#{format_precision(previous_semester_full_data["n_skus"])}",
      "TICKET_PREV_TOTAL" => (if is_nil(previous_semester_full_data["offered_medio"]), do: "", else: "R$     #{format_precision(previous_semester_full_data["offered_medio"])}"),

    } |> Map.merge(ead_stock_map)
      |> Map.merge(presential_stock_map)
      |> Map.merge(stock_report_ead)
      |> Map.merge(stock_report_presential)
      |> Map.merge(map_adicionalidade)
      |> Map.merge(%{
        "#DELETE_SLIDE_19" => %{ type: :delete_slide, slide_index: 18 },  # projecao de captacao
        "#DELETE_SLIDE_22" => %{ type: :delete_slide, slide_index: 21 },  # matricula antecipada
        "#DELETE_SLIDE_23" => %{ type: :delete_slide, slide_index: 22 },  # QUERO CAPTACAO
        "#DELETE_SLIDE_24" => %{ type: :delete_slide, slide_index: 23 }   # QUERO CAPTACAO
      })

    output = generate_presentation(analysis_map, "template_final_2019_2.pptx")

    Logger.info "output: #{output}"

    output_map = Poison.decode!(output)
    Logger.info "output_map: #{inspect output_map}"

    if output_map["sucess"] do
      Ppa.Endpoint.broadcast(topic, "analysisData", %{ filename: output_map["filename"], download_name: base_info.name })
    else
      Ppa.Endpoint.broadcast(topic, "analysisError", %{})
    end

    final_time = :os.system_time(:milli_seconds)
    Logger.info "SemesterEnd::execute_2019_2# Broadcasted #{final_time - start_time} ms"
  end

  def execute_2019_1(params, topic) do
    admin_user_id = params["admin_id"]
    capture_period_id = params["capture_period"]

    kinds_filter = params["kinds"]
    levels_filter = params["levels"]

    kinds_ids_filter = map_ids(kinds_filter)
    levels_ids_filter = map_ids(levels_filter)

    Logger.info "FILTERS: kinds: #{inspect kinds_filter} levels: #{inspect levels_filter}"

    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    Logger.info "initial_date: #{inspect initial_date} final_date: #{inspect final_date}"

    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)

    next_capture_period = Ppa.CapturePeriod.next_capture_period(capture_period)
    previous_capture_period = Ppa.CapturePeriod.previous_capture_period(capture_period)
    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)

    # datas divergem do periodo de captura atual?
    Logger.info "initial_date: #{inspect initial_date} final_date: #{inspect final_date}"

    {
      capture_period,
      previous_capture_period,
      previous_year_capture_period,
      custom_dates
     } = if not (to_iso_date_format(initial_date) == to_iso_date_format(capture_period.start) && to_iso_date_format(final_date) == to_iso_date_format(capture_period.end)) do
      Logger.info "DATAS DIVERGEM"
      # colocar nos capture_period as datas ajustadas
      capture_period = capture_period
        |> Map.put(:start, initial_date)
        |> Map.put(:end, final_date)

      # qual eh o tamanho do periodo?

      days_diff = Kernel.trunc(Timex.diff(final_date, initial_date) / 86400)

      previous_capture_period = previous_capture_period
        |> Map.put(:start, Timex.shift(initial_date, days: -days_diff))
        |> Map.put(:end, Timex.shift(initial_date, days: -1))

      previous_year_capture_period = previous_year_capture_period
        |> Map.put(:start, Timex.shift(initial_date, years: -1))
        |> Map.put(:end, Timex.shift(final_date, years: -1))

      { capture_period, previous_capture_period, previous_year_capture_period, true }
    else
      { capture_period, previous_capture_period, previous_year_capture_period, false }
    end

    # quando as datas nao estao iguais ao capture period, precisa ajustar
    # mas as datas sao usadas dentro dos Ppa.CapturePeriod

    { admin_name, adjusted_email } = get_admin_info(admin_user_id)

    # formato pode ser usado pelo PanelHandler.parse_filters
    base_filter = Enum.at(params["baseFilters"], 0)
    ies_info = if base_filter["type"] == "university" do
      university_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.University, university_id)
    else
      group_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.EducationGroup, group_id)
    end

    university_ids = parse_ies_filter(params)

    # LEADS
    { p_fieis, p_indecisos } = lookup_leads(university_ids, capture_period, kinds_ids_filter, levels_ids_filter, capture_period.start, capture_period.end)
    Logger.info "p_fieis: #{p_fieis} p_indecisos: #{p_indecisos}"

    ### TABELA CAPTADOS / RECEITA
    full_data = product_line_data(params, capture_period, levels_filter, kinds_filter)

    {
      grad_pres_data,
      grad_ead_data,
      full_grad_data,
      full_grad_data_year_ago,
      full_grad_data_previous,
      grad_projection
    } = data_for_level(@level_id_graduacao, params, capture_period, previous_year_capture_period, next_capture_period, previous_capture_period)

    {
      pos_pres_data,
      pos_ead_data,
      full_pos_data,
      full_pos_data_year_ago,
      full_pos_data_previous,
      pos_projection
    } = data_for_level(@level_id_pos_graduacao, params, capture_period, previous_year_capture_period, next_capture_period, previous_capture_period)

    other_levels_query = from l in Ppa.Level,
      where: fragment("? is null ", l.parent_id) and l.id not in ^[@level_id_graduacao, @level_id_pos_graduacao],
      select: %{ "id" => l.id }

    other_levels = Ppa.RepoPpa.all(other_levels_query)

    Logger.info "other_levels: #{inspect other_levels}"

    {
      others_pres_data,
      others_ead_data,
      full_others_data,
      _full_others_data_year_ago,
      _full_others_data_previous,
      _others_projection
    } = data_for_levels(Enum.map(other_levels, &(&1["id"])), params, capture_period, previous_year_capture_period, next_capture_period, previous_capture_period)

    total_paid = full_data["all_follow_ups"]

    grad_pres_paid = Decimal.add(grad_pres_data["exchanged_follow_ups"], grad_pres_data["paid_follow_ups"])
    grad_ead_paid = Decimal.add(grad_ead_data["exchanged_follow_ups"], grad_ead_data["paid_follow_ups"])

    pos_pres_paid = Decimal.add(pos_pres_data["exchanged_follow_ups"], pos_pres_data["paid_follow_ups"])
    pos_ead_paid = Decimal.add(pos_ead_data["exchanged_follow_ups"], pos_ead_data["paid_follow_ups"])

    others_pres_paid = Decimal.add(others_pres_data["exchanged_follow_ups"], others_pres_data["paid_follow_ups"])
    others_ead_paid = Decimal.add(others_ead_data["exchanged_follow_ups"], others_ead_data["paid_follow_ups"])

    # GRAFICOS DE CAPTADOS
    any_grad = ( Decimal.cmp(grad_pres_paid, 0) == :gt or Decimal.cmp(grad_ead_paid, 0) == :gt )
    any_pos = ( Decimal.cmp(pos_pres_paid, 0) == :gt or Decimal.cmp(pos_ead_paid, 0) == :gt )
    any_other = ( Decimal.cmp(others_pres_paid, 0) == :gt or Decimal.cmp(others_ead_paid, 0) == :gt )

    grad_paid_full = Decimal.add(grad_pres_paid, grad_ead_paid)
    pos_paid_full = Decimal.add(pos_pres_paid, pos_ead_paid)
    grad_e_pos_full = Decimal.add(grad_paid_full, pos_paid_full)
    paid_full = Decimal.add(grad_e_pos_full, full_others_data["all_follow_ups"])
    Logger.info "paid_full: #{paid_full} total_paid: #{total_paid} CMP: #{Decimal.cmp(paid_full, total_paid)}"

    if Decimal.cmp(paid_full, total_paid) != :eq do
      # manda erro para a tela!
      Ppa.Endpoint.broadcast(topic, "analysisError", %{})
    else
      Logger.info "any_grad: #{any_grad} any_pos: #{any_pos} any_other: #{any_other}"

      pres_label = cond do
        kinds_ids_filter == [] ->
          "Presencial"
        Enum.member?(kinds_ids_filter, "#{@kind_id_presencial}") ->
          "Presencial"
        true ->
          nil
      end

      ead_label = cond do
        kinds_ids_filter == [] ->
          Logger.info "ead_label# SEM FILTRO"
          "EaD + Semi"
        Enum.member?(kinds_ids_filter, "#{@kind_id_ead}") && Enum.member?(kinds_ids_filter, "#{@kind_id_semi_presencial}") ->
          Logger.info "ead_label# Contem os dois"
          "EaD + Semi"
        Enum.member?(kinds_ids_filter, "#{@kind_id_ead}") ->
          Logger.info "ead_label# Contem EAD"
          "EaD"
        Enum.member?(kinds_ids_filter, "#{@kind_id_semi_presencial}") ->
          Logger.info "ead_label# Contem SEMI"
          "Semipresencial"
        true ->
          nil
      end

      label_modalidade_outros = cond do
        kinds_ids_filter == [] ->
          "EaD + Presencial"
        Enum.member?(kinds_ids_filter, "#{@kind_id_ead}") && Enum.member?(kinds_ids_filter, "#{@kind_id_semi_presencial}")  && Enum.member?(kinds_ids_filter, "#{@kind_id_presencial}") ->
          Logger.info "ead_label# Contem os tre"
          "EaD + Presencial"
        Enum.member?(kinds_ids_filter, "#{@kind_id_ead}") && Enum.member?(kinds_ids_filter, "#{@kind_id_semi_presencial}") ->
          Logger.info "ead_label# Contem os dois"
          "EaD + Semi"
        Enum.member?(kinds_ids_filter, "#{@kind_id_ead}") && Enum.member?(kinds_ids_filter, "#{@kind_id_presencial}") ->
          "EaD + Presencial"
        Enum.member?(kinds_ids_filter, "#{@kind_id_presencial}") && Enum.member?(kinds_ids_filter, "#{@kind_id_semi_presencial}") ->
          "Semi + Presencial"
        Enum.member?(kinds_ids_filter, "#{@kind_id_ead}") ->
          Logger.info "ead_label# Contem EAD"
          "EaD"
        Enum.member?(kinds_ids_filter, "#{@kind_id_semi_presencial}") ->
          Logger.info "ead_label# Contem SEMI"
          "Semipresencial"
        Enum.member?(kinds_ids_filter, "#{@kind_id_presencial}") ->
          Logger.info "ead_label# Contem PRES"
          "Presencial"
        true ->
          nil
      end

      Logger.info "pres_label: #{pres_label} ead_label: #{ead_label} label_modalidade_outros: #{label_modalidade_outros}"

      # se tem o outro de alguma forma, precisa mostrar o grafico de outros
      { chart_1_3,
        chart_2_3,
        chart_3_3,
        chart_1_2,
        chart_2_2,
        chart_1_1 } = if any_other do
        cond do
          any_grad && any_pos -> {
            grad_chart(grad_ead_paid, grad_pres_paid, ead_label, pres_label, 300),
            pos_chart(pos_ead_paid, pos_pres_paid, ead_label, pres_label, 300),
            other_chart(others_ead_paid, others_pres_paid, ead_label, pres_label, 300),
            "", "", ""
          }

          any_grad -> {
            "", "", "",
            grad_chart(grad_ead_paid, grad_pres_paid, ead_label, pres_label, 350),
            other_chart(others_ead_paid, others_pres_paid, ead_label, pres_label, 350),
            ""
          }

          any_pos -> {
            "", "", "",
            pos_chart(pos_ead_paid, pos_pres_paid, ead_label, pres_label, 350),
            other_chart(others_ead_paid, others_pres_paid, ead_label, pres_label, 350),
            ""
          }

          true -> {
            "", "", "", "", "",
            other_chart(others_ead_paid, others_pres_paid, ead_label, pres_label, 400),
          }
        end
      else
        # nao tem nenhum outro, tem que decidir mostrar 1 ou 2 graficos
        # nao posso misturar graduacao e pos
        cond do
          any_grad && any_pos -> {
            "", "", "",
            grad_chart(grad_ead_paid, grad_pres_paid, ead_label, pres_label, 350),
            pos_chart(pos_ead_paid, pos_pres_paid, ead_label, pres_label, 350),
            ""
          }
          any_grad -> {
            "", "", "", "", "",
            grad_chart(grad_ead_paid, grad_pres_paid, ead_label, pres_label, 400)
          }
          any_pos -> {
            "", "", "", "", "",
            pos_chart(pos_ead_paid, pos_pres_paid, ead_label, pres_label, 400)
          }
          true ->  { "", "", "", "", "", "" }
        end
      end

      # SAZONALIDADE
      previous_previous_semester = Ppa.CapturePeriod.simple_name(previous_capture_period)
      previous_semester = Ppa.CapturePeriod.simple_name(capture_period)
      next_semester = Ppa.CapturePeriod.simple_name(next_capture_period)

      query_sazonalidade = query_sazonalidade(next_capture_period.id)

      { :ok, resultset_sazonalidade } = Ppa.RepoPpa.query(query_sazonalidade)
      resultset_sazonalidade_map = if resultset_sazonalidade.num_rows == 0 do
        query_sazonalidade = query_sazonalidade(previous_capture_period.id)
        { :ok, resultset_sazonalidade } = Ppa.RepoPpa.query(query_sazonalidade)
        Ppa.Util.Query.resultset_to_map(resultset_sazonalidade)
      else
        Ppa.Util.Query.resultset_to_map(resultset_sazonalidade)
      end

      sazonalidade = Enum.map(resultset_sazonalidade_map, &(&1["daily_contribution"]))
      datas_sazonalidade = Enum.map(resultset_sazonalidade_map, &(format_local(&1["date"])))
      starting_month = next_capture_period.start.month - 1

      year_ago_semester = Ppa.CapturePeriod.simple_name(previous_year_capture_period)
      year_ago_data = product_line_data(params, previous_year_capture_period, levels_filter, kinds_filter)

      ## FUNIL
      atratividade_atual = divide_rate(full_data["initiated_orders"], full_data["visits"])
      sucesso_atual = divide_rate(full_data["all_follow_ups"], full_data["initiated_orders"])
      conversao_atual = divide_rate(full_data["all_follow_ups"], full_data["visits"])
      # reembolso_atual = divide_rate(Decimal.add(full_data["exchanged_follow_ups"], full_data["refunded_follow_ups"]), full_data["all_follow_ups"])
      reembolso_atual = divide_rate(Decimal.add(full_data["exchanged_follow_ups"], full_data["refunds"]), full_data["all_follow_ups"])

      Logger.info "conversao_atual: #{inspect conversao_atual}"

      ## CORES PARA O FUNIL
      cor_conversao = if is_nil(conversao_atual) do
        :red
      else
        if Decimal.cmp(conversao_atual, Decimal.from_float(@referencia_taxa_conversao)) == :gt do
          :green
        else
          :red
        end
      end

      cor_atratividade = if is_nil(atratividade_atual) do
        :red
      else
        if Decimal.cmp(atratividade_atual, Decimal.from_float(@referencia_taxa_atratividade)) == :gt do
          :green
        else
          :red
        end
      end

      # se nao tem taxa de sucesso vai fazer o que?
      cor_sucesso = if is_nil(sucesso_atual) do
        :black
      else
        if Decimal.cmp(sucesso_atual, Decimal.from_float(@referencia_taxa_sucesso)) == :gt do
          :green
        else
          :red
        end
      end

      cor_reembolso = "#C00000" # TODO - pode mudar?

      Logger.info "atratividade_atual: #{atratividade_atual} @referencia_taxa_atratividade: #{@referencia_taxa_atratividade} reembolso_atual: #{reembolso_atual}"
      Logger.info "year_ago_data: #{inspect year_ago_data} full_data: #{inspect full_data}"

      # ANALISE POTENCIAL

      potencial_grad = if Decimal.cmp(full_grad_data["all_follow_ups"], 0) == :eq do
        %{
          "#DELETE_SLIDE_8" => %{ type: :delete_slide, slide_index: 7 }, # zero based
        }
      else
        potencial_map(year_ago_semester, previous_semester, "Graduação", full_grad_data, full_grad_data_year_ago)
      end

      potencial_pos = if Decimal.cmp(full_pos_data["all_follow_ups"], 0) == :eq do
        %{
          "#DELETE_SLIDE_9" => %{ type: :delete_slide, slide_index: 8 }, # zero based
        }
      else
        potencial_map(year_ago_semester, previous_semester, "Pós", full_pos_data, full_pos_data_year_ago, "_2")
      end



      map_sazonalidade = if custom_dates do
        %{ "#DELETE_SLIDE_16" => %{ type: :delete_slide, slide_index: 15 } }
      else
        %{
          "S_MES_1" => Enum.at(Ppa.Util.Timex.months_names, starting_month),
          "S_MES_2" => Enum.at(Ppa.Util.Timex.months_names, starting_month + 1),
          "S_MES_3" => Enum.at(Ppa.Util.Timex.months_names, starting_month + 2),
          "S_MES_4" => Enum.at(Ppa.Util.Timex.months_names, rem(starting_month + 3, 12)),
          "S_MES_5" => Enum.at(Ppa.Util.Timex.months_names, rem(starting_month + 4, 12)),
          "S_MES_6" => Enum.at(Ppa.Util.Timex.months_names, rem(starting_month + 5, 12)),
          "GRAFICO_SAZONALIDADE" => %{
            type: :chart,
            properties: %{
              type: :line,
              colors: ["#ffc400" ],
              series: [ sazonalidade ],
              labels: datas_sazonalidade,
              draw_values: false,
              draw_percentages: false,
              canvas_width: 800,
              canvas_height: 200,
              hide_legend: true,
              hide_x_axis: true,
              hide_y_axis: true,
              hide_x_axis_grid: true,
              hide_y_axis_grid: true,
              hide_x_axis_border: true,
              hide_y_axis_border: true,
            }, width: 800, height: 200
          }
        }
      end

      ead_label = if is_nil(ead_label), do: "EaD", else: ead_label
      analysis_map = %{
        "IES_NAME_SEMESTER" => "#{ies_info.name} - #{previous_semester}",
        "LABEL_MODALIDADE_EAD" => ead_label,
        "LABEL_MODALIDADE_OUTROS" => label_modalidade_outros,
        "IES_NAME" => ies_info.name,
        "MONTH_YEAR" => "#{Enum.at(Ppa.Util.Timex.months_names, Timex.today.month - 1)} - #{Timex.today.year}",
        "USER_NAME" => admin_name,
        "USER_EMAIL" => adjusted_email,

        "ASSUNTOS_1" => "Resultados #{previous_semester}",
        "ASSUNTOS_2" => "Análise semestre #{previous_semester}",
        "ASSUNTOS_3" => "Planejamento #{next_semester}",
        "TITULO_CAPTADOS" => "Captados #{previous_semester}",
        "TITULO_SAZONALIDADE" => "Sazonalidade QB #{next_semester}",

        "N_CAPTADOS_GRADUACAO_PRESENCIAL" => "#{format_precision(grad_pres_paid)}",
        "N_CAPTADOS_GRADUACAO_EAD" => "#{format_precision(grad_ead_paid)}",
        "N_CAPTADOS_POS_PRESENCIAL" => "#{format_precision(pos_pres_paid)}",
        "N_CAPTADOS_POS_EAD" => "#{format_precision(pos_ead_paid)}",
        "N_CAPTADOS_OUTROS_EAD" => "#{format_precision(full_others_data["all_follow_ups"])}",
        "N_CAPTADOS_TOTAL" => "#{format_precision(total_paid)}",

        "MENSALIDADE_GRADUACAO_PRESENCIAL" => "#{format_precision(grad_pres_data["offered_medio"], 2)}",
        "MENSALIDADE_GRADUACAO_EAD" => "#{format_precision(grad_ead_data["offered_medio"], 2)}",
        "MENSALIDADE_POS_PRESENCIAL" => "#{format_precision(pos_pres_data["offered_medio"], 2)}",
        "MENSALIDADE_POS_EAD" => "#{format_precision(pos_ead_data["offered_medio"], 2)}",
        "MENSALIDADE_OUTROS_EAD" => "#{format_precision(full_others_data["offered_medio"], 2)}",

        "DESCONTO_GRADUACAO_PRESENCIAL" => "#{format_percent_spaced(grad_pres_data["desconto_medio"])}",
        "DESCONTO_GRADUACAO_EAD" => "#{format_percent_spaced(grad_ead_data["desconto_medio"])}",
        "DESCONTO_POS_PRESENCIAL" => "#{format_percent_spaced(pos_pres_data["desconto_medio"])}",
        "DESCONTO_POS_EAD" => "#{format_percent_spaced(pos_ead_data["desconto_medio"])}",
        "DESCONTO_OUTROS_EAD" => "#{format_percent_spaced(full_others_data["desconto_medio"])}",

        "RECEITA_GRADUACAO_PRESENCIAL" => "#{Number.Delimit.number_to_delimited(grad_pres_data["receita"])}",
        "RECEITA_GRADUACAO_EAD" => "#{Number.Delimit.number_to_delimited(grad_ead_data["receita"])}",
        "RECEITA_POS_PRESENCIAL" => "#{Number.Delimit.number_to_delimited(pos_pres_data["receita"])}",
        "RECEITA_POS_EAD" => "#{Number.Delimit.number_to_delimited(pos_ead_data["receita"])}",
        "RECEITA_OUTROS_EAD" => "#{Number.Delimit.number_to_delimited(full_others_data["receita"])}",

        "RECEITA_TOTAL" => "#{Number.Delimit.number_to_delimited(full_data["receita"])}",

        "LINHA_CAPTADOS" => "Captados #{previous_semester}",
        "LINHA_PROJECAO" => "Projecao #{next_semester}",
        "LINHA_PROJECAO_QAP" => "Projecao #{next_semester} QAP",


        "P_SEM" => previous_semester,
        "N_SEM" => next_semester,
        "T_ATRATIVIDADE" => %{ type: :text, color: cor_atratividade, value: format_percent_spaced(format_precision(atratividade_atual, 2)) },
        "T_SUCESSO" => %{ type: :text, color: cor_sucesso, value: format_percent_spaced(format_precision(sucesso_atual, 2)) },
        "T_REEMBOLSO" => %{ type: :text, color: cor_reembolso, value: format_percent_spaced(format_precision(reembolso_atual, 2)) },
        "T_CONVERSAO" => %{ type: :text, color: cor_conversao, value: format_percent_spaced(format_precision(conversao_atual, 2)) },
        "N_VISITAS" => "#{format_precision(full_data["visits"])}",
        "N_ORDENS" => "#{format_precision(full_data["initiated_orders"])}",
        "N_PAGOS" => "#{format_precision(full_data["all_follow_ups"])}",
        "T_INDECISOS" => "#{format_precision(p_indecisos)} %",
        "T_FIEIS" => "#{format_precision(p_fieis)} %",


        "GRAFICO_CAPTADOS_1_DE_3" => chart_1_3,
        "GRAFICO_CAPTADOS_2_DE_3" => chart_2_3,
        "GRAFICO_CAPTADOS_3_DE_3" => chart_3_3,
        "GRAFICO_CAPTADOS_1_DE_2" => chart_1_2,
        "GRAFICO_CAPTADOS_2_DE_2" => chart_2_2,
        "GRAFICO_CAPTADOS_1_DE_1" => chart_1_1,
      }

      { projecao_graduacao_map, projecao_pos_map} = if custom_dates do
        {
          %{ "#DELETE_SLIDE_13" => %{ type: :delete_slide, slide_index: 12 } },
          %{ "#DELETE_SLIDE_14" => %{ type: :delete_slide, slide_index: 13 } }
        }
      else

        projecao_graduacao_map = projection_map(
          full_grad_data,
          full_grad_data_previous,
          grad_projection,
          13,
          "_G",
          previous_previous_semester,
          previous_semester,
          next_semester)

        projecao_pos_map = projection_map(
          full_pos_data,
          full_pos_data_previous,
          pos_projection,
          14,
          "_P",
          previous_previous_semester,
          previous_semester,
          next_semester)

        { projecao_graduacao_map, projecao_pos_map}
      end

      analysis_map = Map.merge(analysis_map, potencial_grad)
        |> Map.merge(potencial_pos)
        |> Map.merge(projecao_graduacao_map)
        |> Map.merge(projecao_pos_map)
        |> Map.merge(map_sazonalidade)
        # REMOVE OS SLIDES DA MATRICULA ANTECIPADA
        |> Map.merge(%{
          "#DELETE_SLIDE_17" => %{ type: :delete_slide, slide_index: 16 },
          "#DELETE_SLIDE_18" => %{ type: :delete_slide, slide_index: 17 },
          "#DELETE_SLIDE_19" => %{ type: :delete_slide, slide_index: 18 },
        })

      output = generate_presentation(analysis_map, "template_apresentacao_resultados.pptx")

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
end

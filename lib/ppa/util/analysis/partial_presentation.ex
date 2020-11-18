defmodule Ppa.Util.Analisys.PartialPresentation do
  import Ppa.Util.Analisys.Base
  import Ppa.Util.Timex
  import Ppa.Util.Sql
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Math
  require Logger

  @referencia_taxa_atratividade 16
  @referencia_taxa_sucesso 10
  @referencia_taxa_conversao 1.6

  def execute(params, topic) do
    Logger.info "Analisys.PartialPresentation.execute# params: #{inspect params}"

    initial_date = load_date_field(params, "initialDate")
    final_date = load_date_field(params, "finalDate")

    admin_user_id = params["admin_id"]
    capture_period_id = params["capture_period"]
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)

    previous_year_capture_period = Ppa.CapturePeriod.previous_year_capture_period(capture_period)

    # estamos considerando apenas a data inicial neste caso!
    { compare_initial_date, compare_final_date, custom_period } = if not (to_iso_date_format(initial_date) == to_iso_date_format(capture_period.start)) do
      # && to_iso_date_format(final_date) == to_iso_date_format(capture_period.end))
      Logger.info "PartialPresentation::execute# DATAS DIVERGEM"
      { initial_date, final_date, true } # -> vai so ate a data final mesmo? tem que deslocar algo?
    else
      Logger.info "PartialPresentation::execute# DATAS IGUAIS"
      { capture_period.start, capture_period.end, false }
    end

    kinds_filter = params["kinds"]
    levels_filter = params["levels"]

    kinds_ids = map_ids(kinds_filter)
    levels_ids = map_ids(levels_filter)

    { admin_name, adjusted_email } = Ppa.Util.Analisys.SemesterEnd.get_admin_info(admin_user_id)

    # TODO - nao tem como suportar grupo no fluxo de concorrencia!
      # pq tem essa selecao de grupo?
    base_filter = Enum.at(params["baseFilters"], 0)
    ies_info = if base_filter["type"] == "university" do
      university_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.University, university_id)
    else
      group_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.EducationGroup, group_id)
    end

    projection_data = if custom_period do
      %{
        "#DELETE_SLIDE_9" => %{ type: :delete_slide, slide_index: 8 }, # zero based
      }
    else
      projection_data(params, kinds_filter, levels_filter, capture_period)
    end

    Logger.info "projection_data: #{inspect projection_data}"

    # GRAFICOS ( visitas, ordens, pagos) ( kinds e levels no param - OK)
    # filter_params = params
    #   |> Map.put("finalDate", capture_period.end)
    #   |> Map.put("initialDate", capture_period.start)

    # quando coloca uma data final -> vai fazer o comparativo so ate aquela data?
      # a ideia era fazer inicio da captacao ate agora, mas pegar um grafico que encaixa com o periodo de comparacao do ano passado

    filter_params = params
      |> Map.put("finalDate", compare_final_date)
      |> Map.put("initialDate", compare_initial_date)

    current_semester_data = Ppa.PanelHandler.execute_filter(capture_period.id, filter_params, "{0D}/{0M}")

    # previous_year_filter_params = params
    #   |> Map.put("finalDate", previous_year_capture_period.end)
    #   |> Map.put("initialDate", previous_year_capture_period.start)

    previous_year_filter_params = params
      |> Map.put("finalDate", compare_final_date |> Timex.shift(years: -1))
      |> Map.put("initialDate", compare_initial_date |> Timex.shift(years: -1))

    previous_year_semester_data = Ppa.PanelHandler.execute_filter(previous_year_capture_period.id, previous_year_filter_params, "{0D}/{0M}")

    #########

    ### STOCK
    # vendas das ofertas ativas no momento!
    report = stock_report_ex(params, levels_ids, kinds_ids)
    Logger.info "report: #{inspect report}"


    stock_report_map = if is_nil(report) do
      Logger.info "SEM REPORT"
      %{}
    else
      saleable = report["base_saleable"]
      unsold = report["base_unsold"]
      if is_nil(saleable) or is_nil(unsold) do
        %{
          "#DELETE_SLIDE_2" => %{ type: :delete_slide, slide_index: 1 }, # zero based
        }
      else
        total = Decimal.add(saleable, unsold)
        Logger.info "total: #{total} unsold: #{inspect unsold} saleable: #{inspect saleable}"
        # saleable_percent = divide_rate(saleable, total)
        # unsold_percent = divide_rate(unsold, total)
        %{
          "GRAFICO_ESTOQUE" => %{
            type: :chart,
            properties: %{
              type: :pie,
              colors: ["#35b6cc", "#fdc029"],
              data: [Decimal.to_integer(saleable), Decimal.to_integer(unsold)],
              labels: ["Com vendas", "Encalhados"],
              # hide_legend: false,
              # draw_values: true,
              draw_percentages: true,
              draw_values_font_size: 28,
              draw_values_locale: "pt-BR",
              hide_x_axis_grid: true,
              hide_y_axis_grid: true,
              x_axis_begin_at_zero: true,
              x_axis_stacked: true,
              y_axis_stacked: true,
            }, width: 830, height: 330
          },
          "LABEL_ESTOQUE" => "#{ies_info.name} tem #{total} ofertas no ar, das quais #{unsold} estão sem vendas"
        }
      end
    end

    ####

    ### VENDAS POR DESCONTO
    per_discount_map = sell_per_discount(params, kinds_ids, levels_ids, compare_initial_date, compare_final_date)
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
    discount_result = List.first(discount_mean_ex(params, levels_ids, kinds_ids))

    media_desconto_ofertas = if is_nil(discount_result) do
      ""
    else
      "#{format_precision(discount_result["avg_discount"], 2)}%"
    end

    Logger.info "discounts_values: #{inspect discounts_values} discounts_values_sum: #{inspect discounts_values_sum} max_pair: #{inspect max_pair}"
    ####

    ### FLUXO DE CONCORRENCIA
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
        Map.put(competitors_filters, "levels", levels_filter)
      end

      IO.inspect params, label: "PARAMS!"
      IO.inspect competitors_filters, label: "COMPETITORS FILTERS!!!  "

      competitors_flow_map = Ppa.CompetitorsHandler.retrieve_competitors_data(competitors_filters)
      Logger.info "competitors_flow_map: #{inspect competitors_flow_map}"


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
            x_axis_font_size: 16,
            y_axis_font_size: 16,
            x_auto_skip: false,
            x_axis_font_color: "#000000",
            y_axis_font_color: "#000000",
          }, width: 850, height: 340
        },

        "SUBTITULO_FLUXO_CONCORRENCIA" => "Alunos perdidos para cada IES (número de alunos que se interessaram pela #{ies_info.name}, mas comprou outra IES)",
      }
    else
      %{
        "#DELETE_SLIDE_8" => %{ type: :delete_slide, slide_index: 7 }, # zero based
      }
    end
    #####

    ### FUNIL
    university_ids = Ppa.Util.Analisys.SemesterEnd.parse_ies_filter(params)
    { p_fieis, p_indecisos } = Ppa.Util.Analisys.SemesterEnd.lookup_leads(university_ids, capture_period, kinds_ids, levels_ids, compare_initial_date, compare_final_date)

    # full_data = Ppa.Util.Analisys.SemesterEnd.product_line_data(params, capture_period, levels_filter, kinds_filter)
    full_data = Ppa.Util.Analisys.SemesterEnd.product_line_data_by_period(params, capture_period, compare_initial_date, compare_final_date, levels_filter, kinds_filter)
    Logger.info "full_data: #{inspect full_data}"

    base_date = Timex.shift(Timex.today, days: -1)
    compare_end = base_date |> Timex.shift(years: -1)
    previous_year_comparing_data = Ppa.Util.Analisys.SemesterEnd.product_line_data_by_period(params, previous_year_capture_period, previous_year_capture_period.start, compare_end, levels_filter, kinds_filter)

    Logger.info ""

    variacao_visitas = if is_nil(previous_year_comparing_data["visits"]) or is_nil(full_data["visits"]) do
      if not is_nil(full_data["visits"]) and is_nil(previous_year_comparing_data["visits"]) do
        "acima"
      else
        ""
      end
    else
      if Decimal.cmp(full_data["visits"], previous_year_comparing_data["visits"]) == :gt do
        "acima"
      else
        "abaixo"
      end
    end

    variacao_ordens = if Decimal.cmp(full_data["initiated_orders"], previous_year_comparing_data["initiated_orders"]) == :gt do
      "acima"
    else
      "abaixo"
    end

    variacao_pagos = if Decimal.cmp(full_data["paid_follow_ups"], previous_year_comparing_data["paid_follow_ups"]) == :gt do
      "acima"
    else
      "abaixo"
    end

    atratividade_atual = divide_rate(full_data["initiated_orders"], full_data["visits"])
    sucesso_atual = divide_rate(full_data["all_follow_ups"], full_data["initiated_orders"])
    conversao_atual = divide_rate(full_data["all_follow_ups"], full_data["visits"])
    # reembolso_atual = divide_rate(Decimal.add(full_data["exchanged_follow_ups"], full_data["refunded_follow_ups"]), full_data["all_follow_ups"])
    reembolso_atual = divide_rate(Decimal.add(full_data["exchanged_follow_ups"], full_data["refunds"]), full_data["all_follow_ups"])

    ## CORES PARA O FUNIL
    cor_conversao = if is_nil(conversao_atual) do
      :red
    else
      if Decimal.cmp(conversao_atual, Decimal.from_float(@referencia_taxa_conversao)) == :gt do
        "#12BA12"
      else
        :red
      end
    end

    cor_atratividade = if is_nil(atratividade_atual) do
      :red
    else
      if Decimal.cmp(atratividade_atual, @referencia_taxa_atratividade) == :gt do
        "#12BA12"
      else
        :red
      end
    end

    # se nao tem taxa de sucesso vai fazer o que?
    cor_sucesso = if is_nil(sucesso_atual) do
      :black
    else
      if Decimal.cmp(sucesso_atual, @referencia_taxa_sucesso) == :gt do
        "#12BA12"
      else
        :red
      end
    end

    cor_reembolso = "#C00000" # TODO - pode mudar?
    ###################

    analysis_map = %{
      "INITIAL_TITLE" => "Resultados #{capture_period.name}",
      "SEMESTER" => capture_period.name,
      "PARTIAL_PERIOD" => "(Parcial até #{format_local(base_date)})",
      "IES_NAME" => ies_info.name,
      "IES_NAME_AND_PERIOD" => "#{ies_info.name} - (Parcial até #{format_local(base_date)})",
      "MONTH_YEAR" => "#{Enum.at(Ppa.Util.Timex.months_names, Timex.today.month - 1)} - #{Timex.today.year}",
      "USER_NAME" => admin_name,
      "USER_EMAIL" => adjusted_email,
      "PREVIOUS_YEAR_SEM" => "(#{previous_year_capture_period.name})",

      "T_ATRATIVIDADE" => %{ type: :text, color: cor_atratividade, value: format_percent(format_precision(atratividade_atual, 2)) },
      "T_SUCESSO" => %{ type: :text, color: cor_sucesso, value: format_percent(format_precision(sucesso_atual, 2)) },
      "T_REEMBOLSO" => %{ type: :text, color: cor_reembolso, value: format_percent(format_precision(reembolso_atual, 2)) },
      "T_CONVERSAO" => %{ type: :text, color: cor_conversao, value: format_percent(format_precision(conversao_atual, 2)) },
      "N_VISITAS" => "#{format_precision(full_data["visits"])}",
      "N_ORDENS" => "#{format_precision(full_data["initiated_orders"])}",
      "N_PAGOS" => "#{format_precision(full_data["all_follow_ups"])}",

      "T_INDECISOS" => "#{format_precision(p_indecisos)} %",
      "T_FIEIS" => "#{format_precision(p_fieis)} %",

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
        }, width: 830, height: 300
      },

      "LABEL_VENDAS_POR_DESCONTO" => "A faixa de desconto entre #{faixa_desconto} apresenta a maior quantidade de vendas. A média de desconto das ofertas ativas é de #{media_desconto_ofertas}",


      "GRAFICO_VISITAS" => %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#35b6cc", "#fdc029"],
          series: [ current_semester_data.visits, previous_year_semester_data.visits ],
          labels: current_semester_data.orders_dates,
          legend_labels: ["Ano Atual", "Ano Anterior"],
          x_axis_font_size: 20,
          x_axis_font_color: "#000000",
          y_axis_title: "Visitas",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          hide_y_axis: true,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          y_axis_title_color: "#49555B"
        }, width: 830, height: 330
      },

      "LABEL_VISITAS" => "#{ies_info.name} está com visitas #{variacao_visitas} do ano passado",

      "GRAFICO_PAGOS" => %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#35b6cc", "#fdc029"],
          series: [ current_semester_data.paids, previous_year_semester_data.paids ],
          labels: current_semester_data.orders_dates,
          legend_labels: ["Ano Atual", "Ano Anterior"],
          y_axis_title: "Pagos",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          x_axis_font_size: 20,
          x_axis_font_color: "#000000",
          hide_y_axis: true,
          hide_legend: false,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          y_axis_title_color: "#49555B"
        }, width: 830, height: 330
      },

      "LABEL_PAGOS" => "#{ies_info.name} está com número de alunos captados #{variacao_pagos} do ano passado",

      "GRAFICO_ORDENS" => %{
        type: :chart,
        properties: %{
          type: :line,
          colors: ["#35b6cc", "#fdc029"],
          series: [ current_semester_data.initiateds, previous_year_semester_data.initiateds ],
          labels: current_semester_data.orders_dates,
          legend_labels: ["Ano Atual", "Ano Anterior"],
          y_axis_title: "Ordens",
          y_axis_title_font_size: 25,
          x_axis_title_font_size: 25,
          x_axis_font_size: 20,
          x_axis_font_color: "#000000",
          hide_y_axis: true,
          hide_x_axis_grid: true,
          hide_y_axis_grid: true,
          y_axis_title_padding: 20,
          x_axis_title_padding: 20,
          y_axis_title_color: "#49555B"
        }, width: 830, height: 330
      },

      "LABEL_ORDENS" => "#{ies_info.name} está com número de boletos gerados #{variacao_ordens} do ano passado"
    } |> Map.merge(stock_report_map)
      |> Map.merge(projection_data)
      |> Map.merge(competitors_map)

    output = generate_presentation(analysis_map, "template_apresentacao_parcial.pptx")

    Logger.info "output: #{output}"

    output_map = Poison.decode!(output)
    Logger.info "output_map: #{inspect output_map}"

    if output_map["sucess"] do
      Ppa.Endpoint.broadcast(topic, "analysisData", %{ filename: output_map["filename"], download_name: ies_info.name })
    else
      Ppa.Endpoint.broadcast(topic, "analysisError", %{})
    end
  end

  def projection_data(params, kinds, levels, capture_period) do
    # total_projection = Ppa.Util.Analisys.SemesterEnd.product_line_projection(params, capture_period, levels, kinds)

    university_ids = Ppa.Util.Analisys.SemesterEnd.parse_ies_filter(params)

    kinds_where = and_if_not_empty(populate_field("kind_id", map_ids(kinds)))
    levels_where = and_if_not_empty(populate_field("level_id", map_ids(levels)))

    initial_date = to_iso_date_format(capture_period.start)
    final_date = to_iso_date_format(capture_period.end)

    product_lines = "SELECT    pl.id,
               array_agg(DISTINCT kind_id)     kinds,
               array_agg(DISTINCT level_id)    levels,
               count(DISTINCT udo.id)       AS relevance
     FROM      product_lines pl
     LEFT JOIN product_lines_levels pll
     ON        (
                         pll.product_line_id = pl.id)
     LEFT JOIN product_lines_kinds plk
     ON        (
                         plk.product_line_id = pl.id)
     LEFT JOIN university_deal_owners udo
     ON        (
                         udo.product_line_id = pl.id
               AND       end_date is NULL)
     GROUP BY  pl.id"

   kinds_where_projection = and_if_not_empty(populate_or_omit_field("kind_id", map_ids(kinds)))
   levels_where_projection = and_if_not_empty(populate_or_omit_field("level_id", map_ids(levels)))

   full_query = "
    select *, sum(case when date < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then total else projection_sum end) over (order by date) current_projection from (
      select
       projections.*,
       total,
       case when projections.date < date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, now()))) then
         sum(coalesce(total, 0)) over (order by projections.date)
       end as cum_total
      from (
      select *, sum(projection_sum) over  (order by date) as cum_projection_sum from (
      select date, sum(movel_projection) projection_sum from (
      select *, base_projection * dc.daily_contribution as movel_projection From (
      select sum(base_projection) as base_projection, product_line_id from (

        select
        distinct on (p.id)
          p.id,
          p.base_projection,
          product_lines.id as product_line_id,
          product_lines.relevance
        from
          -- students_projections_ex p
          parcerias.students_projections p
          left join (#{product_lines}) product_lines on (p.kind_id = any(kinds) and p.level_id = any(levels))
        WHERE
          active and
          university_id in (#{Enum.join(university_ids, ",")})
          AND capture_period_id = #{capture_period.id}
          #{kinds_where_projection}
          #{levels_where_projection}
        order by p.id, product_lines.relevance DESC

      ) as d group by product_line_id
      ) as projection_data
      left join daily_contributions dc on (dc.capture_period_id = 6 and dc.product_line_id = projection_data.product_line_id)
      ) as d group by date order by date
      ) as base_projections
      ) as projections left join (
        SELECT
           follow_up_created as date,
           paid_follow_ups + exchanged_follow_ups as total
         FROM   denormalized_views.consolidated_follow_ups
         WHERE  university_id in (#{Enum.join(university_ids, ",")})
                AND follow_up_created >= '#{initial_date}'
                AND follow_up_created <= '#{final_date}'
                #{kinds_where}
                #{levels_where}
                AND whitelabel_origin IS NULL
      ) fu_data on (fu_data.date = projections.date)
    ) as d"

    {:ok, resultset} = Ppa.RepoPpa.query(full_query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    cum_projection = Enum.map(resultset_map, &(&1["cum_projection_sum"]))
    current_projection = Enum.map(resultset_map, &(&1["current_projection"]))

    dates = Enum.map(resultset_map, &(format_local(&1["date"], "{0D}/{0M}")))
    cum_paids = Enum.map(resultset_map, &(&1["cum_total"]))

    if resultset_map == [] do
      %{
        "#DELETE_SLIDE_9" => %{ type: :delete_slide, slide_index: 8 }, # zero based
      }
    else
      [last] = Enum.take(resultset_map, -1)

      projecao_total_inicial = Decimal.round(last["cum_projection_sum"], 0)
      projecao_total_atual = Decimal.round(last["current_projection"], 0)

      %{
        "SUBTITULO_PROJECAO" => "No início do semestre a projeção de captação foi de #{projecao_total_inicial} alunos. Mantendo-se a performance atual, a projeção é de #{projecao_total_atual} alunos.",
        "GRAFICO_PROJECAO" => %{
         type: :chart,
         properties: %{
           type: :line,
           colors: ["#35b6cc", "#fdc029"],
           fill: [ nil, true, true],
           dashed: [ [10,5], nil, [10,5] ],
           series: [ cum_projection, cum_paids, current_projection ],
           labels: dates,
           legend_labels: ["Projeção inicial", "Vendas", "Projeção atual"],
           y_axis_title: "Alunos",
           y_axis_title_font_size: 25,
           x_axis_title_font_size: 25,
           x_axis_font_size: 20,
           x_axis_font_color: "#000000",
           y_axis_font_size: 20,
           y_axis_font_color: "#000000",
           hide_x_axis_grid: true,
           hide_y_axis_grid: true,
           y_axis_title_padding: 20,
           x_axis_title_padding: 20,
           y_axis_title_color: "#49555B"
          }, width: 830, height: 350
        }
      }
    end
  end

  def sell_per_discount(params, kinds, levels, initial_date, final_date) do
    ies_ids = solve_ies_ids(params)

    query = "
      SELECT Count(*),
             ceil(o.discount_percentage / 5) * 5 AS normalized_discount
      FROM   follow_ups fu
             INNER JOIN offers o
                     ON ( o.id = fu.offer_id )
             INNER JOIN courses c
                     ON ( c.id = o.course_id )
             INNER JOIN levels l
                     ON ( l.name = c.level and l.parent_id is not null )
             INNER JOIN kinds k
                     ON ( k.name = c.kind and k.parent_id is not null )
      WHERE  fu.university_id in (#{Enum.join(ies_ids, ",")})
             AND fu.created_at >= '#{to_iso_date_format(initial_date)}'
             AND fu.created_at <= '#{to_iso_date_format(final_date)}'
             #{and_if_not_empty(populate_or_omit_field("l.parent_id", levels))}
             #{and_if_not_empty(populate_or_omit_field("k.parent_id", kinds))}
      GROUP  BY normalized_discount; "

    {:ok, resultset} = Ppa.RepoPpa.query(query)

    IO.inspect query, label: "!!!! SELL PER DISCOUNT QUERY !!!!"

    Ppa.Util.Query.resultset_to_map(resultset)
  end

  def discount_mean(university_id, levels, kinds) do
    query = "
    select
      avg(avg_discount) as avg_discount
    from
      denormalized_views.consolidated_stock_means
    where
      university_id = #{university_id}
      #{and_if_not_empty(populate_or_omit_field("kind_id", kinds))}
      #{and_if_not_empty(populate_or_omit_field("level_id", levels))}"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    Ppa.Util.Query.resultset_to_map(resultset)
  end

  def solve_ies_ids(params) do
    base_filter = Enum.at(params["baseFilters"], 0)
    if base_filter["type"] == "university" do
      [ base_filter["value"]["id"] ]
    else
      group_id = base_filter["value"]["id"]
      group_ies(group_id)
    end
  end

  def discount_mean_ex(params, levels, kinds) do
    ids_ies = solve_ies_ids(params)

    query = "
    select
      avg(avg_discount) as avg_discount
    from
      denormalized_views.consolidated_stock_means
    where
      university_id in (#{Enum.join(ids_ies, ",")})
      #{and_if_not_empty(populate_or_omit_field("kind_id", kinds))}
      #{and_if_not_empty(populate_or_omit_field("level_id", levels))}"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    Ppa.Util.Query.resultset_to_map(resultset)
  end

  def stock_report(university_id, levels, kinds) do
    base_query =
      """
       SELECT
          parent_level_id,
          parent_kind_id,
          -- WINDOW
          count(case when offers."position" = 1 AND offers.paid_seats <= 0 AND (offers.reserved_seats < offers.total_seats OR offers.limited = false) THEN offer_id END) window_unsold,
          count(case when offers."position" = 1 AND offers.paid_seats > 0 AND ((offers.total_seats - offers.reserved_seats > 0) OR offers.limited = false)
                          THEN offer_id END) window_saleable,
          count(case when offers."position" = 1 AND offers.reserved_seats >= offers.total_seats AND offers.limited THEN offer_id END) window_soldout,

          -- BASE
          count(case when (offers."position" <> 1 OR offers."position" IS NULL) AND offers.paid_seats <= 0 AND (offers.reserved_seats < offers.total_seats OR offers.limited = false) THEN offer_id END) base_unsold,
          count(case when (offers."position" <> 1 OR offers."position" IS NULL) AND offers.paid_seats > 0 AND ((offers.total_seats - offers.reserved_seats) > 0 OR offers.limited = false)
                          THEN offer_id END) base_saleable,
          count(case when (offers."position" <> 1 OR offers."position" IS NULL) AND offers.reserved_seats >= offers.total_seats AND offers.limited THEN offer_id END) base_soldout
        FROM (
          SELECT
            offer.id                                offer_id,
            level.parent_id                         parent_level_id,
            kind.parent_id                          parent_kind_id,
            seats_balance.saleable_seats            saleable_seats,
            seats_balance.reserved_seats            reserved_seats,
            seats_balance.total_seats               total_seats,
            seats_balance.limited                   limited,
            offer."position"                          "position",
            coalesce(sum(seats_transactions.paid_seats_delta), 0) paid_seats
          FROM offers offer
            join courses course on course.id = offer.course_id
            join levels level on level.name = course.level and level.parent_id is not null
            join kinds kind on kind.name = course.kind and kind.parent_id is not null
            join seats_balances seats_balance on seats_balance.id = offer.seats_balance_id
            left join seats_transactions on offer_id = offer.id
          WHERE offer.enabled is true AND offer.restricted is false AND offer.university_id = #{university_id}
          GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
        ) as offers
        GROUP BY
          parent_kind_id,
          parent_level_id
      """

      query = "select
        sum(base_unsold) as base_unsold,
        sum(base_saleable) as base_saleable
      from (#{base_query}) as stock_data
      where
        true
        #{and_if_not_empty(populate_or_omit_field("parent_level_id", levels))}
        #{and_if_not_empty(populate_or_omit_field("parent_kind_id", kinds))}
      "

      {:ok, resultset} = Ppa.RepoPpa.query(query)
      map = Ppa.Util.Query.resultset_to_map(resultset)
      List.first(map)
  end

  def stock_report_ex(params, levels, kinds) do
    ids_ies = solve_ies_ids(params)

    base_query =
      """
       SELECT
          parent_level_id,
          parent_kind_id,
          -- WINDOW
          count(case when offers."position" = 1 AND offers.paid_seats <= 0 AND (offers.reserved_seats < offers.total_seats OR offers.limited = false) THEN offer_id END) window_unsold,
          count(case when offers."position" = 1 AND offers.paid_seats > 0 AND ((offers.total_seats - offers.reserved_seats > 0) OR offers.limited = false)
                          THEN offer_id END) window_saleable,
          count(case when offers."position" = 1 AND offers.reserved_seats >= offers.total_seats AND offers.limited THEN offer_id END) window_soldout,

          -- BASE
          count(case when (offers."position" <> 1 OR offers."position" IS NULL) AND offers.paid_seats <= 0 AND (offers.reserved_seats < offers.total_seats OR offers.limited = false) THEN offer_id END) base_unsold,
          count(case when (offers."position" <> 1 OR offers."position" IS NULL) AND offers.paid_seats > 0 AND ((offers.total_seats - offers.reserved_seats) > 0 OR offers.limited = false)
                          THEN offer_id END) base_saleable,
          count(case when (offers."position" <> 1 OR offers."position" IS NULL) AND offers.reserved_seats >= offers.total_seats AND offers.limited THEN offer_id END) base_soldout
        FROM (
          SELECT
            offer.id                                offer_id,
            level.parent_id                         parent_level_id,
            kind.parent_id                          parent_kind_id,
            seats_balance.saleable_seats            saleable_seats,
            seats_balance.reserved_seats            reserved_seats,
            seats_balance.total_seats               total_seats,
            seats_balance.limited                   limited,
            offer."position"                          "position",
            coalesce(sum(seats_transactions.paid_seats_delta), 0) paid_seats
          FROM offers offer
            join courses course on course.id = offer.course_id
            join levels level on level.name = course.level and level.parent_id is not null
            join kinds kind on kind.name = course.kind and kind.parent_id is not null
            join seats_balances seats_balance on seats_balance.id = offer.seats_balance_id
            left join seats_transactions on offer_id = offer.id
          WHERE offer.enabled is true AND offer.restricted is false AND offer.university_id in (#{Enum.join(ids_ies, ",")})
          GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
        ) as offers
        GROUP BY
          parent_kind_id,
          parent_level_id
      """

      query = "select
        sum(base_unsold) as base_unsold,
        sum(base_saleable) as base_saleable
      from (#{base_query}) as stock_data
      where
        true
        #{and_if_not_empty(populate_or_omit_field("parent_level_id", levels))}
        #{and_if_not_empty(populate_or_omit_field("parent_kind_id", kinds))}
      "

      {:ok, resultset} = Ppa.RepoPpa.query(query)
      map = Ppa.Util.Query.resultset_to_map(resultset)
      List.first(map)
  end
end

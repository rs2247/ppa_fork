defmodule Ppa.Util.Analisys.QapPresentation do
  import Ppa.Util.Analisys.Base
  import Ppa.Util.Sql
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Format
  import Ecto.Query
  require Logger

  @kind_id_presencial 1
  @kind_id_ead 3
  @kind_id_semi_presencial 8

  def execute(params, topic) do
    Logger.info "Analisys.QapPresentation.execute# params: #{inspect params}"

    merge_ead = params["mergeEadAndSemi"]

    base_filter = Enum.at(params["baseFilters"], 0)
    ies_info = if base_filter["type"] == "university" do
      university_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.University, university_id)
    else
      group_id = base_filter["value"]["id"]
      Ppa.RepoPpa.get(Ppa.EducationGroup, group_id)
    end

    base_date = Timex.today

    levels = map_ids(params["levels"])
    kinds = map_ids(params["kinds"])

    kinds_filter_set = MapSet.new(kinds)

    # TODO - capture periods hardcoded!
    # precisa mudar dinamicamente, mas como?
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, 6)

    # se nao tem graduacao ou nao tem pos, nao precisa do slide inicial de graduacao ou pos
    # pq ja vai fazer o slide geral que junta tudo!
    filtro_tem_grad = Enum.member?(levels, ["1"])
    filtro_tem_pos = Enum.member?(levels, ["7"])

    # precisa gerar o slide principal com todos os filtros!

    # nao eh esperado ter delete nesse! a nao ser que nao tenha dado nenhum!
    initial_slide = slide_for_entry(base_filter, capture_period, { kinds, nil, 0, nil, true }, levels, nil, kinds_filter_set, 5, 0)

    # TEM GRADUACAO?
    grad_slides = if filtro_tem_grad or levels == [] do
      process_slides_for_level(capture_period, base_filter, ["1"], "graduação", kinds_filter_set, merge_ead, 0, 6)
    else
      # delete os 3
      Logger.info "SEM GRADUACAO"
      %{
        "DELETE_SLIDE_7" => %{ type: :delete_slide, slide_index: 6 },
        "DELETE_SLIDE_8" => %{ type: :delete_slide, slide_index: 7 },
        "DELETE_SLIDE_9" => %{ type: :delete_slide, slide_index: 8 },
        "DELETE_SLIDE_10" => %{ type: :delete_slide, slide_index: 9 }
      }
    end

    # TEM POS-GRADUACAO?
    pos_slides = if filtro_tem_pos or levels == [] do
      process_slides_for_level(capture_period, base_filter, ["7"], "pós-graduação", kinds_filter_set, merge_ead, 4, 6)
    else
      Logger.info "SEM POS"
      %{
        "DELETE_SLIDE_11" => %{ type: :delete_slide, slide_index: 10 },
        "DELETE_SLIDE_12" => %{ type: :delete_slide, slide_index: 11 },
        "DELETE_SLIDE_13" => %{ type: :delete_slide, slide_index: 12 },
        "DELETE_SLIDE_14" => %{ type: :delete_slide, slide_index: 13 }
      }
    end

    Logger.info "initial_slide: #{inspect initial_slide}"

    Logger.info "grad_slides: #{inspect grad_slides}"

    Logger.info "pos_slides: #{inspect pos_slides}"

    # no final, preciso saber se esta tirando slide 11, ou 7, se tiver tirando um deles, deve tirar o outro tb, pq ja tem o slide geral inicial


    analysis_map = %{
      "IES_NAME" => ies_info.name,
      "DATE" => "#{base_date.day} de #{Enum.at(Ppa.Util.Timex.months_names, base_date.month - 1)} de #{base_date.year}",
      "TITULO_PRINCIPAL" => "Projeções de Captacao 2020.1",
    } |> Map.merge(initial_slide)
      |> Map.merge(grad_slides)
      |> Map.merge(pos_slides)

    ajuste_slides = cond do
      ( Map.has_key?(analysis_map, "DELETE_SLIDE_11") && not Map.has_key?(analysis_map, "DELETE_SLIDE_7") ) or ( Map.has_key?(analysis_map, "DELETE_SLIDE_7") && not Map.has_key?(analysis_map, "DELETE_SLIDE_11") )-> %{ "DELETE_SLIDE_6" => %{ type: :delete_slide, slide_index: 5 } }
      true -> %{}
    end

    Logger.info "ajuste_slides: #{inspect ajuste_slides} K_11: #{  Map.has_key?(analysis_map, "DELETE_SLIDE_11")} K_7: #{Map.has_key?(analysis_map, "DELETE_SLIDE_7")}"

    analysis_map = Map.merge(analysis_map, ajuste_slides)

    Logger.info "analysis_map: #{inspect analysis_map}"

    output = generate_presentation(analysis_map, "template_quero_pago.pptx")

    Logger.info "output: #{output}"
    output_map = Poison.decode!(output)
    Logger.info "output_map: #{inspect output_map}"

    if output_map["sucess"] do
      Ppa.Endpoint.broadcast(topic, "analysisData", %{ filename: output_map["filename"], download_name: ies_info.name })
    else
      Ppa.Endpoint.broadcast(topic, "analysisError", %{})
    end
  end

  def slide_for_entry(base_filter, capture_period, entry, level_ids, level_name, kinds_filter_set, slides_offset, base_index) do
    { kinds_list, title, slide_index, default_months, force_empty_filter } = entry
    kinds_set = MapSet.new(kinds_list)

    university_id = base_filter["value"]["id"]

    Logger.info "kinds_set: #{inspect kinds_set} kinds_filter_set: #{inspect kinds_filter_set}"

    # vai fazer a intersecao
    # se nao achar nada, vai deletar o slide
    # mas existe um caso em que nenhum filtro eh tudo, entao precisa de um flag de force

    kinds_filter = if MapSet.size(kinds_filter_set) == 0 do
      kinds_list
    else
      Enum.map(MapSet.intersection(kinds_set, kinds_filter_set), &(&1))
    end

    Logger.info "kinds_filter: #{inspect kinds_filter}"

    presentation_slide = slide_index + slides_offset + base_index
    delete_slide_map = %{
      "DELETE_SLIDE_#{presentation_slide}" => %{ type: :delete_slide, slide_index: presentation_slide - 1 }
    }

    if kinds_filter == [] && not force_empty_filter do
      Logger.info "DELETE EMPTY FILTER WITHOUT FORCE"
      delete_slide_map
    else
      projections_query = projections_query(university_id, kinds_filter, level_ids, capture_period.start, capture_period.end)
      { :ok, resultset } = Ppa.RepoPpa.query(projections_query)
      projection_map = Ppa.Util.Query.resultset_to_map(resultset)

      if Enum.empty?(projection_map) do
        Logger.info "DELETE EMPTY PROJECTION DATA"
        delete_slide_map
      else
        [projection_entry] = projection_map

        if projection_entry["base_projection"] == 0 or
           projection_entry["qap_projection"] == 0 or
           is_nil(projection_entry["base_projection"]) or
           is_nil(projection_entry["qap_projection"]) do

          Logger.info "NULL DATA IN PROJECTION ENTRY"

          delete_slide_map
        else

          # busca o ticket medio
          # params = %{
          #   "baseFilters" => [ base_filter ]
          # }
          # product_line_data = Ppa.Util.Analisys.SemesterEnd.product_line_data(params, capture_period, Enum.map(level_ids, &(%{"id"=>&1})), Enum.map(kinds_filter, &(%{"id"=>&1})))
          # Logger.info "product_line_data: #{inspect product_line_data}"

          ticket_medio = format_precision(projection_entry["offered_medio_ponderado"], 2)
          valor_sem_qp = projection_entry["base_income"]
          valor_com_qp = projection_entry["qap_income"]
          if is_nil(valor_com_qp) do
            delete_slide_map
          else
            valor_com_qp_liq = Decimal.mult(valor_com_qp, Decimal.from_float(0.9))
            ganho_liquido =  Decimal.add(valor_com_qp_liq, Decimal.mult(valor_sem_qp, -1))

            crescimento_alunos = projection_entry["qap_projection"] - projection_entry["base_projection"]
            cresimento_alunos_percentual = Decimal.round(Decimal.mult(Decimal.div(crescimento_alunos, projection_entry["base_projection"]), 100))

            slide_index_in_map = slide_index + base_index

            slide_title = cond do
              not is_nil(title) and not is_nil(level_name) -> "Somente #{String.capitalize(level_name)} #{title}"
              not is_nil(level_name) -> "Somente #{String.capitalize(level_name)}"
              not is_nil(title) -> "Somente #{title}"
              true -> ""
            end

            months_string = if is_nil(default_months) do
              ""
            else
              "uma duração de #{default_months} meses #{level_name} #{title} e "
            end

            %{
              "MODALIDADE_SLIDE_#{slide_index_in_map}" => slide_title,
              "GANHO_LIQUIDO_#{slide_index_in_map}" => "+R$ #{format_precision(ganho_liquido, 2)}",
              "VALOR_SEM_QP_#{slide_index_in_map}" => "R$ #{format_precision(valor_sem_qp, 2)}",
              "ALUNOS_SEM_QP_#{slide_index_in_map}" => "#{format_precision(projection_entry["base_projection"])}",
              "VALOR_COM_QP_#{slide_index_in_map}" => "R$ #{format_precision(valor_com_qp, 2)}",
              "ALUNOS_COM_QP_#{slide_index_in_map}" => "#{format_precision(projection_entry["qap_projection"])}",
              "VALOR_COM_QP_LIQ_#{slide_index_in_map}" => "R$ #{format_precision(valor_com_qp_liq, 2)}",
              "CRESC_QAP_#{slide_index_in_map}" => " + #{crescimento_alunos} (#{cresimento_alunos_percentual}%)",
              "LEGENDA_#{slide_index_in_map}" => "* Projeção realizada usando como premissa #{months_string}ticket médio vendido atual de R$#{ticket_medio}.",
            }
          end
        end
      end
    end
  end

  def process_slides_for_level(capture_period, base_filter, level_ids, level_name, kinds_filter_set, merge_ead, base_index, slides_offset) do
    Logger.info "process_slides_for_level# base_filter: #{inspect base_filter}"

    { months_presential, months_ead } = if level_ids == ["1"] do
      { 30, 28 }
    else
      { 15, 14 }
    end

    # university_id = base_filter["value"]["id"]
    presential_kinds = ["#{@kind_id_presencial}"]
    ead_kinds = ["#{@kind_id_ead}"]
    semi_kinds = ["#{@kind_id_semi_presencial}"]

    other_kinds_query = from k in Ppa.Kind,
      where: fragment("? is null ", k.parent_id) and k.id not in ^[@kind_id_presencial],
      select: k.id
    other_kinds = Enum.map(Ppa.RepoPpa.all(other_kinds_query), &("#{&1}"))

    kinds_filter = Enum.map(kinds_filter_set, &(&1))

    kinds_list = if merge_ead do
      [
        { kinds_filter, nil, 1, nil, true },
        { presential_kinds, "Presencial", 2, months_presential, false },
        { other_kinds, "EAD e Semi", 3, months_ead, false },
        { [], "", 4, 0, false }
      ]
    else
      [
        { kinds_filter, nil, 1, nil, true },
        { presential_kinds, "Presencial", 2, months_presential, false },
        { ead_kinds, "EAD", 3, months_ead, false },
        { semi_kinds, "Semipresencial", 4, months_ead, false }
      ]
    end

    Logger.info "kinds_list: #{inspect kinds_list}"

    slides_list = Enum.map(kinds_list, fn entry ->
      slide_for_entry(base_filter, capture_period, entry, level_ids, level_name, kinds_filter_set, slides_offset, base_index)
    end)

    Enum.reduce(slides_list, %{}, fn entry, acc ->
      Map.merge(acc, entry)
    end)
  end


  def projections_query(university_id, kinds, levels, start_date, end_date) do
    "select
      sum(base_projection)::integer as base_projection,
      sum(qap_projection)::integer as qap_projection,
      case when sum(base_projection) > 0 then sum(offereds.offered_medio * base_projection) / sum(base_projection) end as offered_medio_ponderado,
      sum(base_projection * offereds.offered_medio *
          case
          when projections_base.level_id = 1 and projections_base.kind_id = 1 then
            30
          when projections_base.level_id = 1 and projections_base.kind_id <> 1 then
            28
          when projections_base.level_id <> 1 and projections_base.kind_id = 1 then
            15
          when projections_base.level_id <> 1 and projections_base.kind_id <> 1 then
            14
          end
        ) as base_income,
        sum(qap_projection * offereds.offered_medio *
          case
          when projections_base.level_id = 1 and projections_base.kind_id = 1 then
            38
          when projections_base.level_id = 1 and projections_base.kind_id <> 1 then
            35
          when projections_base.level_id <> 1 and projections_base.kind_id = 1 then
            17
          when projections_base.level_id <> 1 and projections_base.kind_id <> 1 then
            16
          end
        ) as qap_income
      from (
          select
            sum(base_projection) as base_projection,
            sum(qap_projection) as qap_projection,
            level_id, kind_Id
          from parcerias.students_projections
            where
              active and
              capture_period_id = 7 and
              university_id = #{university_id}
              #{and_if_not_empty(populate_or_omit_field("level_id", levels))}
              #{and_if_not_empty(populate_or_omit_field("kind_id", kinds))}
            group by
              level_id, kind_id
      ) as projections_base
      left join (

        SELECT
          avg(o.offered_price) as offered_medio,
          l.parent_id as level_id, k.parent_id as kind_id
        FROM   querobolsa_production.follow_ups fu
             INNER JOIN querobolsa_production.offers o ON (o.id = fu.offer_id)
             INNER JOIN querobolsa_production.courses c ON (c.id = fu.course_id)
             INNER JOIN querobolsa_production.levels l ON (l.name = c.level and l.parent_id is not null)
             INNER JOIN querobolsa_production.kinds k ON (k.name = c.kind and k.parent_id is not null)
             where fu.university_id = #{university_id}
              and fu.created_at >= '#{to_iso_date_format(start_date)}' and fu.created_at <= '#{to_iso_date_format(end_date)}'
        group by
            l.parent_id, k.parent_id
      ) as offereds on (offereds.level_id = projections_base.level_id and offereds.kind_id = projections_base.kind_id )
  "
  end
end

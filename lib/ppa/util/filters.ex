defmodule Ppa.Util.Filters do
  import Ecto.Query
  import Ppa.Util.Sql
  import Ppa.Util.Timex
  require Logger

  def map_ids(nil), do: []
  def map_ids(a), do: Enum.map(a, &(&1["id"]))

  def map_types(nil), do: []
  def map_types(a), do: Enum.map(a, &(&1["type"]))

  def cities() do
    query = "select id, name as city, state from cities"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    Enum.map(resultset_map, fn entry ->
      %{ name: "#{entry["city"]} - #{entry["state"]}", state: entry["state"], city: entry["city"], city_id: entry["id"] }
    end)
  end

  def clean_canonical_courses() do
    courses_query = from c in Ppa.CanonicalCourse, where: c.clean_canonical_course_id == c.id, select: %{ id: c.id, name: c.name }
    Ppa.RepoPpa.all(courses_query)
  end

  def groups_names(ids) do
    query = from u in Ppa.EducationGroup, where: u.id in ^ids, select: {u.id, u.name}
    resultset = Ppa.RepoPpa.all(query)
    resultset_map = Enum.reduce(resultset, %{}, fn { id, name}, acc ->
      Map.put(acc, "#{id}", name)
    end)
    Enum.map(ids, &(resultset_map[&1]))
  end

  def universities_names(ids) do
    query = from u in Ppa.University, where: u.id in ^ids, select: {u.id, u.name}
    resultset = Ppa.RepoPpa.all(query)
    resultset_map = Enum.reduce(resultset, %{}, fn { id, name}, acc ->
      Map.put(acc, "#{id}", name)
    end)
    Enum.map(ids, &(resultset_map[&1]))
  end

  def kinds_names(ids) do
    query = from u in Ppa.Kind, where: u.id in ^ids, select: {u.id, u.name}
    resultset = Ppa.RepoPpa.all(query)
    resultset_map = Enum.reduce(resultset, %{}, fn { id, name}, acc ->
      Map.put(acc, "#{id}", name)
    end)
    Enum.map(ids, &(resultset_map[&1]))
  end

  def levels_names(ids) do
    query = from u in Ppa.Level, where: u.id in ^ids, select: {u.id, u.name}
    resultset = Ppa.RepoPpa.all(query)
    resultset_map = Enum.reduce(resultset, %{}, fn { id, name}, acc ->
      Map.put(acc, "#{id}", name)
    end)
    Enum.map(ids, &(resultset_map[&1]))
  end

  def product_lines_kinds(product_lines_ids) do
    query = "select distinct kind_id from product_lines_kinds where product_line_id in (#{Enum.join(product_lines_ids, ",")})"
    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map  = Ppa.Util.Query.resultset_to_map(resultset)
    Enum.map(resultset_map, &(&1["kind_id"]))
  end

  def product_lines_levels(product_lines_ids) do
    query = "select distinct level_id from product_lines_levels where product_line_id in (#{Enum.join(product_lines_ids, ",")})"
    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map  = Ppa.Util.Query.resultset_to_map(resultset)
    Enum.map(resultset_map, &(&1["level_id"]))
  end

  # TODO - melhor lugar?
  def solve_product_line(kinds, levels, capture_period_id) do
    capture_period = Ppa.RepoPpa.get(Ppa.CapturePeriod, capture_period_id)
    Logger.info "solve_product_line: kinds: #{inspect kinds} levels: #{inspect levels}"
    if Enum.empty?(kinds) && Enum.empty?(levels) do
      nil
    else
      kinds_where = if Enum.empty?(kinds) do
        ""
      else
        "and kinds @> '{#{Enum.join(kinds, ",")}}'"
      end

      levels_where = if Enum.empty?(levels) do
        ""
      else
        "and levels @> '{#{Enum.join(levels, ",")}}'"
      end

      # tem mais de uma com relevancia?
      # se tiver nao tem determinismo no filtro!
      query_report = "
      select count(*), count(case when relevance > 0 then 1 end) as com_relevancia From (
        SELECT    pl.id,
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
              AND       (start_date <= '#{to_iso_date_format(capture_period.end)}'
        AND       (
                        end_date >= '#{to_iso_date_format(capture_period.start)}'
              OR        end_date is NULL)))
        GROUP BY  pl.id
      ) as d
      where true
        #{kinds_where}
        #{levels_where}
      "

      {:ok, resultset_report} = Ppa.RepoPpa.query(query_report)
      resultset_report_map  = Ppa.Util.Query.resultset_to_map(resultset_report)
      [report_data] = resultset_report_map
      if report_data["com_relevancia"] > 1 do
        nil
      else

        Logger.info "resultset_report_map: #{inspect resultset_report_map}"

        query = "
        select * From (
          SELECT    pl.id,
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
                AND       (start_date <= '#{to_iso_date_format(capture_period.end)}'
          AND       (
                          end_date >= '#{to_iso_date_format(capture_period.start)}'
                OR        end_date is NULL)))
          GROUP BY  pl.id
        ) as d
        where true
          #{kinds_where}
          #{levels_where}
        order by relevance desc limit 1"

        {:ok, resultset} = Ppa.RepoPpa.query(query)
        resultset_map  = Ppa.Util.Query.resultset_to_map(resultset)
        if resultset_map == [] do
          nil
        else
          [ product_line ] = resultset_map
          Logger.info "solve_product_line# product_line: #{inspect product_line}"
          if product_line["id"] == 1 do
            nil
          else
            product_line["id"]
          end
        end
      end
    end
  end

  def product_lines(capture_period_id) do
    query_distinct_product_lines = "
      select
        distinct product_line_id
      from
        capture_periods cp
        inner join
          university_deal_owners udo
            on (udo.start_date <= cp.end and (udo.end_date >= cp.start or udo.end_date is null))
      where
        cp.id = #{capture_period_id}
      "

    {:ok, resultset_distinct_product_lines } = Ppa.RepoPpa.query(query_distinct_product_lines)
    distinct_product_lines_map = Ppa.Util.Query.resultset_to_map(resultset_distinct_product_lines)

    if Enum.empty?(distinct_product_lines_map) do
      Logger.info "product_lines# NENHUMA LINHA DE PRODUTO ENCONTRADA capture_period_id: #{capture_period_id}"
      []
    else
      query_product_lines = "select id, name from product_lines where id in (#{Enum.join(Enum.map(distinct_product_lines_map,&(&1["product_line_id"])), ",")})"
      Logger.info "product_lines# query_product_lines: #{query_product_lines}"
      {:ok, resultset_product_lines } = Ppa.RepoPpa.query(query_product_lines)
      resultset_product_lines_map = Ppa.Util.Query.resultset_to_map(resultset_product_lines)

      Enum.map(resultset_product_lines_map, fn entry ->
        %{ name: entry["name"], id: entry["id"] }
      end)
    end
  end

  def ies_ids_filter(params, capture_period_id, product_line_id \\ nil) do
    case params["type"] do
      "all" -> [ ]
      "university" -> [ params["value"]["id"] ]
      "group" -> group_ies(params["value"]["id"])
      "account_type" -> account_type_ies(params["value"]["id"], capture_period_id, product_line_id)
      "deal_owner" -> deal_owner_ies(params["value"]["id"], capture_period_id)
      "farm_region" -> farm_region_ies(params["value"]["id"])
      "deal_owner_ies" -> deal_owner_current_ies(params["value"]["id"], capture_period_id)
    end
  end

  def levels_leafs(levels_id) do
    query = from l in Ppa.Level, where: l.parent_id in ^levels_id, select: fragment("'''' || ? || ''''", l.name)
    Ppa.RepoPpa.all(query)
  end

  def kinds_leafs(kinds_id) do
    query = from k in Ppa.Kind, where: k.parent_id in ^kinds_id, select: fragment("'''' || ? || ''''", k.name)
    Ppa.RepoPpa.all(query)
  end

  def region_states(region) do
    query = from s in Ppa.State, where: s.region == ^region, select: fragment("'''' || ? || ''''", s.acronym)
    Ppa.RepoPpa.all(query)
  end

  def regions_states(regions) do
    query = from s in Ppa.State, where: s.region in ^regions, select: fragment("'''' || ? || ''''", s.acronym)
    Ppa.RepoPpa.all(query)
  end

  # USADO POR INEP-HANDLER
  def deal_owner_ies(deal_owner, capture_period_id) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    Logger.info "deal_owner_ies# capture_period_id: #{capture_period_id} current_id: #{current_id}"
    query = from u in Ppa.UniversityDealOwner,
      join: c in Ppa.CapturePeriod,
      on: fragment("date(?) >= date(?) and ((date(?) <= date(?)) or (? is null and ? = ?))", u.start_date, c.start, u.end_date, c.end, u.end_date, c.id, ^current_id),
      where: c.id == ^capture_period_id and u.admin_user_id == ^deal_owner,
      select: u.university_id,
      distinct: u.university_id
    Ppa.RepoPpa.all(query)
  end

  def farm_regions_ies(regions) do
    query = "select university_id from ppa.universities_regions where region in (#{Enum.join(quotes(regions))})"
    { :ok, resultset } = Ppa.RepoPpa.query(query)
    resultset_map  = Ppa.Util.Query.resultset_to_map(resultset)
    Enum.map(resultset_map, &(&1["university_id"]))
  end

  def farm_region_ies(region) do
    farm_regions_ies([region])
  end

  def quality_owner_ies(quality_owner, capture_period_id) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    Logger.info "quality_owner_ies# capture_period_id: #{capture_period_id} current_id: #{current_id}"
    query = from u in Ppa.UniversityQualityOwner,
      join: c in Ppa.CapturePeriod,
      on: fragment("date(?) >= date(?) and ((date(?) <= date(?)) or (? is null and ? = ?))", u.start_date, c.start, u.end_date, c.end, u.end_date, c.id, ^current_id),
      where: c.id == ^capture_period_id and u.admin_user_id == ^quality_owner,
      select: u.university_id,
      distinct: u.university_id
    Ppa.RepoPpa.all(query)
  end


  def deal_owner_current_ies(deal_owner, capture_period_id) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    Logger.info "deal_owner_current_ies# capture_period_id: #{capture_period_id} current_id: #{current_id}"
    query = from u in Ppa.UniversityDealOwner,
      join: c in Ppa.CapturePeriod,
      on: fragment("? is null", u.end_date),
      where: c.id == ^capture_period_id and u.admin_user_id == ^deal_owner,
      select: u.university_id,
      distinct: u.university_id
    Ppa.RepoPpa.all(query)
  end

  def quality_owner_current_ies(quality_owner, capture_period_id) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    Logger.info "quality_owner_current_ies# capture_period_id: #{capture_period_id} current_id: #{current_id}"
    query = from u in Ppa.UniversityQualityOwner,
      join: c in Ppa.CapturePeriod,
      on: fragment("? is null", u.end_date),
      where: c.id == ^capture_period_id and u.admin_user_id == ^quality_owner,
      select: u.university_id,
      distinct: u.university_id
    Ppa.RepoPpa.all(query)
  end

  def account_types_ies(account_types, capture_period_id) when is_binary(capture_period_id) do
    Logger.info "account_types_ies capture_period_id BINARY capture_period_id: #{capture_period_id}"
    { int_capture_period_id, _ } = Integer.parse(capture_period_id)
    account_types_ies(account_types, int_capture_period_id)
  end

  def account_types_ies(account_types, capture_period_id, product_line_id \\ nil) do
    # current_id = Ppa.CapturePeriod.actual_capture_period.id # TODO  PQ TINHA ISSO AQUI?
      # deixa amarrado e nao permite usar a selecao na tela!
    Logger.info "account_types_ies capture_period_id NOT BINARY capture_period_id: #{capture_period_id} product_line_id: #{product_line_id}"
    product_line_filter = and_if_not_empty(populate_or_omit_field("product_line_id", product_line_id))
    query = "
    select
      distinct u.university_id as university_id
    from
      university_deal_owners u
      inner join capture_periods c
         on (date(u.start_date) >= date(c.start) and ((date(u.end_date) <= date(c.end)) or (u.end_date is null and c.id = #{capture_period_id})))
    where
      c.id = #{capture_period_id}
      and u.account_type in (#{Enum.join(account_types, ",")})
      #{product_line_filter}"

    {:ok, resultset} = Ppa.RepoPpa.query(query)
    resultset_map  = Ppa.Util.Query.resultset_to_map(resultset)
    Enum.map(resultset_map, &(&1["university_id"]))
  end

  def account_type_ies(account_type, capture_period_id, product_line_id \\ nil) do
    account_types_ies([account_type], capture_period_id, product_line_id)
  end

  def group_ies(group_id) do
    query = from u in Ppa.University, where: u.status in ["partner", "frozen_partnership", "enabled"] and u.education_group_id == ^group_id, select: u.id
    Ppa.RepoPpa.all(query)
  end

  def groups_ies(group_ids) do
    query = from u in Ppa.University, where: u.status in ["partner", "frozen_partnership", "enabled"] and u.education_group_id in ^group_ids, select: u.id
    Ppa.RepoPpa.all(query)
  end

  def deal_owner_universities(deal_owner_id) do
    query = from o in Ppa.UniversityDealOwner,
      join: u in Ppa.University,
      on: u.id == o.university_id,
      where: fragment("? is null", o.end_date) and o.admin_user_id == ^deal_owner_id,
      select: %{ name: fragment("'(' || ? || ') - ' || ?", u.id, u.name), id: u.id, simple_name: u.name },
      order_by: u.id
    Ppa.RepoPpa.all(query)
  end

  def deal_owner_universities_id(deal_owner_id, product_line_id \\ nil) do
    query = if is_nil(product_line_id) do
      from o in Ppa.UniversityDealOwner,
      join: u in Ppa.University,
      on: u.id == o.university_id,
      where: fragment("? is null", o.end_date) and o.admin_user_id == ^deal_owner_id,
      select: u.id,
      order_by: u.id
    else
      from o in Ppa.UniversityDealOwner,
      join: u in Ppa.University,
      on: u.id == o.university_id,
      where: fragment("? is null", o.end_date) and o.admin_user_id == ^deal_owner_id and o.product_line_id == ^product_line_id,
      select: u.id,
      order_by: u.id
    end
    Ppa.RepoPpa.all(query)
  end

  def universities do
    query = from u in Ppa.University, where: u.status in ["partner", "frozen_partnership", "enabled"], select: %{ name: fragment("'(' || ? || ') - ' || ?", u.id, u.name), id: u.id, simple_name: u.name }, order_by: u.id
    Ppa.RepoPpa.all(query)
  end

  def groups do
    query = from u in Ppa.EducationGroup, select: %{ name: fragment("'(' || ? || ') - ' || ?", u.id, u.name), id: u.id }
    Ppa.RepoPpa.all(query)
  end

  def kinds do
    Enum.map(CourseFilters.kind_select_options, fn { name, id} ->
      %{name: name, id: id}
    end)
  end

  def levels do
    Enum.map(CourseFilters.level_select_options, fn { name, id} ->
      %{name: name, id: id}
    end)
  end

  def location_types do
    [
      %{ name: "Região", type: "region"},
      %{ name: "Estado", type: "state"},
      %{ name: "Cidade", type: "city"},
      %{ name: "Campus", type: "campus"}
    ]
  end

  def states_options do
    query = from s in Ppa.State, select: %{ name: s.name, type: s.acronym }
    Ppa.RepoPpa.all(query)
  end

  def region_options do
    [
      %{ name: "Norte", type: "norte"},
      %{ name: "Sul", type: "sul"},
      %{ name: "Centro-Oeste", type: "centro_oeste"},
      %{ name: "Nordeste", type: "nordeste"},
      %{ name: "Sudeste", type: "sudeste"}
    ]
  end

  def farm_region_options do
    [
      %{ name: "TOP8", id: "TOP8"},
      %{ name: "SE", id: "SE"},
      %{ name: "Oeste", id: "Oeste"},
      %{ name: "NE", id: "NE"},
      %{ name: "Ativação", id: "Ativação"}
    ]
  end

  def group_options do
    [
      %{ name: "Universidade", type: "university"},
      %{ name: "Grupo", type: "group"},
      %{ name: "Farmer", type: "deal_owner"},
      %{ name: "Carteira", type: "account_type"},
      %{ name: "Quali", type: "quality_owner"},
      %{ name: "Site Todo", type: ""}
    ]
  end

  def account_type_options do
    [
      %{ name: "Carteira 1", id: 1},
      %{ name: "Carteira 2", id: 2},
      %{ name: "Carteira 3", id: 3},
      %{ name: "Carteira 4", id: 4},
      %{ name: "Carteira 5", id: 5},
    ]
  end

  def active_deal_owners(capture_period_id, product_line_id \\ nil) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    query = if is_nil(product_line_id) do
      from u in Ppa.UniversityDealOwner,
        join: au in Ppa.AdminUser, on: au.id == u.admin_user_id,
        join: c in Ppa.CapturePeriod,
        on: fragment("? is null", u.end_date),
        select: %{ email: au.email, id: au.id },
        distinct: au.id
    else
      from u in Ppa.UniversityDealOwner,
        join: au in Ppa.AdminUser, on: au.id == u.admin_user_id,
        join: c in Ppa.CapturePeriod,
        on: fragment("? is null", u.end_date),
        where: c.id == ^capture_period_id and u.product_line_id == ^product_line_id,
        select: %{ email: au.email, id: au.id },
        distinct: au.id
    end
    owners = Ppa.RepoPpa.all(query)
    Enum.map(owners, fn owner ->
      { index, _count } = :binary.match(owner.email, "@")
      name = String.slice(owner.email, 0, index)
      filtered_name = Enum.map(String.split(name, "."), &(String.capitalize(&1)))
      Map.put(owner, :name, Enum.join(filtered_name, " "))
    end)
  end

  def deal_owners(capture_period_id, product_line_id \\ nil) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    query =  if is_nil(product_line_id) do
      from u in Ppa.UniversityDealOwner,
        join: au in Ppa.AdminUser, on: au.id == u.admin_user_id,
        join: c in Ppa.CapturePeriod,
        on: fragment("date(?) >= date(?) and ((date(?) <= date(?)) or (? is null and ? = ?))", u.start_date, c.start, u.end_date, c.end, u.end_date, c.id, ^current_id),
        where: c.id == ^capture_period_id,
        select: %{ email: au.email, id: au.id },
        distinct: au.id
    else
      from u in Ppa.UniversityDealOwner,
        join: au in Ppa.AdminUser, on: au.id == u.admin_user_id,
        join: c in Ppa.CapturePeriod,
        on: fragment("date(?) >= date(?) and ((date(?) <= date(?)) or (? is null and ? = ?))", u.start_date, c.start, u.end_date, c.end, u.end_date, c.id, ^current_id),
        where: c.id == ^capture_period_id and u.product_line_id == ^product_line_id,
        select: %{ email: au.email, id: au.id },
        distinct: au.id
    end
    owners = Ppa.RepoPpa.all(query)
    Enum.map(owners, fn owner ->
      { index, _count } = :binary.match(owner.email, "@")
      name = String.slice(owner.email, 0, index)
      filtered_name = Enum.map(String.split(name, "."), &(String.capitalize(&1)))
      Map.put(owner, :name, Enum.join(filtered_name, " "))
    end)
  end

  def quality_owners(capture_period_id) do
    current_id = Ppa.CapturePeriod.actual_capture_period.id
    query = from u in Ppa.UniversityQualityOwner,
      join: au in Ppa.AdminUser, on: au.id == u.admin_user_id,
      join: c in Ppa.CapturePeriod,
      on: fragment("date(?) >= date(?) and ((date(?) <= date(?)) or (? is null and ? = ?))", u.start_date, c.start, u.end_date, c.end, u.end_date, c.id, ^current_id),
      where: c.id == ^capture_period_id,
      select: %{ email: au.email, id: au.id },
      distinct: au.id
    owners = Ppa.RepoPpa.all(query)
    Enum.map(owners, fn owner ->
      { index, _count } = :binary.match(owner.email, "@")
      name = String.slice(owner.email, 0, index)
      filtered_name = Enum.map(String.split(name, "."), &(String.capitalize(&1)))
      Map.put(owner, :name, Enum.join(filtered_name, " "))
    end)
  end

  def map_simple_name(list) do
    Enum.map(list, &(Map.put(&1, :simple_name, &1.name)))
  end

  def populate_filters(filters_columns, conversion_map) do
    filters = Enum.map(filters_columns, fn [ field, value ] ->
      if Map.has_key?(conversion_map, field) do
        table_alias = conversion_map[field]
        if is_nil(table_alias) or table_alias == "" do
          [populate_field(field, value)]
        else
          [populate_field("#{conversion_map[field]}.#{field}", value)]
        end
      else
        ["",""]
      end
    end)
    Enum.filter(filters, &(Enum.at(&1,0) != ""))
  end

  def parse_date(input) when is_binary(input) do
    Elixir.Timex.Parse.DateTime.Parser.parse(input, "{ISO:Extended:Z}")
  end
  def parse_date(input) do
    { :ok, input }
  end

  def load_date_field(params, field) do
    { :ok, data } = parse_date(params[field])
    data
  end

  def lookup_capture_period(start_date, end_date) do
    query = from c in Ppa.CapturePeriod,
      where: fragment("date(?) <= date(?) and date(?) >= date(?)", c.start, ^start_date, c.end, ^end_date)
    periods = Ppa.RepoPpa.all(query)
    List.first(periods)
  end
end

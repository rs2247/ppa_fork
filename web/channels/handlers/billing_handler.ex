defmodule Ppa.BillingHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  import Math
  require Tasks

  def handle_load_data(socket, params) do
    Tasks.async_handle((fn -> load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket, _params) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def handle_edit_promisse(socket, params) do
    Tasks.async_handle((fn -> edit_promisse(socket, params) end))
    {:reply, :ok, socket}
  end

  def edit_promisse(socket, params) do
    Logger.info "edit_promisse# params: #{inspect params} socket: #{inspect socket.assigns}"

    university_id = params["university_id"]
    promisse = params["promisse"]

    query = from p in Ppa.StudentsProjection,
      where: p.university_id == ^university_id and p.active,
      limit: 1

    current_projection = Ppa.RepoQB.one(query)
    new_projection = Map.drop(current_projection, [:id, :created_at, :updated_at])

    disable_projection = Ppa.StudentsProjection.changeset_for_disable(current_projection)
    insert_projection = Ppa.StudentsProjection.changeset_for_insert(new_projection, %{admin_user_id: socket.assigns.admin_user_id, promisse: promisse})

    Ppa.RepoQB.transaction(fn ->
      Ppa.RepoQB.update(disable_projection)
      Ppa.RepoQB.insert(insert_projection)
    end)

    Ppa.Endpoint.broadcast(socket.assigns.topic, "promisseEdit", %{})
  end

  def load_filters(socket) do
    config = Ppa.UsersConfigurations.get_config(socket.assigns.admin_user_id)
    response_map = %{
      product_lines: product_lines(socket.assigns.capture_period),
      current_product_line: config.product_line_id
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", response_map)
  end

  def load_data(socket, params) do
    Logger.info "Ppa.BillingHandler::load_data: params: #{inspect params}"
    capture_period_id = socket.assigns.capture_period

    product_line_id = params["product_line_id"]
    { levels, kinds } = if is_nil(product_line_id) do
      { [], [] }
    else
      {
        product_lines_levels([product_line_id]),
        product_lines_kinds([product_line_id])
      }
    end

    Logger.info "load_data# levels: #{inspect levels} kinds: #{inspect kinds}"

    inner_query_ies = "SELECT DISTINCT
    ON (
         university_id) university_id,
           Array_agg(k_name
         || ' - '
         || levels) OVER (partition BY university_id) AS product_lines,
           Sum(total_count) OVER (partition BY university_id)  AS full_count,
           Sum(not_qap_count) OVER (partition BY university_id)         AS not_qap_count,
           Sum(qap_count) OVER (partition BY university_id)    AS qap_count,
           Sum(enrolled_count) OVER (partition BY university_id)    AS enrolled_count,
           Sum(qap_enrolled_count) OVER (partition BY university_id)    AS qap_enrolled_count,
           Sum(adjusted_projection) OVER (partition BY university_id)   AS adjusted_projection,
           Sum(promisse) OVER (partition BY university_id)     AS promisse,
           Sum(meta_movel_qap) OVER (partition BY university_id)     AS meta_movel_qap,
           Sum(projecao_movel) OVER (partition BY university_id)        AS projecao_movel,
           Min(billing_start) OVER (partition BY university_id)         AS billing_start
    FROM   (
         SELECT DISTINCT
         ON (
              university_id, k_name) university_id,
                k_name,
                String_agg(l_name, ' & ') OVER (partition BY university_id, k_name)::text levels,
                sum(total_count) over (partition by university_id, k_name)         AS total_count,
                sum(not_qap_count) OVER (partition BY university_id, k_name)       AS not_qap_count,
                sum(qap_count) OVER (partition BY university_id, k_name)  AS qap_count,
                sum(enrolled_count) OVER (partition BY university_id, k_name)  AS enrolled_count,
                sum(qap_enrolled_count) OVER (partition BY university_id, k_name)  AS qap_enrolled_count,
                sum(adjusted_projection) OVER (partition BY university_id, k_name) AS adjusted_projection,
                sum(promisse) OVER (partition BY university_id, k_name)   AS promisse,


                sum(
                CASE
              WHEN adjusted_promisse IS NOT NULL THEN (adjusted_promisse * (sazonalidade - (1 - sazonalidade_qap)) * fator_ajuste_sazonalidade_promessa)
              ELSE meta_movel_qap
                END) OVER (partition BY university_id, k_name)      AS meta_movel_qap,

                sum(
                CASE
              WHEN adjusted_promisse IS NOT NULL THEN (adjusted_promisse * (sazonalidade - (1 - sazonalidade_qap)) * fator_ajuste_sazonalidade_promessa) + not_qap_count
              ELSE meta_movel
                END) OVER (partition BY university_id, k_name)      AS projecao_movel,
                min(billing_start) OVER (partition BY university_id, k_name) AS billing_start
         FROM   (
                 #{base_query(capture_period_id, levels, kinds)} ) ddd ) dddd"




    inner_query_product_lines = "
                SELECT university_id,
                       ('{' || k_name || ' - ' || l_name || '}')::text[] AS product_lines,
                       total_count         AS full_count,
                       not_qap_count       AS not_qap_count,
                       enrolled_count      AS enrolled_count,
                       qap_enrolled_count  AS qap_enrolled_count,
                       qap_count  AS qap_count,
                       adjusted_projection AS adjusted_projection,
                       promisse   AS promisse,
                       CASE
                     WHEN adjusted_promisse IS NOT NULL THEN (adjusted_promisse * (sazonalidade - (1 - sazonalidade_qap)) * fator_ajuste_sazonalidade_promessa)
                     ELSE meta_movel_qap END as meta_movel_qap,
                       CASE
                     WHEN adjusted_promisse IS NOT NULL THEN (adjusted_promisse * (sazonalidade - (1 - sazonalidade_qap)) * fator_ajuste_sazonalidade_promessa) + not_qap_count
                     ELSE meta_movel
                       END      AS projecao_movel,
                       billing_start AS billing_start
                FROM   (
                  #{base_query(capture_period_id, levels, kinds)} ) dddd"

    inner_query = if params["type"] == "ies" do
      inner_query_ies
    else
      inner_query_product_lines
    end

    query = "
      SELECT
            university_id,
            product_lines,
            full_count,
            not_qap_count,
            qap_count,
            enrolled_count,
            qap_enrolled_count,
            adjusted_projection,
            promisse,
            billing_start,
            u.NAME AS university_name,
            u.account_type, -- carteira deve estar errada!
            Round(projecao_movel, 0) AS projecao_movel,
            Round(meta_movel_qap, 0) AS meta_movel_qap,
            CASE
              WHEN meta_movel_qap > 0 THEN Trunc(((qap_count / meta_movel_qap) * 100), 2)
              ELSE 0
            END AS velocimetro_qap,
            Round(meta_movel_qap, 0) AS meta_movel_qap,
            CASE
              WHEN projecao_movel > 0 THEN Trunc(((full_count / projecao_movel) * 100), 2)
              ELSE 0
            END AS velocimetro
          FROM       (
                    #{inner_query}
                    ) ddddd
      INNER JOIN universities u
      ON         (
      u.id = ddddd.university_id and u.status in ('partner', 'frozen_partnership'))
      ORDER BY   velocimetro DESC;"

    IO.puts query

    {:ok, resultset } = Ppa.RepoQB.query(query)

    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    resultset_map = Enum.map(resultset_map, fn entry ->
      if is_nil(entry["billing_start"]) do
        entry
      else
        entry
        |> Map.put("billing_start", format_local(entry["billing_start"]))
        |> Map.put("billing_start_raw", to_iso_date_format(entry["billing_start"]))
        |> Map.put("qap_enrolled_rate", divide_rate(entry["qap_enrolled_count"], entry["qap_count"]))
      end
    end)

    response_map = %{
      universities: resultset_map,
      editPromisses: false # Enum.member?(["105", "366"], socket.assigns.admin_user_id)
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", response_map)
  end

  def base_query(capture_period_id, levels \\ [], kinds \\ []) do
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)

    levels_where = and_if_not_empty(populate_or_omit_field("l.parent_id", levels))
    kinds_where = and_if_not_empty(populate_or_omit_field("k.parent_id", kinds))

    ubc_levels_where = and_if_not_empty(populate_or_omit_field("ubc.level_id", levels))
    ubc_kinds_where = and_if_not_empty(populate_or_omit_field("ubc.kind_id", kinds))

    Logger.info "base_query# levels_where: #{levels_where}"
    Logger.info "base_query# kinds_where: #{kinds_where}"

    "SELECT
     date(billing_start) AS billing_start,
     dd.university_id,
     k_name,
     l_name,
     round(sazonalidade_qap * qap_projection + (1 - sazonalidade_qap) * base_projection, 0) AS adjusted_projection,
     sazonalidade_qap,
     CASE
      WHEN sazonalidade_qap >= 1 THEN 1
      ELSE 1 / sazonalidade_qap
     END AS fator_ajuste_sazonalidade_promessa,
     promisse,
     fu_data.total_count,
     fu_data.not_qap_count,
     fu_data.qap_count,
     fu_data.enrolled_count,
     fu_data.qap_enrolled_count,
     CASE
      WHEN promisse IS NOT NULL THEN promisse - fu_data.not_qap_count
     END                                 adjusted_promisse,
     sazonalidade_atual.sazonalidade                       AS sazonalidade,
     ( (1 - sazonalidade_qap) * base_projection ) + ( ( sazonalidade_qap * qap_projection ) * ( ( sazonalidade_atual.sazonalidade - ((1 - sazonalidade_qap))) / sazonalidade_qap) ) AS meta_movel,
     ( ( sazonalidade_qap * qap_projection ) * ( ( sazonalidade_atual.sazonalidade - ((1 - sazonalidade_qap))) / sazonalidade_qap) ) AS meta_movel_qap
    FROM      (
   SELECT d.*,
          CASE
        WHEN daily_contribution_qap > 1 THEN 1
        ELSE daily_contribution_qap
          END AS sazonalidade_qap
   FROM   (
            SELECT     ubc.*,
              ubc.created_at         AS billing_start,
              k.NAME        AS k_name,
              l.NAME        AS l_name,
              COALESCE(sp.base_projection, 0)    base_projection,
              COALESCE(sp.qap_projection, 0)     qap_projection,
              sp.promisse,
              sum(dc.daily_contribution) daily_contribution_qap
            FROM       university_billing_configurations ubc
            INNER JOIN kinds k
            ON         (
                k.id = ubc.kind_id)
            INNER JOIN levels l
            ON         (
                l.id = ubc.level_id)
            INNER JOIN daily_contributions dc
            ON         (
                dc.capture_period_id = #{capture_period_id}
              AND product_line_id = case when capture_period_id = 6 then 8 else 1 end
              AND        dc.date >= ubc.created_at)
            LEFT JOIN  students_projections_ex sp
            ON         (
                         sp.active AND sp.capture_period_id = #{capture_period_id}
              AND        sp.university_id = ubc.university_id
              AND        sp.level_id = ubc.level_id
              AND        sp.kind_id = ubc.kind_id)
            WHERE      (ubc.enabled or ubc.enabled_until > '#{to_iso_date_format(capture_period.start)}')
              #{ubc_levels_where}
              #{ubc_kinds_where}
            GROUP BY   ubc.id,
              k.id,
              l.id,
              sp.id ) AS d ) AS dd
    JOIN
     (
   SELECT sum(daily_contribution) sazonalidade
   FROM   daily_contributions
   WHERE  capture_period_id = #{capture_period_id}
          and product_line_id = case when capture_period_id = 6 then 8 else 1 end
   AND    date < now() ) sazonalidade_atual
    ON        (
      true)
    LEFT JOIN
     (
      SELECT    count(fu.id) AS total_count,
       count(
       CASE
        WHEN fu.step = 'enrolled' THEN 1
       END) enrolled_count,
       count(
       CASE
        WHEN fu.created_at >= ubc.created_at and (fu.created_at <= ubc.enabled_until or ubc.enabled_until is null) and fu.step = 'enrolled' THEN 1
       END) qap_enrolled_count,
       count(
       CASE
        WHEN fu.created_at < ubc.created_at or fu.created_at > ubc.enabled_until THEN 1
       END) not_qap_count,
       count(
       CASE
        WHEN fu.created_at >= ubc.created_at and (fu.created_at <= ubc.enabled_until or ubc.enabled_until is null) THEN 1
       END) qap_count,
       ubc.university_id,
       ubc.kind_id,
       ubc.level_id
      FROM      university_billing_configurations ubc
      LEFT JOIN
      (
        select fups.*, l.parent_id as parent_level_id, k.parent_id as parent_kind_id
        from follow_ups fups
        inner join courses c on (c.id = fups.course_id)
        inner join levels l on (l.name = c.level and l.parent_id is not null)
        inner join kinds k on (k.name = c.kind and k.parent_id is not null)
        where
          true
          #{levels_where}
          #{kinds_where}
      ) fu
      ON        (
        fu.university_id = ubc.university_id
       AND       fu.parent_level_id = ubc.level_id
       AND       fu.parent_kind_id = ubc.kind_id
       AND       fu.created_at >= '#{to_iso_date_format(capture_period.start)}')
      WHERE      (ubc.enabled or ubc.enabled_until > '#{to_iso_date_format(capture_period.start)}' )
        #{ubc_levels_where}
        #{ubc_kinds_where}

      GROUP BY  ubc.university_id,
       ubc.level_id,
       ubc.kind_id ) AS fu_data
    ON        (
      fu_data.university_id = dd.university_id
     AND       fu_data.level_id = dd.level_id
     AND       fu_data.kind_id = dd.kind_id)"
  end
end

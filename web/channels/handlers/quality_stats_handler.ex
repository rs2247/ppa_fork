defmodule Ppa.QualityStatsHandler do
  use Ppa.Web, :handler
  require Logger
#  import Ppa.Util.Timex
#  import Ppa.Util.Filters
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.QualityStatsHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> load_data(socket, params) end))

    {:reply, :ok, socket}
  end

  def load_data(socket, _params) do
    # query_tratamento_relacionamento = base_query("Relacionamento", "BOT - Tratamento")
    # { :ok, tratamento_relacionamento } = Ppa.RepoRedmine.query(query_tratamento_relacionamento)
    # tratamento_relacionamento_map = Ppa.Util.Query.resultset_to_map(tratamento_relacionamento)
    #
    # query_tratamento_siteops = base_query("Tabela (SiteOPS)", "BOT - Tratamento")
    # { :ok, tratamento_siteops } = Ppa.RepoRedmine.query(query_tratamento_siteops)
    # tratamento_siteops_map = Ppa.Util.Query.resultset_to_map(tratamento_siteops)
    #
    # query_tratamento_integracao = base_query("Integração", "BOT - Tratamento")
    # { :ok, tratamento_integracao } = Ppa.RepoRedmine.query(query_tratamento_integracao)
    # tratamento_integracao_map = Ppa.Util.Query.resultset_to_map(tratamento_integracao)
    #
    # dates = Enum.map(tratamento_relacionamento_map, fn row ->
    #   to_iso_date_format(row["date_set"])
    # end)
    #
    # tasks_tratamento_relacionamento = Enum.map(tratamento_relacionamento_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # tasks_tratamento_siteops = Enum.map(tratamento_siteops_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # tasks_tratamento_integracao = Enum.map(tratamento_integracao_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    #
    # query_sp_relacionamento = base_query("Relacionamento", "BOT - Secretary Pitch (SP)")
    # { :ok, sp_relacionamento } = Ppa.RepoRedmine.query(query_sp_relacionamento)
    # sp_relacionamento_map = Ppa.Util.Query.resultset_to_map(sp_relacionamento)
    #
    # query_sp_siteops = base_query("Tabela (SiteOPS)", "BOT - Secretary Pitch (SP)")
    # { :ok, sp_siteops } = Ppa.RepoRedmine.query(query_sp_siteops)
    # sp_siteops_map = Ppa.Util.Query.resultset_to_map(sp_siteops)
    #
    # query_sp_integracao = base_query("Integração", "BOT - Secretary Pitch (SP)")
    # { :ok, sp_integracao } = Ppa.RepoRedmine.query(query_sp_integracao)
    # sp_integracao_map = Ppa.Util.Query.resultset_to_map(sp_integracao)
    #
    # tasks_sp_relacionamento = Enum.map(sp_relacionamento_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # tasks_sp_siteops = Enum.map(sp_siteops_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # tasks_sp_integracao = Enum.map(sp_integracao_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # query_tratamento_farmer = "
    # SELECT manual_data.date_set, (manual_data.n_tasks + bot_data.n_tasks) as n_tasks FROM (#{base_query("", "Solicitação de Tratamento")}) manual_data
    # INNER JOIN (#{base_query("", "BOT - Tratamento")}) bot_data on (bot_data.date_set = manual_data.date_set)
    # "
    # { :ok, tratamento_farmer } = Ppa.RepoRedmine.query(query_tratamento_farmer)
    # tratamento_farmer_map = Ppa.Util.Query.resultset_to_map(tratamento_farmer)
    #
    # query_sp_farmer = "
    # SELECT manual_data.date_set, (manual_data.n_tasks + bot_data.n_tasks) as n_tasks FROM (#{base_query("", "Pedido de Secretary Pitch (SP)")}) manual_data
    # INNER JOIN (#{base_query("", "BOT - Secretary Pitch (SP)")}) bot_data on (bot_data.date_set = manual_data.date_set)
    # "
    # { :ok, sp_farmer } = Ppa.RepoRedmine.query(query_sp_farmer)
    # sp_farmer_map = Ppa.Util.Query.resultset_to_map(sp_farmer)
    #
    # tasks_tratamento_farmer = Enum.map(tratamento_farmer_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # tasks_sp_farmer = Enum.map(sp_farmer_map, fn row ->
    #   row["n_tasks"]
    # end)
    #
    # result_map = %{
    #   dates: dates,
    #   tasks_tratamento_relacionamento: tasks_tratamento_relacionamento,
    #   tasks_tratamento_siteops: tasks_tratamento_siteops,
    #   tasks_tratamento_integracao: tasks_tratamento_integracao,
    #   tasks_sp_relacionamento: tasks_sp_relacionamento,
    #   tasks_sp_siteops: tasks_sp_siteops,
    #   tasks_sp_integracao: tasks_sp_integracao,
    #   tasks_tratamento_farmer: tasks_tratamento_farmer,
    #   tasks_sp_farmer: tasks_sp_farmer,
    # }

    result_map = %{}

    Ppa.Endpoint.broadcast(socket.assigns.topic, "chartData", result_map)
  end

  def base_query(task_source, task_type) do
    "select date_set, all_dates.fonte, coalesce(count, 0) n_tasks From (
      select date_set, column1 as fonte from generate_series( (now()::date - interval '10 days')::timestamp, now()::date::timestamp, '1 day'::interval) date_set, ( select * From (values ('#{task_source}') ) d ) fontes ) all_dates
      left join (
      select count(*), tipo_de_task, fonte, date_trunc('day', dt) dt from (
      SELECT
          iss.id,
          trackers.name tipo_de_task,
          cv.value fonte,
          date_trunc('day',iss.created_on) dt
      FROM
          issues iss

      JOIN     trackers
          ON iss.tracker_id = trackers.id
      JOIN
          custom_values cv
             on iss.id = cv.customized_id

      WHERE
          trackers.id IN (63,69,70,71)
             AND cv.custom_field_id = 120) d WHERE tipo_de_task = '#{task_type}' group by tipo_de_task, fonte, dt order by tipo_de_task, dt, fonte

      ) report on (report.dt = all_dates.date_set and report.fonte = all_dates.fonte)"
  end
end

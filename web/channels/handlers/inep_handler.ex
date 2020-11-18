defmodule Ppa.InepHandler do
  use Ppa.Web, :handler
  require Logger
  require Tasks
#  import Ppa.Util.Filters
#  import Math

  def handle_load_entrants(socket, params) do
    Logger.info "Ppa.InepHandler::handle_load_entrants# params: #{inspect params}"
    Tasks.async_handle((fn -> load_entrants(socket, params) end))
    {:reply, :ok, socket}
  end

  def load_entrants(socket, params) do
    university_id = params["university_id"]
    state = params["state"]
    state_where = if not is_nil(state) do
      "AND dm_alunos.ds_uf_curso = '#{state}'"
    else
      ""
    end

    { grouping_field, grouping_field_name, grouping_field_title } = case params["grouping"] do
      "kind" -> { ", dm_alunos.ds_modalidade_ensino", "ds_modalidade_ensino", "Modalidade" }
      "state" -> { ", dm_alunos.ds_uf_curso", "ds_uf_curso", "Estado" }
      _ -> { "", "", "" }
    end

    query = "
    SELECT
     dm_alunos.ano_ingresso,
     COUNT(DISTINCT dm_alunos.co_aluno) AS quantidade
     #{grouping_field}
    FROM
    #{Ppa.AgentDatabaseConfiguration.get_inep_schema()}dm_alunos
    WHERE
     (dm_alunos.ano_ingresso - dm_alunos.ano_inep) = 0
     AND
     dm_alunos.university_id = #{university_id}
     #{state_where}
    GROUP BY
     1
     #{grouping_field}"

     resultset_map = if Ppa.AgentDatabaseConfiguration.get_inep_spark do
       {:ok, resultset} = Ppa.RepoSpark.query(query)
       Ppa.Util.Query.resultset_to_map(resultset)
     else
       {:ok, resultset} = Ppa.RepoPpa.query(query)
       Ppa.Util.Query.resultset_to_map(resultset)
     end

     response_map = %{
       entrants: resultset_map,
       grouping_field_name: grouping_field_name,
       grouping_field_title: grouping_field_title
     }

     Ppa.Endpoint.broadcast(socket.assigns.topic, "inepEntrants", response_map)
  end
end

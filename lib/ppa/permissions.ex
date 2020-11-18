defmodule Ppa.Permissions do
  import Ecto.Query, only: [from: 2]

  def lookup_access(admin_user_id) do
    lookup_query = "
      SELECT
        au.id, count(udo.id), count(uqo.id)
      FROM
        admin_users au
      LEFT JOIN
        university_deal_owners udo
      ON
        (udo.admin_user_id = au.id and udo.end_date is null)
      LEFT JOIN
        university_quality_owners uqo
      ON
        (uqo.admin_user_id = au.id and uqo.end_date is null)
      WHERE
        au.id = #{admin_user_id}
      GROUP BY
        au.id;
    "

    {:ok, lookup_resultset } = Ppa.RepoQB.query(lookup_query)

    data = List.first(lookup_resultset.rows)
    [ _, deal, quality ] = data

    query = from ar in Ppa.AdminRole, where: ar.admin_user_id == ^admin_user_id and ar.role_id in [88, 89]
    managing_permission = Ppa.RepoQB.all(query)

    %{
      manager: not Enum.empty?(managing_permission),
      quality: quality > 0,
      farmer: deal > 0
    }
  end
end

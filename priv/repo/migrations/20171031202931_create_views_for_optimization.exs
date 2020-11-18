defmodule Ppa.Repo.Migrations.CreateViewsForOptimization do
  use Ecto.Migration

  def up do
    execute "DROP MATERIALIZED VIEW IF EXISTS university_deal_owners;"
    execute "DROP MATERIALIZED VIEW IF EXISTS university_quality_owners;"
    execute "DROP MATERIALIZED VIEW IF EXISTS admin_users;"
    execute "DROP MATERIALIZED VIEW IF EXISTS product_lines;"
    execute "DROP MATERIALIZED VIEW IF EXISTS universities;"
    execute "DROP MATERIALIZED VIEW IF EXISTS education_groups;"

    %{database: qb_database, hostname: host, password: pwd } = Ppa.RepoQB.config() |> Enum.into(%{})

    %{username: user, database: db} = Ppa.Repo.config() |> Enum.into(%{})
    execute """
     CREATE MATERIALIZED VIEW university_deal_owners AS
       SELECT *
         FROM dblink('dbname=#{qb_database} user=#{user} password=#{pwd} host=#{host}'::text, 'select id, university_id, admin_user_id, product_line_id, start_date, end_date, accountable, account_type from university_deal_owners')
         AS t1(id integer, university_id integer, admin_user_id integer, product_line_id integer, start_date date, end_date date, accountable boolean, account_type integer);
    """

    execute """
     CREATE MATERIALIZED VIEW university_quality_owners AS
       SELECT *
         FROM dblink('dbname=#{qb_database} user=#{user} password=#{pwd} host=#{host}'::text, 'select id, university_id, admin_user_id, product_line_id, start_date, end_date, accountable, account_type from university_quality_owners')
         AS t1(id integer, university_id integer, admin_user_id integer, product_line_id integer, start_date date, end_date date, accountable boolean, account_type integer);
    """

    execute """
     CREATE MATERIALIZED VIEW admin_users AS
       SELECT *
         FROM dblink('dbname=#{qb_database} user=#{user} password=#{pwd} host=#{host}'::text, 'select id, email from admin_users')
         AS t1(id integer, email text);
    """

    execute """
     CREATE MATERIALIZED VIEW product_lines AS
       SELECT *
         FROM dblink('dbname=#{qb_database} user=#{user} password=#{pwd} host=#{host}'::text, 'select id, name from product_lines')
         AS t1(id integer, name text);
    """

    execute """
     CREATE MATERIALIZED VIEW universities AS
       SELECT *
         FROM dblink('dbname=#{qb_database} user=#{user} password=#{pwd} host=#{host}'::text, 'select id, name, education_group_id, partner_plus, frozen_partnership, partner from universities')
         AS t1(id integer, name text, education_group_id integer, partner_plus boolean, frozen_partnership boolean, partner boolean);
    """

    execute """
     CREATE MATERIALIZED VIEW education_groups AS
       SELECT *
         FROM dblink('dbname=#{qb_database} user=#{user} password=#{pwd} host=#{host}'::text, 'select id, name from education_groups')
         AS t1(id integer, name text);
    """
  end

  def down do
    execute "DROP MATERIALIZED VIEW university_deal_owners;"
    execute "DROP MATERIALIZED VIEW university_quality_owners;"
    execute "DROP MATERIALIZED VIEW admin_users;"
    execute "DROP MATERIALIZED VIEW product_lines;"
    execute "DROP MATERIALIZED VIEW universities;"
    execute "DROP MATERIALIZED VIEW education_groups;"
  end
end

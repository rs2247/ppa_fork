defmodule Ppa.RefundPanelHandler do
  use Ppa.Web, :handler
  require Logger
  import Ppa.Util.Timex
  import Ppa.Util.Filters
  import Ppa.Util.Sql
  require Tasks

  def handle_load_data(socket, params) do
    Logger.info "Ppa.RefundPanelHandler.handle_load_data# params: #{inspect params}"
    Tasks.async_handle((fn -> async_load_data(socket, params) end))
    {:reply, :ok, socket}
  end

  def handle_load_filters(socket) do
    Tasks.async_handle((fn -> load_filters(socket) end))
    {:reply, :ok, socket}
  end

  def async_load_data(socket, params) do
    universities = map_ids(params["universities"])
    group_ids = map_ids(params["groups"])
    groups_ies_ids = groups_ies(group_ids)

    universities = universities ++ groups_ies_ids

    period_where = if is_nil(params["initialDate"]) or is_nil(params["finalDate"]) do
      ""
    else
      { initialDate, finalDate } = Ppa.PanelHandler.load_dates(params)
      "AND ro.created_at BETWEEN '#{to_iso_date_format(initialDate)}' AND '#{to_iso_date_format(finalDate)}'"
    end


    cpf = params["cpf"]
    cpf_where = if !is_nil(cpf) && cpf != "" do
      "AND regexp_replace(ro.cpf, '[^0-9]', '', 'g') = '#{cpf |> String.replace(~r/[^\d]/, "")}'"
    else
      ""
    end

    kinds = map_ids(params["kinds"])
    levels = map_ids(params["levels"])
    status = map_ids(params["status"])
    reasons = map_ids(params["reasons"])

    universities_where = and_if_not_empty(populate_or_omit_field("u.id", universities))
    kinds_where = and_if_not_empty(populate_or_omit_field("parent_k.id", kinds))
    levels_where = and_if_not_empty(populate_or_omit_field("parent_l.id", levels))
    status_where = and_if_not_empty(populate_or_omit_field("ro.status", quotes(status)))
    reasons_where = and_if_not_empty(populate_or_omit_field("ro.reason", quotes(reasons)))

    query = "
    SELECT
      ro.id,
      u.id as university_id,
      u.name as university_name,
      eg.name as education_group,
      ro.status,
      ro.cpf,
      ro.observations,
      c.name as course,
      c.shift as shift,
      parent_l.name as level,
      parent_k.name as kind,
      cps.name as campus,
      date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, ro.created_at))) as creation_date,
      date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, ro.updated_at))) as update_date,
      coalesce(ror.description, ro.reason) as reason,
      deal_owners.account_type as carteira,
      au_udo.email as farmer,
      au_uqo.email as quali,
      date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.created_at))) as order_created,
      date(timezone('America/Sao_Paulo'::text, timezone('UTC'::text, sales.payment_date))) as order_paid,
      round(sales.coupon_price, 2) as coupon_price
     FROM   refund_operations ro
     LEFT JOIN refund_operation_reasons ror
             ON (ror.key = ro.reason)
     INNER JOIN coupons cp on (cp.id = ro.coupon_id)
     INNER JOIN orders o on (o.id = cp.order_id)
     LEFT JOIN sales on (sales.order_id = o.id)

     LEFT join courses c
             ON (c.id = cp.course_id)
     LEFT join campuses cps
             ON (cps.id = c.campus_id)
     LEFT join universities u
             ON (u.id = c.university_id)

     LEFT JOIN education_groups eg
             ON ( eg.id = u.education_group_id )
     LEFT JOIN levels l
             ON ( l.NAME = c.level
                  AND l.parent_id IS NOT NULL )
     LEFT JOIN kinds k
             ON ( k.NAME = c.kind
                  AND k.parent_id IS NOT NULL )
     LEFT JOIN levels parent_l
             ON ( parent_l.id = l.parent_id )
     LEFT JOIN kinds parent_k
             ON ( parent_k.id = k.parent_id )
     LEFT JOIN ( #{owners_product_line("university_deal_owners")} ) deal_owners on (
        deal_owners.university_id = u.id and
        k.parent_id = any(deal_owners.kinds) and
        l.parent_id = any(deal_owners.levels)
      )
    LEFT JOIN ( #{owners_product_line("university_quality_owners")} ) quality_owners on (
       quality_owners.university_id = u.id and
       k.parent_id = any(quality_owners.kinds) and
       l.parent_id = any(quality_owners.levels)
     )
     LEFT JOIN admin_users au_udo ON (au_udo.id = deal_owners.admin_user_id)
     LEFT JOIN admin_users au_uqo ON (au_uqo.id = quality_owners.admin_user_id)
     WHERE
        true
        #{period_where}
        #{universities_where}
        #{status_where}
        #{reasons_where}
        #{kinds_where}
        #{levels_where}
        #{cpf_where}"

    {:ok, resultset} = Ppa.RepoQB.query(query)
    resultset_map = Ppa.Util.Query.resultset_to_map(resultset)

    # Logger.info "resultset_map: #{inspect resultset_map}"

    resultset_response = Enum.map(resultset_map, fn entry ->
      entry
        |> Map.put("order_paid", (if is_nil(entry["order_paid"]), do: "", else: format_local(entry["order_paid"])))
        |> Map.put("order_paid_raw", (if is_nil(entry["order_paid"]), do: "", else: to_iso_date_format(entry["order_paid"])))
        |> Map.put("order_created", format_local(entry["order_created"]))
        |> Map.put("order_created_raw", to_iso_date_format(entry["order_created"]))
        |> Map.put("creation_date", format_local(entry["creation_date"]))
        |> Map.put("creation_date_raw", to_iso_date_format(entry["creation_date"]))
        |> Map.put("update_date", format_local(entry["update_date"]))
        |> Map.put("update_date_raw", to_iso_date_format(entry["update_date"]))
        |> Map.put("farmer", Ppa.AdminUser.pretty_name(entry["farmer"]))
        |> Map.put("quali", Ppa.AdminUser.pretty_name(entry["quali"]))
    end)

    reponse_map = %{
      bos: resultset_response
    }

    Ppa.Endpoint.broadcast(socket.assigns.topic, "tableData", reponse_map)
  end

  def owners_product_line(table) do
    "select #{table}.id, #{table}.admin_user_id, #{table}.university_id, #{table}.account_type, array_agg(distinct pll.level_id) as levels, array_agg(distinct plk.kind_id) as kinds from
        #{table}
        LEFT JOIN product_lines pl
        ON        (pl.id = #{table}.product_line_id)
        LEFT JOIN product_lines_levels pll
        ON        (pll.product_line_id = pl.id)
        LEFT JOIN product_lines_kinds plk
        ON        (plk.product_line_id = pl.id)
        WHERE end_date IS NULL
        GROUP BY  #{table}.id"
  end

  def refund_reasons do
    query = from reason in "refund_operation_reasons",
      select: %{ id: reason.key, name: reason.description },
      order_by: [ desc: reason.id]
    query |> Ppa.RepoQB.all
  end

  def load_filters(socket) do
    filters = [
      %{ name: "Universidade", type: "university"},
    ]

    capture_period_id = socket.assigns.capture_period
    capture_period = Ppa.Repo.get(Ppa.CapturePeriod, capture_period_id)
    filters_map = %{
      kinds: kinds(),
      levels: levels(),
      universities: universities(),
      semester_start: capture_period.start |> Timex.format!("{ISO:Extended:Z}"),
      semester_end: capture_period.end |> Timex.format!("{ISO:Extended:Z}"),
      states: states_options(),
      regions: region_options(),
      groups: map_simple_name(groups()),
      filters: filters,
      status: [
        %{ id: "open", name: "Novo" },
        %{ id: "refund_request_open", name: "No financeiro" },
        %{ id: "no_contact_email", name: "Sem contato" },
        %{ id: "reverted", name: "Revertido" },
        %{ id: "rejected", name: "Rejeitado" },
        %{ id: "canceled", name: "Cancelado" }
      ],
      reasons: refund_reasons(),
    }
    Ppa.Endpoint.broadcast(socket.assigns.topic, "filters", filters_map)
  end
end

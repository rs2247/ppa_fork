defmodule Ppa.Repo.Migrations.CreateDenormalizedViews do
  use Ecto.Migration

  def up do
    %{hostname: host} = Ppa.RepoQB.config() |> Enum.into(%{})
    if host == "localhost" do
      IO.puts("Running from local database... The migration will create the schema")
      create_schema()
    else
      IO.puts("Running in remote database... The schema creation won't be executed")
    end
  end

  defp create_schema do
    execute """
      CREATE MATERIALIZED VIEW sales AS WITH pagos_pagar_me AS (
               SELECT DISTINCT ON (notifications.payment_id) notifications.payment_id,
                  'pagar_me'::text AS psp,
                      CASE
                          WHEN ((notifications.data -> 'transaction'::text) ~~ '%"payment_method"=>"boleto"%'::text) THEN (notifications.updated_at - '1 day'::interval)
                          ELSE notifications.updated_at
                      END AS payment_date,
                  notifications.created_at AS notification_created_at,
                  (("substring"((notifications.data -> 'transaction'::text), '"amount"=>"(.*?)"'::text))::numeric(10,2) / (100)::numeric) AS coupon_price
                 FROM notifications
                WHERE (((notifications.notifier)::text = 'pagar_me'::text) AND ((notifications.data -> 'event'::text) = 'transaction_status_changed'::text) AND ((notifications.data -> 'current_status'::text) = 'paid'::text))
                ORDER BY notifications.payment_id DESC, notifications.id DESC
              ), pagos_adyen AS (
               SELECT DISTINCT ON (notifications.payment_id) notifications.payment_id,
                  'adyen'::text AS psp,
                  COALESCE((((notifications.data -> 'additional_data_boletobancario_payment_date'::text))::timestamp without time zone + ('12:00:00'::time without time zone)::interval), ((notifications.data -> 'event_date'::text))::timestamp without time zone) AS payment_date,
                  notifications.created_at AS notification_created_at,
                  (((notifications.data -> 'value'::text))::numeric(10,2) / (100)::numeric) AS coupon_price
                 FROM notifications
                WHERE (((notifications.data -> 'event_code'::text) = 'AUTHORISATION'::text) AND (((notifications.data -> 'success'::text))::boolean = true) AND ((notifications.notifier)::text = 'adyen'::text))
                ORDER BY notifications.payment_id DESC, notifications.id DESC
              ), pagos_pagseguro AS (
               SELECT payments.id AS payment_id,
                  'pagseguro'::text AS psp,
                  COALESCE(((payments.gateway_response -> 'payment_date'::text))::timestamp without time zone, payments.created_at) AS payment_date,
                  payments.created_at AS notification_created_at,
                  payments.value AS coupon_price
                 FROM payments
                WHERE (((payments.psp)::text = 'pagseguro'::text) AND ((payments.status)::text = ANY (ARRAY[('authorized'::character varying)::text, ('captured'::character varying)::text, ('refunded'::character varying)::text, ('manually_refunded'::character varying)::text])) AND (NOT (((payments.gateway_response -> 'payment_date'::text) IS NULL) AND (payments.created_at < '2012-11-01 00:00:00'::timestamp without time zone))))
              ), pagos AS (
               SELECT pagos_pagar_me.payment_id,
                  pagos_pagar_me.psp,
                  pagos_pagar_me.payment_date,
                  pagos_pagar_me.notification_created_at,
                  pagos_pagar_me.coupon_price
                 FROM pagos_pagar_me
              UNION ALL
               SELECT pagos_adyen.payment_id,
                  pagos_adyen.psp,
                  pagos_adyen.payment_date,
                  pagos_adyen.notification_created_at,
                  pagos_adyen.coupon_price
                 FROM pagos_adyen
              UNION ALL
               SELECT pagos_pagseguro.payment_id,
                  pagos_pagseguro.psp,
                  pagos_pagseguro.payment_date,
                  pagos_pagseguro.notification_created_at,
                  pagos_pagseguro.coupon_price
                 FROM pagos_pagseguro
              ), sales_00 AS (
               SELECT DISTINCT ON (payments.order_id) pagos.payment_id,
                  pagos.psp,
                  pagos.payment_date,
                  pagos.notification_created_at,
                  pagos.coupon_price,
                  payments.order_id,
                  payments.type AS payment_type,
                  payments.cc_type AS payment_cc_type,
                  payments.installments AS payment_installments,
                  coupons.id AS coupon_id,
                  orders.base_user_id,
                  coupons.course_id,
                  courses.campus_id,
                  campuses.university_id,
                  courses.name AS course_name,
                  courses.formatted_name AS course_formatted_name,
                  courses.level AS course_level,
                  courses.kind AS course_kind,
                  courses.shift AS course_shift,
                  coupons.exemption AS course_exemption,
                  campuses.name AS campus_name,
                  campuses.state AS campus_state,
                  campuses.city AS campus_city,
                  universities.name AS university_name,
                  universities.partner_plus AS university_partner_plus,
                  coupons.status AS coupon_status,
                  coupons.created_at AS coupon_created_at,
                  coupons.full_price AS coupon_full_price,
                  coupons.offered_price AS coupon_offered_price,
                  coupons.discount_percentage AS coupon_discount_percentage,
                  coupons.enabled_at AS coupon_enabled_at,
                  base_users.name AS user_name,
                  base_users.cpf AS user_cpf,
                  orders.created_at AS order_created_at,
                  orders.whitelabel_origin
                 FROM (((((((pagos
                   LEFT JOIN payments ON ((pagos.payment_id = payments.id)))
                   LEFT JOIN orders ON ((payments.order_id = orders.id)))
                   LEFT JOIN coupons ON ((payments.order_id = coupons.order_id)))
                   LEFT JOIN base_users ON ((orders.base_user_id = base_users.id)))
                   LEFT JOIN courses ON ((coupons.course_id = courses.id)))
                   LEFT JOIN campuses ON ((courses.campus_id = campuses.id)))
                   LEFT JOIN universities ON ((campuses.university_id = universities.id)))
                ORDER BY payments.order_id, pagos.payment_date DESC
              ), commission_contracts_00 AS (
               SELECT commission_contracts.id,
                  commission_contracts.university_id,
                  commission_contracts.campus_id,
                  commission_contracts.course_kind,
                  commission_contracts.course_level,
                  commission_contracts.start_date,
                  commission_contracts.end_date,
                  commission_contracts.last_invoice_date,
                  commission_contracts.commission_rate,
                  commission_contracts.created_at,
                  commission_contracts.updated_at,
                  ((((commission_contracts.campus_id IS NOT NULL))::integer + (((commission_contracts.course_kind)::text <> ''::text))::integer) + (((commission_contracts.course_level)::text <> ''::text))::integer) AS rules
                 FROM commission_contracts
              ), sales_01 AS (
               SELECT sales_00.payment_id,
                  sales_00.psp,
                  sales_00.payment_date,
                  sales_00.notification_created_at,
                  sales_00.coupon_price,
                  sales_00.order_id,
                  sales_00.payment_type,
                  sales_00.payment_cc_type,
                  sales_00.payment_installments,
                  sales_00.coupon_id,
                  sales_00.base_user_id,
                  sales_00.course_id,
                  sales_00.campus_id,
                  sales_00.university_id,
                  sales_00.course_name,
                  sales_00.course_formatted_name,
                  sales_00.course_level,
                  sales_00.course_kind,
                  sales_00.course_shift,
                  sales_00.course_exemption,
                  sales_00.campus_name,
                  sales_00.campus_state,
                  sales_00.campus_city,
                  sales_00.university_name,
                  sales_00.university_partner_plus,
                  sales_00.coupon_status,
                  sales_00.coupon_created_at,
                  sales_00.coupon_full_price,
                  sales_00.coupon_offered_price,
                  sales_00.coupon_discount_percentage,
                  sales_00.coupon_enabled_at,
                  sales_00.user_name,
                  sales_00.user_cpf,
                  sales_00.order_created_at,
                  sales_00.whitelabel_origin,
                  commission_contracts_00.commission_rate AS commission_contract_rate,
                  commission_contracts_00.id AS commission_contract_id,
                  (commission_contracts_00.commission_rate * (sales_00.coupon_offered_price)::double precision) AS commission_gross_revenue,
                  commission_contracts_00.rules AS commission_contract_rules
                 FROM (sales_00
                   LEFT JOIN commission_contracts_00 ON (((sales_00.university_id = commission_contracts_00.university_id) AND (commission_contracts_00.start_date < sales_00.payment_date) AND ((commission_contracts_00.end_date > sales_00.payment_date) OR (commission_contracts_00.end_date IS NULL)) AND (((commission_contracts_00.course_kind)::text = ''::text) OR ((sales_00.course_kind)::text = (commission_contracts_00.course_kind)::text)) AND ((commission_contracts_00.campus_id IS NULL) OR (sales_00.campus_id = commission_contracts_00.campus_id)) AND (((commission_contracts_00.course_level)::text = ''::text) OR ((sales_00.course_level)::text = (commission_contracts_00.course_level)::text)))))
              ), sales_02 AS (
               SELECT DISTINCT ON (sales_01.payment_id) sales_01.payment_id,
                  sales_01.psp,
                  sales_01.payment_date,
                  sales_01.notification_created_at,
                  sales_01.coupon_price,
                  sales_01.order_id,
                  sales_01.payment_type,
                  sales_01.payment_cc_type,
                  sales_01.payment_installments,
                  sales_01.coupon_id,
                  sales_01.base_user_id,
                  sales_01.course_id,
                  sales_01.campus_id,
                  sales_01.university_id,
                  sales_01.course_name,
                  sales_01.course_formatted_name,
                  sales_01.course_level,
                  sales_01.course_kind,
                  sales_01.course_shift,
                  sales_01.course_exemption,
                  sales_01.campus_name,
                  sales_01.campus_state,
                  sales_01.campus_city,
                  sales_01.university_name,
                  sales_01.university_partner_plus,
                  sales_01.coupon_status,
                  sales_01.coupon_created_at,
                  sales_01.coupon_full_price,
                  sales_01.coupon_offered_price,
                  sales_01.coupon_discount_percentage,
                  sales_01.coupon_enabled_at,
                  sales_01.user_name,
                  sales_01.user_cpf,
                  sales_01.order_created_at,
                  sales_01.whitelabel_origin,
                  sales_01.commission_contract_rate,
                  sales_01.commission_contract_id,
                  sales_01.commission_gross_revenue,
                  sales_01.commission_contract_rules
                 FROM sales_01
                ORDER BY sales_01.payment_id, sales_01.commission_contract_rules DESC
              ), validation_rate_commission_invoices AS (
               SELECT commission_invoices.id,
                  min(commission_contracts.university_id) AS university_id,
                  min(COALESCE(commission_invoices.realized_revenue, commission_invoices.booked_revenue)) AS net_revenue,
                  sum(((sales_02.coupon_offered_price)::double precision * commission_contracts.commission_rate)) AS gross_revenue
                 FROM (((commission_invoices
                   LEFT JOIN commission_contracts ON ((commission_contracts.id = commission_invoices.commission_contract_id)))
                   LEFT JOIN commission_invoices_coupons ON ((commission_invoices_coupons.commission_invoice_id = commission_invoices.id)))
                   LEFT JOIN sales_02 ON ((sales_02.coupon_id = commission_invoices_coupons.coupon_id)))
                GROUP BY commission_invoices.id
              ), validation_rate_commission_contracts AS (
               SELECT commission_contracts.id,
                  min(commission_contracts.university_id) AS university_id,
                  sum(COALESCE(commission_invoices.realized_revenue, commission_invoices.booked_revenue)) AS net_revenue,
                  sum(a.gross_revenue) AS gross_revenue
                 FROM ((commission_contracts
                   LEFT JOIN commission_invoices ON ((commission_contracts.id = commission_invoices.commission_contract_id)))
                   LEFT JOIN ( SELECT commission_contracts_1.id AS commission_contract_id,
                          sum(((b.coupon_offered_price)::double precision * commission_contracts_1.commission_rate)) AS gross_revenue
                         FROM (commission_contracts commission_contracts_1
                           LEFT JOIN ( SELECT DISTINCT ON (commission_invoices_coupons.coupon_id) commission_invoices_coupons.coupon_id,
                                  commission_invoices_1.commission_contract_id,
                                  sales_02.coupon_offered_price
                                 FROM ((commission_invoices_coupons
                                   LEFT JOIN sales_02 ON ((commission_invoices_coupons.coupon_id = sales_02.coupon_id)))
                                   JOIN commission_invoices commission_invoices_1 ON (((commission_invoices_1.id = commission_invoices_coupons.commission_invoice_id) AND ((commission_invoices_1.status)::text <> 'exported'::text))))
                                ORDER BY commission_invoices_coupons.coupon_id, commission_invoices_coupons.id DESC) b ON ((b.commission_contract_id = commission_contracts_1.id)))
                        GROUP BY commission_contracts_1.id) a ON ((a.commission_contract_id = commission_contracts.id)))
                GROUP BY commission_contracts.id
              ), validation_rate_university AS (
               SELECT validation_rate_commission_contracts.university_id AS id,
                  sum(validation_rate_commission_contracts.gross_revenue) AS gross_revenue,
                  sum(validation_rate_commission_contracts.net_revenue) AS net_revenue
                 FROM validation_rate_commission_contracts
                GROUP BY validation_rate_commission_contracts.university_id
              ), validation_rate AS (
               SELECT sum(validation_rate_university.gross_revenue) AS gross_revenue,
                  sum(validation_rate_university.net_revenue) AS net_revenue
                 FROM validation_rate_university
              ), sales_03 AS (
               SELECT sales_02.payment_id,
                  sales_02.psp,
                  sales_02.payment_date,
                  sales_02.notification_created_at,
                  sales_02.coupon_price,
                  sales_02.order_id,
                  sales_02.payment_type,
                  sales_02.payment_cc_type,
                  sales_02.payment_installments,
                  sales_02.coupon_id,
                  sales_02.base_user_id,
                  sales_02.course_id,
                  sales_02.campus_id,
                  sales_02.university_id,
                  sales_02.course_name,
                  sales_02.course_formatted_name,
                  sales_02.course_level,
                  sales_02.course_kind,
                  sales_02.course_shift,
                  sales_02.course_exemption,
                  sales_02.campus_name,
                  sales_02.campus_state,
                  sales_02.campus_city,
                  sales_02.university_name,
                  sales_02.university_partner_plus,
                  sales_02.coupon_status,
                  sales_02.coupon_created_at,
                  sales_02.coupon_full_price,
                  sales_02.coupon_offered_price,
                  sales_02.coupon_discount_percentage,
                  sales_02.coupon_enabled_at,
                  sales_02.user_name,
                  sales_02.user_cpf,
                  sales_02.order_created_at,
                  sales_02.whitelabel_origin,
                  sales_02.commission_contract_rate,
                  sales_02.commission_contract_id,
                  sales_02.commission_gross_revenue,
                  sales_02.commission_contract_rules,
                      CASE
                          WHEN (a.validation_rate IS NOT NULL) THEN (sales_02.commission_gross_revenue * a.validation_rate)
                          WHEN (validation_rate_commission_contracts.gross_revenue IS NOT NULL) THEN ((sales_02.commission_gross_revenue * (validation_rate_commission_contracts.net_revenue)::double precision) / validation_rate_commission_contracts.gross_revenue)
                          WHEN (validation_rate_university.gross_revenue IS NOT NULL) THEN ((sales_02.commission_gross_revenue * (validation_rate_university.net_revenue)::double precision) / validation_rate_university.gross_revenue)
                          ELSE ((sales_02.commission_gross_revenue * (validation_rate.net_revenue)::double precision) / validation_rate.gross_revenue)
                      END AS commission_net_revenue,
                      CASE
                          WHEN (a.validation_rate IS NOT NULL) THEN 'charged'::text
                          ELSE 'theoric'::text
                      END AS commission_status
                 FROM ((((sales_02
                   LEFT JOIN ( SELECT commission_invoices_coupons.coupon_id,
                          sum(((validation_rate_commission_invoices.net_revenue)::double precision / validation_rate_commission_invoices.gross_revenue)) AS validation_rate
                         FROM (commission_invoices_coupons
                           LEFT JOIN validation_rate_commission_invoices ON ((validation_rate_commission_invoices.id = commission_invoices_coupons.commission_invoice_id)))
                        WHERE (validation_rate_commission_invoices.gross_revenue IS NOT NULL)
                        GROUP BY commission_invoices_coupons.coupon_id) a ON ((a.coupon_id = sales_02.coupon_id)))
                   LEFT JOIN validation_rate_commission_contracts ON ((sales_02.commission_contract_id = validation_rate_commission_contracts.id)))
                   LEFT JOIN validation_rate_university ON ((sales_02.university_id = validation_rate_university.id)))
                   LEFT JOIN validation_rate ON (true))
              )
       SELECT sales_03.payment_id,
          sales_03.psp,
          sales_03.payment_date,
          sales_03.notification_created_at,
          sales_03.coupon_price,
          sales_03.order_id,
          sales_03.payment_type,
          sales_03.payment_cc_type,
          sales_03.payment_installments,
          sales_03.coupon_id,
          sales_03.base_user_id,
          sales_03.course_id,
          sales_03.campus_id,
          sales_03.university_id,
          sales_03.course_name,
          sales_03.course_formatted_name,
          sales_03.course_level,
          sales_03.course_kind,
          sales_03.course_shift,
          sales_03.course_exemption,
          sales_03.campus_name,
          sales_03.campus_state,
          sales_03.campus_city,
          sales_03.university_name,
          sales_03.university_partner_plus,
          sales_03.coupon_status,
          sales_03.coupon_created_at,
          sales_03.coupon_full_price,
          sales_03.coupon_offered_price,
          sales_03.coupon_discount_percentage,
          sales_03.coupon_enabled_at,
          sales_03.user_name,
          sales_03.user_cpf,
          sales_03.order_created_at,
          sales_03.whitelabel_origin,
          sales_03.commission_contract_rate,
          sales_03.commission_contract_id,
          sales_03.commission_gross_revenue,
          sales_03.commission_contract_rules,
          sales_03.commission_net_revenue,
          sales_03.commission_status,
          ((sales_03.coupon_price)::double precision + COALESCE(sales_03.commission_net_revenue, (0)::double precision)) AS total_revenue
         FROM sales_03;
    """

    execute """
      CREATE INDEX sales_university_id
        ON sales (university_id);
    """

    execute """
      CREATE INDEX sales_course_level
        ON sales (course_level);
    """

    execute """
      CREATE INDEX sales_course_kind
        ON sales (course_kind);
    """

    execute """
      CREATE INDEX sales_order_created_at
        ON sales (order_created_at);
    """

    execute """
      CREATE INDEX sales_whitelabel_origin
        ON sales (whitelabel_origin);
    """

    execute "create schema if not exists denormalized_views"
    execute """
      create table if not exists denormalized_views.consolidated_visits
      (
        visited_at date,
        university_id integer,
        whitelabel_origin varchar,
        level_id integer,
        kind_id integer,
        visits integer
      );
    """

    execute "create index if not exists consolidated_visits_visited_at  on denormalized_views.consolidated_visits (visited_at);"
    execute "create index if not exists consolidated_visits_university_id  on denormalized_views.consolidated_visits (university_id);"
    execute "create index if not exists consolidated_visits_whitelabel_origin  on denormalized_views.consolidated_visits (whitelabel_origin);"
    execute "create index if not exists consolidated_visits_level_id  on denormalized_views.consolidated_visits (level_id);"
    execute "create index if not exists consolidated_visits_kind_id  on denormalized_views.consolidated_visits (kind_id);"

    execute """
      CREATE MATERIALIZED VIEW if not exists denormalized_views.consolidated_orders AS WITH filtered_orders AS (
        SELECT o.id AS order_id,
          (timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.created_at)))::date AS created_at,
          o.base_user_id,
          o.checkout_step,
          o.id AS offer_id,
          c.university_id,
          c.id AS course_id,
          l.parent_id AS level_id,
          k.parent_id AS kind_id,
          li.price,
          coupon.status,
          coupon.disablement_reason,
              CASE
                  WHEN ((btrim((o.whitelabel_origin)::text) = ''::text) OR (o.whitelabel_origin IS NULL)) THEN 'quero_bolsa'::character varying
                  ELSE o.whitelabel_origin
              END AS whitelabel_origin
          FROM ((((((orders o
            JOIN line_items li ON ((li.order_id = o.id)))
            JOIN offers offer ON ((offer.id = li.offer_id)))
            JOIN courses c ON ((c.id = offer.course_id)))
            JOIN levels l ON ((((l.name)::text = (c.level)::text) AND (l.parent_id IS NOT NULL))))
            JOIN kinds k ON ((((k.name)::text = (c.kind)::text) AND (k.parent_id IS NOT NULL))))
            LEFT JOIN coupons coupon ON ((coupon.order_id = o.id)))
        WHERE ((o.base_user_id IS NOT NULL) AND ((timezone('America/Sao_Paulo'::text, timezone('UTC'::text, o.created_at)))::date >= '2015-10-01'::date) AND ((o.price > (0)::numeric) OR ((o.checkout_step)::text <> 'paid'::text)))
      ), refunded_orders AS (
        SELECT DISTINCT coupons.order_id
           FROM coupons
          WHERE ((coupons.disablement_reason)::text = ANY ((ARRAY['refund'::character varying, 'manual_refund'::character varying])::text[]))
        UNION
        SELECT DISTINCT c.order_id
         FROM ((coupons c
        JOIN refund_requests r ON ((r.coupon_id = c.id)))
        JOIN orders o ON ((c.order_id = o.id)))
        WHERE (((r.status)::text = 'finalized'::text) AND (o.refunded_at IS NOT NULL) AND (o.paid_at IS NULL))
      )
      SELECT filtered_orders.created_at,
      filtered_orders.university_id,
      filtered_orders.whitelabel_origin,
      filtered_orders.level_id,
      filtered_orders.kind_id,
      (count(DISTINCT filtered_orders.base_user_id))::integer AS initiated_orders,
      (count(DISTINCT
          CASE
              WHEN ((filtered_orders.checkout_step)::text <> 'initiated'::text) THEN filtered_orders.base_user_id
              ELSE NULL::integer
          END))::integer AS registered_orders,
      (count(DISTINCT
          CASE
              WHEN ((filtered_orders.checkout_step)::text = ANY ((ARRAY['commited'::character varying, 'paid'::character varying])::text[])) THEN filtered_orders.base_user_id
              ELSE NULL::integer
          END))::integer AS commited_orders,
      (count(DISTINCT
          CASE
              WHEN ((filtered_orders.checkout_step)::text = 'paid'::text) THEN filtered_orders.base_user_id
              ELSE NULL::integer
          END))::integer AS paid_orders,
      (count(DISTINCT
          CASE
              WHEN (refunded_orders.order_id IS NOT NULL) THEN filtered_orders.base_user_id
              ELSE NULL::integer
          END))::integer AS refunded_orders,
      COALESCE(avg(
          CASE
              WHEN ((filtered_orders.checkout_step)::text = 'paid'::text) THEN filtered_orders.price
              ELSE NULL::numeric
          END), 0.0) AS average_ticket,
      COALESCE(sum(
          CASE
              WHEN ((filtered_orders.checkout_step)::text = 'paid'::text) THEN filtered_orders.price
              ELSE NULL::numeric
          END), 0.0) AS total_revenue,
      COALESCE(sum(
          CASE
              WHEN (refunded_orders.order_id IS NOT NULL) THEN filtered_orders.price
              ELSE NULL::numeric
          END), 0.0) AS total_refunded
      FROM (filtered_orders
        LEFT JOIN refunded_orders ON ((filtered_orders.order_id = refunded_orders.order_id)))
      GROUP BY filtered_orders.created_at, filtered_orders.university_id, CUBE(filtered_orders.whitelabel_origin, filtered_orders.level_id, filtered_orders.kind_id);
    """

    execute """
    create or replace function denormalized_views.fnu_calculate_consolidated_visits(rebuild boolean) returns character
    language plpgsql
    as $$
    DECLARE
        start_date date;
        end_date date;
      BEGIN

        IF rebuild is true THEN
          DELETE FROM denormalized_views.consolidated_visits;
          start_date = '2015-10-01'::date;
        ELSE
          start_date = ((select max(visited_at) from denormalized_views.consolidated_visits) + interval '1 day');
        END IF;

        end_date = now()::date - interval '1 day';

        insert into denormalized_views.consolidated_visits (visited_at,university_id,whitelabel_origin,level_id,kind_id,visits)
          with
          -- filtrando as visitas por data
          filtered_visits as (
            select
              id
              ,((visited_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Sao_Paulo')::date visited_at
              ,base_user_id
              ,visitable_id
              ,visitable_type
              ,case when trim(whitelabel_origin) = '' or whitelabel_origin is null then 'quero_bolsa' else whitelabel_origin end whitelabel_origin
            from
              public.visits
            where
              base_user_id is not null
              -- to be used with create table or create materialized view
              --and ((visited_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Sao_Paulo')::date >= '2015-10-01'

              -- to be used with insert
              and ((visited_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Sao_Paulo')::date BETWEEN
                start_date
                and
                end_date

          )
          , uv as (
            --visitas em universidade
            select distinct
              fv.visited_at
              ,fv.base_user_id
              ,fv.visitable_id university_id
              ,0 level_id
              ,0 kind_id
              ,fv.whitelabel_origin
            from
              filtered_visits fv
              join public.universities u on visitable_type = 'University' and u.id = fv.visitable_id
            union
            --visitas em cursos
            select distinct
              fv.visited_at
              ,fv.base_user_id
              ,c.university_id
              ,l.parent_id level_id
              ,k.parent_id kind_id
              ,fv.whitelabel_origin
            from
              filtered_visits fv
              join public.courses c on fv.visitable_type = 'Course' and fv.visitable_id = c.id
              join public.levels l on l.name = c.level and l.parent_id is not null
              join public.kinds k on k.name = c.kind and k.parent_id is not null
            union
            --visitas em ofertas
            select distinct
              fv.visited_at
              ,fv.base_user_id
              ,c.university_id
              ,coalesce(l.parent_id,l.id) level_id
              ,coalesce(k.parent_id,k.id) kind_id
              ,fv.whitelabel_origin
            from
              filtered_visits fv
              join public.offers o on fv.visitable_type = 'Offer' and fv.visitable_id = o.id
              join public.courses c on c.id = o.course_id
              join public.levels l on l.name = c.level and l.parent_id is not null
              join public.kinds k on k.name = c.kind and k.parent_id is not null
          )
          --contagem de visitas
          ,visits_count as(
            select
              visited_at,university_id,uv.whitelabel_origin,level_id,kind_id,count(distinct base_user_id)::integer visits
            from
              uv
              join public.base_users bu on bu.id = uv.base_user_id
            group by
              visited_at,university_id,CUBE(uv.whitelabel_origin,level_id,kind_id)
          order by
            1,2,3,4,5,6
          )
          select
            *
          from
            visits_count
          where
            coalesce(kind_id,-1) <> 0
            and coalesce(level_id,-1) <> 0;

          RETURN 't';
      END
      $$
    """

    execute "select * from denormalized_views.fnu_calculate_consolidated_visits(true);"
  end

  def down do
    %{hostname: host} = Ppa.RepoQB.config() |> Enum.into(%{})
    if host == "localhost" do
      IO.puts("Running from local database... The migration will drop the schema")
      drop_schema()
    else
      IO.puts("Running in remote database... The schema removal won't be executed")
    end
  end

  defp drop_schema do
    execute "drop schema denormalized_views CASCADE"
  end
end

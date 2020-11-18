DISCARD TEMP;


-- pagos_pagar_me
-- lista todos os pagamentos recebidos pelo pagar_me
create temp table pagos_pagar_me as
select
    distinct on (payment_id)
    payment_id,
    'pagar_me'::text as psp,
    case when  ((substring(data->'transaction' from '\{(.*?)\}'))::hstore->'payment_method')::text = 'boleto' then updated_at - INTERVAL '1 day' else updated_at end as payment_date,
    created_at as notification_created_at,
    (((substring(data->'transaction' from '\{(.*?)\}'))::hstore->'amount')::numeric(10,2) / 100) as coupon_price
from
    notifications
where
        notifier = 'pagar_me'
        and data->'event' = 'transaction_status_changed'
        and data->'current_status' = 'paid'
order by
    payment_id desc,
    id desc;

-- pagos_adyen
-- lista todos os pagamentos recebidos pela adyen
create temp table pagos_adyen as
select
    distinct on (payment_id)
    payment_id,
    'adyen'::text as psp,
    coalesce((data -> 'additional_data_boletobancario_payment_date')::timestamp + time '12:00' , (data -> 'event_date')::timestamp) as payment_date,
    created_at as notification_created_at,
    ((data -> 'value')::numeric(10,2) / 100) as coupon_price
from
    notifications
where
    (data -> 'event_code')::text = 'AUTHORISATION'
    and
    (data -> 'success')::boolean = true
    and
        notifier = 'adyen'
order by
    payment_id desc,
    id desc;


-- pagos_pagseguro
-- lista todos os pagamentos recebidos pelo pagseguro
create temp table pagos_pagseguro as
select
    id as payment_id,
    'pagseguro'::text as psp,
    coalesce((gateway_response -> 'payment_date')::timestamp, created_at) as payment_date,
    created_at as notification_created_at,
    value as coupon_price 
from
    payments
where
    psp = 'pagseguro'
    and
        status in ('authorized', 'captured', 'refunded', 'manually_refunded')
    and
    not ((gateway_response->'payment_date') is null and created_at < '2012-11-01');


-- pagos
-- consolida lista de pagamentos
create temp table pagos as
select * from pagos_pagar_me
union all
select * from pagos_adyen
union all
select * from pagos_pagseguro;


-- sales_00
-- lista completa de cupons pagos
create temp table sales_00 as
select 
    distinct on (payments.order_id)
    pagos.*,
    payments.order_id,
    payments.type as payment_type,
    payments.cc_type as payment_cc_type,
    payments.installments as payment_installments,
    coupons.id as coupon_id,
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
    base_users.cpf AS user_cpf
from
    pagos
    left join payments on pagos.payment_id = payments.id
    left join orders on payments.order_id = orders.id
    left join coupons on payments.order_id = coupons.order_id
    left join base_users on orders.base_user_id = base_users.id
    left join courses on coupons.course_id = courses.id
    left join campuses on courses.campus_id = campuses.id
    left join universities on campuses.university_id = universities.id
order by
    payments.order_id,
    pagos.payment_date desc;

-- commission_contracts_00
-- count the number of rules on commission_contracts for when selecting the correct one
create temp table commission_contracts_00 as
select
    *,
    (campus_id is not null)::integer + (course_kind <> '')::integer + (course_level <> '')::integer as rules
from
    commission_contracts;


-- sales_01
-- find possible commission_contracts per payment
create temp table sales_01 as
select 
    sales_00.*,
        commission_contracts_00.commission_rate as commission_contract_rate,
        commission_contracts_00.id AS commission_contract_id,
        commission_contracts_00.commission_rate * sales_00.coupon_offered_price AS commission_gross_revenue,
        commission_contracts_00.rules as commission_contract_rules
from
    (sales_00
    left join commission_contracts_00 ON (((sales_00.university_id = commission_contracts_00.university_id)
        and (commission_contracts_00.start_date < sales_00.payment_date)
        and ((commission_contracts_00.end_date > sales_00.payment_date)
        or (commission_contracts_00.end_date is null))
        and ((commission_contracts_00.course_kind = '')
        or (sales_00.course_kind = commission_contracts_00.course_kind))
        and ((commission_contracts_00.campus_id is null)
        or (sales_00.campus_id = commission_contracts_00.campus_id))
        and ((commission_contracts_00.course_level = '')
        or (sales_00.course_level = commission_contracts_00.course_level)))));


-- sales_02
-- filter commission_contract for the one with more detailed rules
create temp table sales_02 as
select 
    distinct on (sales_01.payment_id)
    sales_01.*
from
    sales_01
order by 
    sales_01.payment_id,
    sales_01.commission_contract_rules desc;




-- validation_rate_commission_invoices
-- average validation_rate per commission_commission
create temp table validation_rate_commission_invoices as
select
    commission_invoices.id,
    min(commission_contracts.university_id) as university_id,
    min(coalesce(commission_invoices.realized_revenue, commission_invoices.booked_revenue)) as net_revenue,
    sum(sales_02.coupon_offered_price * commission_contracts.commission_rate) as gross_revenue
from
    commission_invoices
    left join commission_contracts on (commission_contracts.id = commission_invoices.commission_contract_id)
    left join commission_invoices_coupons on (commission_invoices_coupons.commission_invoice_id = commission_invoices.id)
    left join sales_02 on (sales_02.coupon_id = commission_invoices_coupons.coupon_id)
group by
    commission_invoices.id;

    


-- validation_rate_commission_contracts
-- average validation_rate per contract
create temp table validation_rate_commission_contracts as
select
    commission_contracts.id,
    min(commission_contracts.university_id) as university_id,
    sum(coalesce(commission_invoices.realized_revenue, commission_invoices.booked_revenue)) as net_revenue,
    sum(a.gross_revenue) as gross_revenue
from
    commission_contracts
    left join commission_invoices on (commission_contracts.id = commission_invoices.commission_contract_id)
    left join (
        select
            commission_contracts.id as commission_contract_id,
            sum(b.coupon_offered_price * commission_contracts.commission_rate) as gross_revenue
        from
            commission_contracts
            left join (
                select
                    distinct on (commission_invoices_coupons.coupon_id)
                    commission_invoices_coupons.coupon_id,
                    commission_invoices.commission_contract_id,
                    sales_02.coupon_offered_price
                from
                    commission_invoices_coupons
                    left join sales_02 on (commission_invoices_coupons.coupon_id = sales_02.coupon_id)
                    inner join commission_invoices on (commission_invoices.id = commission_invoices_coupons.commission_invoice_id and commission_invoices.status <> 'exported')
                order by
                    commission_invoices_coupons.coupon_id,
                    commission_invoices_coupons.id desc
                ) b on (b.commission_contract_id = commission_contracts.id)
        group by
            commission_contracts.id
        ) a on (a.commission_contract_id = commission_contracts.id)
group by
    commission_contracts.id;



-- validation_rate_university
-- average validation_rate per university
create temp table validation_rate_university as
select
    validation_rate_commission_contracts.university_id as id,
    sum(validation_rate_commission_contracts.gross_revenue) as gross_revenue,
    sum(validation_rate_commission_contracts.net_revenue) as net_revenue
from
    validation_rate_commission_contracts
group by
    validation_rate_commission_contracts.university_id;



-- validation_rate_total
-- average validation_rate
create temp table validation_rate as
select 
    sum(validation_rate_university.gross_revenue) as gross_revenue,
    sum(validation_rate_university.net_revenue) as net_revenue
from
    validation_rate_university;



-- sales_03
-- base de sales com valores de commissione calculados
create temp table sales_03 as
select
    sales_02.*,
    CASE    WHEN a.validation_rate is not null THEN sales_02.commission_gross_revenue * a.validation_rate
        WHEN validation_rate_commission_contracts.gross_revenue is not null THEN sales_02.commission_gross_revenue * validation_rate_commission_contracts.net_revenue / validation_rate_commission_contracts.gross_revenue
        WHEN validation_rate_university.gross_revenue is not null THEN sales_02.commission_gross_revenue * validation_rate_university.net_revenue / validation_rate_university.gross_revenue
        ELSE sales_02.commission_gross_revenue * validation_rate.net_revenue / validation_rate.gross_revenue
        END as commission_net_revenue,
        CASE    WHEN a.validation_rate is not null THEN 'charged'
        ELSE 'theoric'
        END as commission_status
from
    sales_02
    left join (
            select
                commission_invoices_coupons.coupon_id,
                sum(validation_rate_commission_invoices.net_revenue / validation_rate_commission_invoices.gross_revenue) as validation_rate
            from
                commission_invoices_coupons
                left join validation_rate_commission_invoices on (validation_rate_commission_invoices.id = commission_invoices_coupons.commission_invoice_id)
            where
                validation_rate_commission_invoices.gross_revenue is not null
            group by
                commission_invoices_coupons.coupon_id
        ) a on (a.coupon_id = sales_02.coupon_id)
    left join validation_rate_commission_contracts on sales_02.commission_contract_id = validation_rate_commission_contracts.id
    left join validation_rate_university on sales_02.university_id = validation_rate_university.id
    left join validation_rate on true;



-- sales_03
-- base final de sales
drop table if exists sales;
create table sales as
select
    sales_03.*,
    sales_03.coupon_price + coalesce(sales_03.commission_net_revenue, 0) as total_revenue
from
    sales_03;
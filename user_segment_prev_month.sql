with base as (
select *,
    m*x + b as exp_y,
    abs(m*x + b - y) as var_y
from (
    select 
        *,
        regr_intercept(y,x) over(partition by employee_id) as b,
        regr_slope(y,x) over(partition by employee_id) as m
    from (
        select 
            employee_id,
            row_number() over(partition by employee_id order by completed_at) as x, 
            extract(epoch from completed_at)::float/86400.0 as y
        from table_name
        ) z
    ) zz
) 

, regularity  as (
select 
    employee_id,
    sum(var_y)/count(*) as regularity_score 
from base 
group by 1
) 

, frequency as (
select
    employee_id, 
    m as frequency_score
from base 
group by 1,2
)

, active_last_month as (
select 
    employee_id, 
    count(distinct x_id) as x_activity
from table_name
where completed_at >= date_trunc('month', now() - interval '1 month')
and completed_at < date_Trunc('month', now())
group by 1
)

, final as (
select 
    concat(regular, ' ', frequent) as grouping, 
    *
from (
select 
        regularity.employee_id as employee_id, 
        case when  regularity_score < 5 then 'Regular' else 'Irregular' end as regular, --#handpicked cutoffs 
        case when frequency_score <= 7 then 'High' else 'Low' end as frequent, 
        1 as fake
    from regularity  
    join frequency 
    using (employee_id)
    join transfer_lifetime
    on regularity.employee_id = transfer_lifetime.employee_id
    join active_last_month
    on regularity.employee_id = active_last_month.employee_id
    ) a
) 


select 
    *, 
    activity_total::float/employees as avg_activity_per_employee
from (
    select 
        grouping,
        sum(net_amount::float/100) as transfer_amount, 
        count(distinct employee_id) as employees, 
        sum(x_activity) activity_total 
    from final 
    join active_last_month 
    using (employee_id)
    group by 1
) a
order by 1

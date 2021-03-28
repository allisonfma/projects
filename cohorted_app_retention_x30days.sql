with app_visits as (
select
    employee_id as user_id,
    day
from dau_rollup --
join employees using (employee_id)
left join companies using(company_id)
and day >= '2018-01-01'
) 

, first_app_visit as (
select 
    user_id,
    min(day) as first_visit
from app_visits
group by 1
having min(day) < date_trunc('day', now() - interval '210')
)

--figure out end (disabled_at) day then add to first visit
, enrollment_stages as (
select
    first_app_visit.*,
    date_trunc('quarter', first_visit) as cohort,
    disabled_at
from(
    select
        employee_id as user_id,
        min(created_at) as disabled_at
    from employee_enrollment_history
    where state = 'DISABLED'
    group by 1
) a
right join first_app_visit on a.user_id = first_app_visit.user_id
where (disabled_at >= first_visit or disabled_at is null)
)


, denominator_enrollment as (
select
    *,
    generate_series(0, max_days::int, 30) as days_30
from(
    select
    --create max days to make sure only people counted in denominator have had the chance to be enrolled for at least x days
        user_id,
        first_visit,
        cohort,
        floor((EXTRACT(epoch from age(date_Trunc('day', now()), first_visit)) / 86400)/30.0)*30 as max_days
    from enrollment_stages
  ) a
)


, numerator_appvisits as (
select
    (EXTRACT(epoch from age(day, first_visit)) / 86400)::int as days_since_enrolled,
    floor((EXTRACT(epoch from age(day, first_visit)) / 86400)/30.0)*30 as days_30_since_enrolled, 
    *
from app_visits 
join enrollment_stages using (user_id)
)

select 
  * 
from (
  select
      a.cohort,
      days_30,
      count(distinct a.user_id) as enrolled_users,
      count(distinct b.user_id) as app_visiting_users,
      count(distinct b.user_id)::float/count(distinct a.user_id) as percent_visiting_app,
      row_number() over (partition by a.cohort order by days_30 desc) as rn
  from denominator_enrollment a
  left join numerator_appvisits b
  on a.user_id = b.user_id
  and days_30::int = days_30_since_enrolled::int
  group by 1,2
  ) a 
where rn > 2
and enrolled_users > 500


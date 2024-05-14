-- 1. How many customers has Foodie-Fi ever had?

select count(distinct customer_id) from subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select 
month(start_date) as Month,
monthname(start_date) as Month_Name,
count(*) as Trial_plan 
from subscriptions s left join plans p
on s.plan_id=p.plan_id
where p.plan_name='trial'
group by 1,2
order by 1 asc;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select
p.plan_name,
count(*) plans
from plans p left join subscriptions s
on p.plan_id=s.plan_id
where start_date>='2021-01-01'
group by 1;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select 
count(*) total_churn,
round(count(*)/(select count(distinct customer_id) from subscriptions)*100,1) as churn_percantage
from subscriptions
where plan_id=4;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to 1 decimal place?

with ranked as (SELECT s.customer_id, s.plan_id, p.plan_name,
  ROW_NUMBER() OVER (
    PARTITION BY s.customer_id 
    ORDER BY s.plan_id) AS plan_rank 
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id)
select
sum(case when plan_id=4 then 1 else 0 end) churn_customers,
round(100*sum(case when plan_id=4 then 1 else 0 end)/count(*),2) churn_percantage
from ranked
where plan_rank=2;

-- 6. What is the number and percentage of customer plans after their initial free trial?

with next_plan_cte as (SELECT customer_id, plan_id, 
  LEAD(plan_id, 1) OVER(
    PARTITION BY customer_id 
    ORDER BY plan_id) as next_plan
FROM subscriptions)
select next_plan,count(*) conversions,
      round(100*count(*)/(select count(distinct customer_id) from subscriptions),1) as conversion_percantage
      from next_plan_cte
      where next_plan is not null and plan_id=0
      group by next_plan
      order by next_plan;
      
-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with next_plan  as (SELECT customer_id, plan_id, start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31'),
customer_breakdown as (select plan_id,
count(distinct customer_id) as customers from next_plan
WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
      OR (next_date IS NULL AND start_date < '2020-12-31')
group by plan_id)
select plan_id,customers,
       round(100*customers/(select count(distinct customer_id) from subscriptions),1) as customer_percantage
       from customer_breakdown group by 1,2;

-- 8.How many customers have upgraded to an annual plan in 2020?

select 
      count(s.customer_id)
      from subscriptions s left join plans p
      on s.plan_id=p.plan_id
      where p.plan_id=3 and start_date between '2020-01-01' and '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH trial_plan AS (SELECT customer_id, start_date AS start
FROM foodie_fi.subscriptions
WHERE plan_id = 0),annual_plan AS
(SELECT customer_id, start_date AS start
FROM foodie_fi.subscriptions
WHERE plan_id = 3)
SELECT 
round(avg(datediff(ap.start,tp.start)),2) AS avg_days_to_upgrad
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id;
  
-- 10.Can you further breakdown this averagevalue into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH annual_plan AS (SELECT customer_id, start_date AS annual_date 
    FROM subscriptions WHERE plan_id = 3), 
trial_plan AS (SELECT customer_id, start_date AS trial_date 
    FROM subscriptions WHERE plan_id = 0), 
day_period AS (SELECT DATEDIFF(annual_date, trial_date) AS diff 
    FROM trial_plan tp 
    LEFT JOIN annual_plan ap ON tp.customer_id = ap.customer_id WHERE annual_date IS NOT NULL), 
bins AS (SELECT *, FLOOR(diff/30) AS bins 
    FROM day_period)
SELECT CONCAT((bins*30)+1, '-', (bins+1)*30, 'days') AS days, COUNT(diff) AS Count_of_Customer
FROM bins GROUP BY bins;




-- 11.How many customers downgradedfrom a pro monthly to a basic monthly plan in 2020?
WITH next_plan_cte AS (
    SELECT 
        customer_id,
        plan_id,
        start_date,
        LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan 
    FROM subscriptions
)  
SELECT COUNT(*) AS downgraded 
FROM next_plan_cte 
WHERE start_date <= '2020-12-31'  
AND plan_id = 2 
AND next_plan = 1;
      
      
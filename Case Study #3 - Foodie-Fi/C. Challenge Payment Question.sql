SET search_path = 'foodie_fi'


-------------------------------------------------------------- C. Challenge Payment Question -------------------------------------------------------------

-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments


WITH CTE as(
SELECT customer_id, ss.plan_id, start_date, plan_name, price,
	LEAD(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date) AS lead_date,
	LEAD(ss.plan_id,1) OVER(PARTITION BY customer_id ORDER BY start_date) AS lead_id
FROM subscriptions ss
	JOIN plans pp
	ON ss.plan_id = pp.plan_id
WHERE pp.plan_id <> 0),
final_date as (
SELECT *, 
		CASE WHEN plan_id IN (1,2) AND lead_id is null THEN '2020-12-31'
			 WHEN plan_id IN (1,2) AND lead_id IN (3,4) THEN lead_date
			 ELSE start_date END as end_date
FROM CTE
WHERE plan_id <> 4),
generating_time_series as (
SELECT customer_id,
		plan_id,
		plan_name,
		price,
		generate_series(start_date, end_date, '1 month') :: date AS payment_date
from final_date)
SELECT *,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY payment_date)
FROM generating_time_series


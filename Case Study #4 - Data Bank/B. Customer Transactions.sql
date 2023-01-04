
------------------------------------------------------------------ B. Customer Transactions -------------------------------------------------------------


--1: What is the unique count and total amount for each transaction type?
SELECT txn_type,
		SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

--2: What is the average total historical deposit counts and amounts for all customers?
SELECT customer_id,
		ROUND(AVG(txn_amount),1) AS avg_amount,
		SUM(txn_amount) AS total_amount,
		COUNT(txn_amount) AS cnt
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id;
		
--3: For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_count AS
(SELECT DATE_PART('month', txn_date) AS month_,
		COUNT(customer_id) as cnt
FROM customer_transactions
GROUP BY month_, customer_id
HAVING COUNT(customer_id) > 1)
SELECT month_,
		SUM(cnt) AS customer_count
FROM monthly_count
GROUP BY month_
ORDER BY month_;

--4: What is the closing balance for each customer at the end of the month?
SELECT customer_id,
		DATE_PART('month', txn_date) AS month_,
		SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN -txn_amount
				 ELSE txn_amount END ) AS closing_blance
FROM customer_transactions
GROUP BY customer_id, month_
ORDER BY customer_id;


--5: What is the percentage of customers who increase their closing balance by more than 5%?
WITH first_txn AS 
(SELECT customer_id,
		SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN -txn_amount
				 ELSE txn_amount END ) AS closing_blance,
		MIN(txn_date) AS first_txn_date,
		MAX(txn_date) AS last_txn_txn
FROM customer_transactions
GROUP BY customer_id
ORDER BY customer_id),
five_percent as(
SELECT ft.customer_id,
		ft.first_txn_date,
		ft.closing_blance,
		((ct.txn_amount*0.05) + ct.txn_amount) as percent_increase
FROM first_txn ft
	JOIN customer_transactions ct
	ON ft.first_txn_date = ct.txn_date
	AND ft.customer_id = ct.customer_id
)
SELECT ROUND((COUNT(*)*100/(SELECT COUNT(DISTINCT customer_id) FROM customer_transactions)::decimal),1) AS increase_five_percent
FROM five_percent
WHERE percent_increase > closing_blance;





 --1: How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;


--2: What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT TO_CHAR(start_date, 'month') AS month_, 
		COUNT(plan_id) as subs_number
FROM subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 2 DESC


--3: What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
Select sub.plan_id,
		p.plan_name,
		COUNT(*) AS sub_number
FROM subscriptions sub
	JOIN plans p
	ON p.plan_id = sub.plan_id
WHERE sub.start_date >= '2021-01-01'
GROUP BY 1,2
ORDER BY 1


--4: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(customer_id) AS churn_number,
		round((COUNT(DISTINCT customer_id)/(SELECT COUNT(DISTINCT customer_id)*1.0 AS total FROM subscriptions)) * 100, 1) AS churn_percent
FROM Subscriptions
WHERE plan_id = 4


--5: How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT COUNT(DISTINCT customer_id) AS churn_number,
		round(COUNT(DISTINCT customer_id)/(SELECT COUNT(DISTINCT customer_id)*1.0 AS total FROM subscriptions) * 100,0) AS churn_percent
FROM Subscriptions
WHERE customer_id NOT IN(
	SELECT customer_id
	FROM subscriptions
	WHERE plan_id IN (1,2,3))

	
	
-- window function
WITH CTE AS (
SELECT customer_id,
	start_date,
	plan_id AS current_plan,
	LAG(plan_id,1) OVER(PARTITION BY customer_id ORDER BY start_date) as prev_plan
FROM subscriptions)
SELECT count(*) AS churn_number,
		round(COUNT(*)/(SELECT COUNT(DISTINCT customer_id)*1.0 AS total FROM subscriptions) * 100,0) AS churn_percent
FROM cte
WHERE prev_plan = 0 AND current_plan = 4;

--6: What is the number and percentage of customer plans after their initial free trial?
WITH CTE AS(
	SELECT customer_id,
			start_date,
			plan_id,
			lag(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) AS lag_plan
	FROM subscriptions)
SELECT plan_id, COUNT(*) AS sub_after_trail,
		round(COUNT(*)/(SELECT COUNT(DISTINCT customer_id)*1.0 AS total FROM subscriptions) * 100,2) AS after_trail_percent
FROM CTE 
WHERE lag_plan = 0 AND plan_id is not null
GROUP BY plan_id;



--7: What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH(
	SELECT plan_id, COUNT(*) AS CNT
	FROM subscriptions
	WHERE start_date <= '2020-12-31'
	GROUP BY plan_id)
SELECT plan_id, 


--8: How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) as annual
FROM subscriptions
WHERE plan_id = 3
	AND start_date BETWEEN '2020-01-01' AND '2020-12-31'


--9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH start_sub AS (
SELECT customer_id,
	MIN(start_date) as upgrade_start_date
FROM subscriptions
WHERE plan_id = 3
GROUP BY customer_id),
join_foodie AS
	(
	SELECT customer_id,
		start_date as join_date
	FROM subscriptions 
	WHERE plan_id = 0
	)
SELECT ROUND(AVG(upgrade_start_date - join_date),0) AS avg_upgradation
FROM start_sub ss
	 JOIN join_foodie jd
	 ON ss.customer_id = jd.customer_id;

	
	
	
 
WITH union_table AS(
SELECT customer_id,
	MIN(start_date) as min_date
FROM subscriptions
WHERE plan_id = 3
GROUP BY customer_id
UNION ALL
	(
SELECT customer_id,
start_date as min_date
FROM subscriptions 
WHERE plan_id = 0
	)),
lag_date as	
(
	SELECT customer_id,
			min_date,
	LAG(min_date,1) OVER (PARTITION BY customer_id ORDER BY min_date) join_date,
	(min_date - LAG(min_date,1) OVER (PARTITION BY customer_id ORDER BY min_date)) AS days
	FROM union_table)
SELECT ROUND(AVG(days),0)
FROM lag_date;

--10: Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH start_sub AS (
	SELECT customer_id,
		MIN(start_date) as upgrade_start_date
	FROM subscriptions
	WHERE plan_id = 3
	GROUP BY customer_id),
join_foodie AS
	(
	SELECT customer_id,
		start_date as join_date
	FROM subscriptions 
	WHERE plan_id = 0
	),
days_ as (SELECT (upgrade_start_date - join_date) AS days
	FROM start_sub ss
	 JOIN join_foodie jd
	 ON ss.customer_id = jd.customer_id),
breakdown as(
	SELECT floor(days/30) AS range_
	FROM days_ )
SELECT concat((range_ * 30) + 1, ' - ', (range_ + 1) * 30) AS limits,
		COUNT(*) as num_of_days
FROM breakdown
GROUP BY limits
ORDER BY num_of_days DESC
			

--11: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?



SET search_path = foodie_fi;
select * from plans;
select * from subscriptions;
select * from final_table;






------------------------------------------------------------------ B. Customer Transactions -------------------------------------------------------------


--1: What is the unique count and total amount for each transaction type?
SELECT txn_type,
		SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

--2: What is the average total historical deposit counts and amounts for all customers?
SELECT customer_id,
		ROUND(AVG(txn_amount),1) AS avg_amount,
		SUM(txn_amount) AS total_amount,
		COUNT(txn_amount) AS cnt
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id;
		
--3: For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_count AS
(SELECT DATE_PART('month', txn_date) AS month_,
		COUNT(customer_id) as cnt
FROM customer_transactions
GROUP BY month_, customer_id
HAVING COUNT(customer_id) > 1)
SELECT month_,
		SUM(cnt) AS customer_count
FROM monthly_count
GROUP BY month_
ORDER BY month_;

--4: What is the closing balance for each customer at the end of the month?
SELECT customer_id,
		DATE_PART('month', txn_date) AS month_,
		SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN -txn_amount
				 ELSE txn_amount END ) AS closing_blance
FROM customer_transactions
GROUP BY customer_id, month_
ORDER BY customer_id;


--5: What is the percentage of customers who increase their closing balance by more than 5%?
WITH first_txn AS 
(SELECT customer_id,
		SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN -txn_amount
				 ELSE txn_amount END ) AS closing_blance,
 		MIN(txn_date) as first_txn_date
FROM customer_transactions
GROUP BY customer_id
ORDER BY customer_id),
five_percent as(
SELECT ft.customer_id,
		ft.first_txn_date,
		ft.closing_blance,
		((ct.txn_amount*0.05) + ct.txn_amount) as percent_increase
FROM first_txn ft
	JOIN customer_transactions ct
	ON ft.first_txn_date = ct.txn_date
	AND ft.customer_id = ct.customer_id
)
SELECT ROUND((COUNT(*)*100/(SELECT COUNT(DISTINCT customer_id) FROM customer_transactions)::decimal),1) AS increase_five_percent
FROM five_percent
WHERE percent_increase > closing_blance;





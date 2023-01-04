
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

SET search_path = data_bank;


---------------------------------------------------- C. Data Allocation Challenge -------------------------------------------------------------


-- running customer balance column that includes the impact each transaction
WITH CTE AS (
SELECT customer_id,
		txn_amount,
		txn_date,
		txn_type,
		CASE WHEN txn_type = 'deposit' THEN txn_amount
		   ELSE -txn_amount END as deposit_withdrawl 
FROM customer_transactions)
SELECT customer_id, 
		deposit_withdrawl,
		txn_type,
		SUM(deposit_withdrawl) OVER(PARTITION BY customer_id ORDER BY txn_date)
FROM CTE
ORDER BY customer_id;


-- customer balance at the end of each month
SELECT customer_id,
		DATE_PART('month', txn_date) AS month_,
		SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN -txn_amount
				 ELSE txn_amount END ) AS closing_blance
FROM customer_transactions
GROUP BY customer_id, month_
ORDER BY customer_id;




-- minimum, average and maximum values of the running balance for each customer
WITH CTE AS (
SELECT customer_id,
		txn_amount,
		txn_date,
		txn_type,
		CASE WHEN txn_type = 'deposit' THEN txn_amount
		   ELSE -txn_amount END as deposit_withdrawl 
FROM customer_transactions),
running_table AS(
SELECT customer_id, 
		deposit_withdrawl,
		txn_type,
		SUM(deposit_withdrawl) OVER(PARTITION BY customer_id ORDER BY txn_date) as running_total
FROM CTE
ORDER BY customer_id)
SELECT  customer_id,
		MIN(running_total),
		MAX(running_total),
		ROUND(AVG(running_total), 1)
FROM running_table
GROUP BY customer_id









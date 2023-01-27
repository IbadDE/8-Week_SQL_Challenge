
--------------------------------------------------------- 2.Transaction Analysis --------------------------------------------------------------



--1: How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) as total_transactions
FROM sales;


--2: What is the average unique products purchased in each transaction?
SELECT prod_id, ROUND(AVG(qty), 2) as avg_products
FROM sales
GROUP BY prod_id
ORDER BY avg_products DESC;


--3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY total) as percentile_25th,
		PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY total) as percentile_50th,
		PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY total) as percentile_75th
FROM sales;


--4: What is the average discount value per transaction?
SELECT ROUND(AVG(discount),2) as avg_discount
FROM (SELECT txn_id, discount
		FROM sales
		GROUP BY 1,2) as t1;

--5: What is the percentage split of all transactions for members vs non-members?
SELECT member, 
		ROUND(COUNT(DISTINCT txn_id)::decimal/(SELECT COUNT(DISTINCT txn_id)::decimal FROM sales) * 100,2)
FROM sales
GROUP BY member;


--6: What is the average revenue for member transactions and non-member transactions?
SELECT member, 
		ROUND(AVG(total),2)
FROM sales
GROUP BY member;




select * from sales
select * from product_prices
select * from product_details
select * from product_hierarchy
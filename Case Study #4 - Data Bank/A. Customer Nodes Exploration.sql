
----------------------------------------------------------   A. Customer Nodes Exploration   ----------------------------------------------------------

--1: How many unique nodes are there on the Data Bank system?
SELECT SUM(cnt) 
FROM (SELECT COUNT(DISTINCT node_id) AS cnt
	FROM customer_nodes
	GROUP BY region_id, node_id) as sub


--2: What is the number of nodes per region?
SELECT rg.region_name,
		COUNT(DISTINCT cn.node_id) AS num_nodes
	FROM customer_nodes cn
		JOIN regions rg
	ON cn.region_id = rg.region_id
	GROUP BY rg.region_name


--3: How many customers are allocated to each region?
SELECT rg.region_name,
		COUNT(DISTINCT cn.customer_id) AS num_nodes
FROM customer_nodes cn
	JOIN regions rg
ON cn.region_id = rg.region_id
GROUP BY rg.region_name
	
	
--4: How many days on average are customers reallocated to a different node?
SELECT ROUND(AVG(end_date - start_date),1) AS avg_days 
FROM customer_nodes
WHERE end_date <> '9999-12-31';


--5: What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with diff_in_days AS(
SELECT region_id,
		(end_date - start_date) AS days_diff 
FROM customer_nodes
WHERE end_date <> '9999-12-31')
SELECT region_id,
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY days_diff ) AS median,
		PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY days_diff ) AS eighth_percentile,
		PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY days_diff ) AS nintyfifth_percentile
FROM diff_in_days
GROUP BY region_id



SELECT * FROM customer_nodes;
SELECT * FROM customer_transactions;
SELECT * FROM regions;
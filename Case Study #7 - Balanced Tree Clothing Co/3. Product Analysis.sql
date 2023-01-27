set search_path = 'balanced_tree'
---------------------------------------------------------- 3.Product Analysis -------------------------------------------------------------

--1. What are the top 3 products by total revenue before discount?
SELECT pd.product_name,
		SUM(s.total) as product_revenue
FROM sales s
	JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY product_revenue DESC
LIMIT 3;


--2: What is the total quantity, revenue and discount for each segment?
SELECT pd.segment_id,
		SUM(s.qty) as total_quantity,
		SUM(s.total) as total_revenue           -- I didn't included discount on each items, because in sales tables the discount is given on basis of
FROM sales s								    -- transaction_id. It doesn't give us any idea about discount given on segment_id.
	JOIN product_details pd						-- If you know please email me or make changes through forks.
	ON s.prod_id = pd.product_id
GROUP BY pd.segment_id


--3: What is the top selling product for each segment?
WITH CTE AS(
	SELECT prod_id, 
			SUM(qty) as top_settling
	FROM sales
	GROUP BY prod_id),
ranking as (
	SELECT pd.segment_name,
			pd.product_name,
			cte.top_settling,
			DENSE_RANK() OVER(PARTITION BY segment_name ORDER BY top_settling DESC) as rnk
FROM cte
	JOIN product_details pd
	ON cte.prod_id = pd.product_id)
SELECT segment_name,
		product_name,
		top_settling
FROM ranking
WHERE rnk = 1;


--4: What is the total quantity, revenue and discount for each category?
SELECT pd.category_name,
		SUM(s.qty) as total_quantity,
		SUM(s.total) as total_revenue 
FROM sales s
	JOIN product_details pd	
	ON s.prod_id = pd.product_id
GROUP BY pd.category_name


--5: What is the top selling product for each category?
WITH CTE AS(
	SELECT prod_id, 
			SUM(qty) as top_settling
	FROM sales
	GROUP BY prod_id),
ranking as (
	SELECT pd.category_name,
			pd.product_name,
			cte.top_settling,
			DENSE_RANK() OVER(PARTITION BY category_name ORDER BY top_settling DESC) as rnk
FROM cte
	JOIN product_details pd
	ON cte.prod_id = pd.product_id)
SELECT category_name,
		product_name,
		top_settling
FROM ranking
WHERE rnk = 1;


--6: What is the percentage split of revenue by product for each segment?
WITH CTE_1 AS (
	SELECT segment_name,
			product_name,
			SUM(total) as product_revenue
	FROM sales s
		JOIN product_details pd	
		ON s.prod_id = pd.product_id
	GROUP BY segment_name,product_name),
CTE_2 AS(
	SELECT *, 
			SUM(product_revenue) OVER (PARTITION BY segment_name) as segment_revenue
	FROM CTE_1)
SELECT segment_name,
		product_name,
		ROUND(product_revenue/segment_revenue * 100,2) as pct_revenue
FROM CTE_2
		

--7: What is the percentage split of revenue by segment for each category?
WITH CTE_1 AS (
	SELECT category_name,
			segment_name,
			SUM(total) as seg_revenue
	FROM sales s
		JOIN product_details pd	
		ON s.prod_id = pd.product_id
	GROUP BY category_name,segment_name),
CTE_2 AS(
	SELECT *, 
			SUM(seg_revenue) OVER (PARTITION BY category_name) as cat_revenue
	FROM CTE_1)
SELECT category_name,
		segment_name,
		ROUND(seg_revenue/cat_revenue * 100,2) as pct_revenue
FROM CTE_2


--8: What is the percentage split of total revenue by category?
SELECT category_name,
		ROUND(((SUM(total)/(SELECT SUM(total) FROM sales)) *100),2) as pct
FROM sales s
	JOIN Product_details pd
	ON s.prod_id = pd.product_id
GROUP BY category_name


--9: What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT product_name,
		ROUND((COUNT(*)::decimal/ (SELECT COUNT(DISTINCT txn_id)::decimal FROM sales)) *100, 2) as penetration
FROM sales s
	JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY product_name


--10: What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH CTE as (
SELECT pd.product_name, s.txn_id
	FROM sales as s
	JOIN product_details pd
	ON s.prod_id = pd.product_id)
SELECT combinations.product_name_1, combinations.product_name_2, combinations.product_name_3, COUNT(*) as frequency
FROM (
  SELECT c1.product_name as product_name_1,
		c2.product_name as product_name_2, 
		c3.product_name as product_name_3
  FROM CTE c1
  	JOIN CTE c2 
	ON c2.txn_id = c1.txn_id AND c2.product_name <> c1.product_name
  	JOIN CTE c3 
	ON c3.txn_id = c1.txn_id AND c3.product_name <> c1.product_name AND c3.product_name <> c2.product_name
) combinations
GROUP BY combinations.product_name_1, combinations.product_name_2, combinations.product_name_3
ORDER BY frequency DESC
LIMIT 1;



-- THE above query was solved by chatgpt, I just made few changes.

 


select * from sales
select * from product_prices
select * from product_details
select * from product_hierarchy

--------------------------------------------------------------- 2. Data Exploration ---------------------------------------------------------------------



--1. What day of the week is used for each week_date value?
SELECT DISTINCT to_char(week_date, 'Day') as day_
FROM weekly_sales;


--2: What range of week numbers are missing from the dataset?
SELECT generate_series(1,52) :: int as range_
			EXCEPT
SELECT week_number :: int
FROM weekly_sales
ORDER BY range_;


--3: How many total transactions were there for each year in the dataset?
SELECT year_number,
		SUM(year_number) as total_transactions
FROM weekly_sales
GROUP BY year_number
ORDER BY year_number;


--4: What is the total sales for each region for each month?
SELECT region,
		month_number,
		SUM(sales) as total_sales
FROM weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
		

--5: What is the total count of transactions for each platform
SELECT platform,
		COUNT(*) as total_number
FROM weekly_sales
GROUP BY platform
ORDER BY platform;


--6: What is the percentage of sales for Retail vs Shopify for each month?
WITH cte_sum as (
SELECT month_number,
		SUM(sales) :: decimal as total,
		SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) :: decimal as retail_sum,
		SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) :: decimal as shopify_sum
FROM weekly_sales
GROUP BY month_number
ORDER BY month_number)
SELECT month_number,
		round(retail_sum*100/total,2) as retail_percentage,
		round(shopify_sum*100/total, 2) as shopify_percentage
FROM cte_sum;


--7: What is the percentage of sales by demographic for each year in the dataset?
WITH CTE_sum AS(
	SELECT demographic,
			year_number,
			SUM(sales):: decimal as total_sales
	FROM weekly_sales
	GROUP BY demographic, year_number
	),
cte_window as (
	SELECT *,
			SUM(total_sales) OVER (PARTITION BY year_number)::decimal as win_sales
	FROM CTE_sum)
SELECT demographic,
		year_number,
		round((total_sales * 100 / win_sales),2) as percent_sale
FROM cte_window;


--8: Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band,
       demographic,
       round(100*SUM(sales)/(SELECT SUM(sales)
                			FROM weekly_sales
           				     WHERE platform='Retail'), 2) AS retail_percent
FROM weekly_sales
WHERE platform='Retail'
GROUP BY demographic, age_band
ORDER BY retail_percent DESC;



--9: Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT year_number,
		platform,
		ROUND(SUM(sales)::decimal/(SUM(transactions)::decimal),2) as avg_transactions
FROM weekly_sales
GROUP BY year_number,platform



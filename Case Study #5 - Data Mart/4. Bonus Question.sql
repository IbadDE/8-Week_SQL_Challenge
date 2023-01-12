

---------------------------------------------------------- 4. Bonus Question -------------------------------------------------------------------

-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

-- region
-- platform
-- age_band
-- demographic
-- customer_type



-- region
WITH CTE AS (
	SELECT region,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '4 week' ) 
							AND ('2020-06-15'::date + interval '3 weeks')),						
weekly_sum as (
	SELECT Event_,
			region,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_, region),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(PARTITION BY region ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT Event_,
		region,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;




-- platform
WITH CTE AS (
	SELECT platform,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '4 week' ) 
							AND ('2020-06-15'::date + interval '3 weeks')),						
weekly_sum as (
	SELECT platform,
			Event_,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_, platform),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(PARTITION BY platform ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT platform,
		Event_,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;


-- age_band
WITH CTE AS (
	SELECT age_band,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '4 week' ) 
							AND ('2020-06-15'::date + interval '3 weeks')),						
weekly_sum as (
	SELECT age_band,
			Event_,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_, age_band),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(PARTITION BY age_band ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT age_band,
		Event_,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;

--demographic
WITH CTE AS (
	SELECT demographic,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '4 week' ) 
							AND ('2020-06-15'::date + interval '3 weeks')),						
weekly_sum as (
	SELECT demographic,
			Event_,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_, demographic),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(PARTITION BY demographic ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT demographic,
		Event_,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;


--customer_type
WITH CTE AS (
	SELECT customer_type,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '4 week' ) 
							AND ('2020-06-15'::date + interval '3 weeks')),						
weekly_sum as (
	SELECT customer_type,
			Event_,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_, customer_type),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(PARTITION BY customer_type ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT customer_type,
		Event_,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;





--ANS: Shopify have the most negative impact after -3.08 after the required date.
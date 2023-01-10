

-------------------------------------------------------------- 3. Before & After Analysis --------------------------------------------------------------

-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- Using this analysis approach - answer the following questions:
-- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
-- What about the entire 12 weeks before and after?
-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?



--1: What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
WITH CTE AS (
	SELECT week_date,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '4 week' ) 
							AND ('2020-06-15'::date + interval '3 weeks')),						
weekly_sum as (
	SELECT Event_,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT Event_,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;



--2: What about the entire 12 weeks before and after?
WITH CTE AS (
	SELECT week_date,
			CASE WHEN week_date < '2020-06-15' THEN 'before_event' 
			WHEN week_date >= '2020-06-15' THEN 'after_event'
			END as Event_,
			sales
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '12 week' ) 
							AND ('2020-06-15'::date + interval '11 weeks')),						
weekly_sum as (
	SELECT Event_,
			SUM(sales)::decimal as four_week_sales
	FROM CTE
	GROUP BY Event_),
lagging_sum as (
	SELECT *,
			LAG(four_week_sales, 1) OVER(ORDER BY Event_ DESC) as previous_weeks_sale
	FROM weekly_sum)
SELECT Event_,
		four_week_sales,
		previous_weeks_sale,
		round((four_week_sales - previous_weeks_sale)/previous_weeks_sale * 100,2) as growth_rate_pct,
		four_week_sales - previous_weeks_sale as sales_diff
FROM lagging_sum;


--3: How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
WITH CTE AS (
	SELECT DISTINCT week_number
	FROM weekly_sales
	WHERE week_date BETWEEN ('2020-06-15'::date - interval '12 week' ) 
							AND ('2020-06-15'::date + interval '11 weeks')),
Joining_table as (
	SELECT ws.week_number,
			SUM(CASE WHEN year_number = 2018 THEN sales ELSE null END)::decimal as sales_2018,
			SUM(CASE WHEN year_number = 2019 THEN sales ELSE 0 END)::decimal as sales_2019,
			SUM(CASE WHEN year_number = 2020 THEN sales ELSE 0 END)::decimal as sales_2020	
	FROM weekly_sales ws
		JOIN CTE 
		ON CTE.week_number = ws.week_number
	GROUP BY ws.week_number)
SELECT *,
		round(coalesce(((sales_2019 - sales_2018)/sales_2018),0)*100,2) growth_rate_pct_2019,
		round(coalesce(((sales_2020 - sales_2019)/sales_2020),0)*100,2) growth_rate_pct_2020
FROM joining_table
ORDER BY week_number




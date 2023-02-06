DROP TABLE IF EXISTS customer_orders_update;
CREATE TABLE customer_orders_update AS 	
WITH clean_table AS(
	SELECT order_id,
		customer_id,
		pizza_id,
	   CASE WHEN extras IN ('null', '') THEN null
	   	    ELSE extras END
	   		AS extras,
	   CASE WHEN exclusions IN ('null', '') THEN null
	  		ELSE exclusions END 
			AS  exclusions,
			order_time
	FROM customer_orders)
SELECT *,
		ROW_NUMBER() OVER(Order BY order_id,customer_id) AS row_rank
FROM clean_table;




DROP TABLE IF EXISTS runner_order_temp;
SELECT order_id,
  	runner_id,
	to_timestamp(CASE WHEN pickup_time = 'null' then null
				ELSE pickup_time end, 'YYYY-MM-DD HH24:MI:SS') as pickup_time,
	CASE WHEN distance LIKE '%km' THEN Trim(substring(distance, 0, position('k' in distance)))
		 WHEN distance in ('null', ' ') then null
		 ELSE TRIM(distance) END :: decimal as distance,
	CASE WHEN duration like '%min%' then trim(substring(duration, 0, position('m' in duration)))
		 WhEN duration in ('null', ' ') then null
		 ELSE TRIM(duration) END ::int  as duration,
	CASE WHEN cancellation in ('null', '') then null 
		 ELSE TRIM(cancellation) END AS cancellation
INTO runner_order_temp
FROM runner_orders;
TRUNCATE TABLE runner_orders;
ALTER TABLE runner_orders
	DROP COLUMN distance,
	DROP COLUMN duration,
	DROP COLUMN pickup_time,
	DROP COLUMN cancellation;
ALTER TABLE runner_orders
	ADD COLUMN pickup_time timestamp DEFAULT null,
	ADD COLUMN distance decimal DEFAULT null,
	ADD COLUMN duration int DEFAULT null,
	ADD COLUMN cancellation varchar(32) DEFAULT null;
INSERT INTO runner_orders
	SELECT * FROM runner_order_temp;
DROP TABLE runner_order_temp;


DROP TABLE IF EXISTS new_pizza_recipes;
SELECT pizza_id, UNNEST(string_to_array(toppings, ', '))::int AS toppings
INTO new_pizza_recipes
FROM pizza_recipes;




---------------------------------------------------------- C.Ingredient Optimisation---------------------------------------------------------

--1: What are the standard ingredients for each pizza?
SELECT pn.pizza_name, ARRAY_AGG(pt.topping_name) as ingredients
FROM new_pizza_recipes pr
	JOIN pizza_toppings pt
	on pr.toppings = pt.topping_id
	JOIN pizza_names pn
	ON pn.pizza_id = pr.pizza_id
Group by pn.pizza_name;

--2: What was the most commonly added extra?
SELECT pt.topping_name,
	COUNT(extrass)
FROM
	(SELECT CAST(UNNEST(STRING_TO_ARRAY(extras, ', ')) as int) as extrass
	FROM customer_orders) sq
	JOIN pizza_toppings pt
	ON sq.extrass = pt.topping_id
GROUP BY pt.topping_name;

--3: What was the most common exclusion?
SELECT pt.topping_name,
	COUNT(exclusionss)
FROM
	(SELECT CAST(UNNEST(STRING_TO_ARRAY(exclusions, ', ')) as int) as exclusionss
	FROM customer_orders) sq
	JOIN pizza_toppings pt
	ON sq.exclusionss = pt.topping_id
GROUP BY pt.topping_name;




--4: Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers




WITH customer_pref AS (
		SELECT cu.customer_id,
				pn.pizza_name,
				split_part(cu.exclusions, ',', 1) :: int AS exclusion_1,
				split_part(cu.exclusions, ',', 2) AS exclusion_2,
				split_part(cu.extras, ',', 1) :: int AS extra_1,
				split_part(cu.extras, ',', 2) AS extra_2
		FROM customer_orders cu
			JOIN pizza_names pn
			ON cu.pizza_id = pn.pizza_id
	),
	
customer_preference AS(
SELECT customer_id,
		pizza_name,
		exclusion_1,
		extra_1,
		CAST(CASE WHEN exclusion_2 = '' then null
			ELSE exclusion_2 END AS int) AS exclusion_3,
		CAST(CASE WHEN extra_2 = '' then null
			ELSE extra_2  END AS int)  AS extra_3
FROM customer_pref
		),
	Pizza_ingredients as (
SELECT customer_id, pizza_name, 
		pt.topping_name as exclusion_11, 
		pt1.topping_name as extra_11, 
		pt2.topping_name as extra_22, 
		pt3.topping_name as exclusion_22
FROM customer_preference  cp
LEFT JOIN pizza_toppings pt 
	ON cp.exclusion_1 = pt.topping_id
LEFT JOIN pizza_toppings pt1
	ON cp.extra_1 = pt1.topping_id
LEFT JOIN pizza_toppings pt2
	ON cp.extra_3 = pt2.topping_id
LEFT JOIN pizza_toppings pt3
	ON cp.exclusion_3 = pt3.topping_id
	),
Exclude_include AS (
SELECT *,
		CASE WHEN exclusion_11 is null AND exclusion_22 is  null THEN null
			 WHEN exclusion_11 is null AND exclusion_22 is not null THEN concat(' - Exclude ', exclusion_11)
			 ELSE concat(' - Exclude ', exclusion_11, ' ', exclusion_22) END AS exclude_items,
		CASE WHEN extra_11 is null AND extra_22 is  null THEN null
			 WHEN extra_11 is null AND extra_22 is not null THEN concat(' - Exclude ', extra_11)
			 ELSE concat(' - Exclude ', extra_11, ' ', extra_22) END AS extra_items
FROM Pizza_ingredients)
	SELECT customer_id,
	concat(pizza_name, exclude_items,extra_items) AS pizza_with_ingredients 
	FROM exclude_include
	
-- 5: Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
DROP TABLE IF EXISTS clean_table;
CREATE TEMP TABLE clean_table AS (
SELECT cu.row_rank,
		cu.order_id,
		pn.pizza_name,
		pt.topping_id
FROM customer_orders_update cu
	JOIN new_pizza_recipes npr
	ON cu.pizza_id = npr.pizza_id
JOIN pizza_names pn
	ON pn.pizza_id = cu.pizza_id
JOIN pizza_toppings pt
ON pt.topping_id = npr.toppings
ORDER BY order_id);


DROP TABLE IF EXISTS pizza_exclusions;
CREATE TEMP TABLE pizza_exclusions AS (
SELECT row_rank, 
		order_id, 
		pn.pizza_name,
		UNNEST(string_to_array(coalesce(exclusions, '0'), ', ')) :: int AS exclusions
FROM customer_orders_update cu
	JOIN pizza_names pn
	ON cu.pizza_id = pn.pizza_id);
	
DROP TABLE IF EXISTS pizza_extras;
CREATE TEMP TABLE pizza_extras AS (
SELECT row_rank, 
		order_id, 
		pn.pizza_name,
		UNNEST(string_to_array(COALESCE(extras, '0'), ', ')) :: int AS topping_id
FROM customer_orders_update cu
	JOIN pizza_names pn
	ON cu.pizza_id = pn.pizza_id);
	

DROP TABLE IF EXISTS ingredient_name;
CREATE TEMP TABLE ingredient_name AS(
WITH union_except as(
SELECT *
FROM clean_table
EXCEPT 
SELECT * FROM pizza_exclusions
UNION ALL
SELECT * FROM pizza_extras
WHERE topping_id != 0)

SELECT row_rank,order_id, 
	ue.pizza_name,
	pt.topping_name,
	COUNT(*) AS cnt
FROM union_except ue
	JOIN pizza_toppings pt
	ON pt.topping_id = ue.topping_id
GROUP BY row_rank,order_id,pt.topping_name,ue.pizza_name);
	
with row_names AS(
SELECT row_rank,
		order_id,pizza_name,
		STRING_AGG(CASE when cnt > 1  THEN concat(cnt, 'x ' , topping_name, ' ')
		ELSE  concat(topping_name, ' ') END, ',') AS all_ingre
FROM ingredient_name
GROUP BY row_rank, order_id,pizza_name
ORDER BY row_rank
)
SELECT row_rank,order_id, concat(pizza_name,': ',all_ingre)
FROM row_names;



--6: What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

SELECT topping_name,
		COUNT(*) AS num_of_time_use
FROM ingredient_name
GROUP BY topping_name
ORDER BY num_of_time_use DESC;

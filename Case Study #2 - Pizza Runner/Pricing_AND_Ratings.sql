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





----------------------------------------------------------- D. Pricing and Ratings ---------------------------------------------------------


--1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH pizza_type AS (	
SELECT cu.order_id,
		pn.pizza_name,
		pn.pizza_id
FROM customer_orders_update cu
	JOIN pizza_names pn
	ON pn.pizza_id = cu.pizza_id
	)
SELECT ro.runner_id,
		SUM(CASE WHEN pt.pizza_id = 1 THEN 12
		ELSE 10 END) AS collect_money
FROM pizza_type pt
	JOIN runner_orders ro
	ON pt.order_id = ro.order_id
WHERE cancellation is null
GROUP BY ro.runner_id;


--2: What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH pizza_type AS (	
SELECT cu.order_id,
		pn.pizza_name,
		cu.extras,
		pn.pizza_id
FROM customer_orders_update cu
	JOIN pizza_names pn
	ON pn.pizza_id = cu.pizza_id
	)
SELECT ro.runner_id,
		SUM(CASE WHEN pt.pizza_id = 1 THEN 12
		ELSE 10 END)
		+ SUM(CASE WHEN pt.extras is not null THEN 1
		   ELSE 0 END) AS collect_money
FROM pizza_type pt
	JOIN runner_orders ro
	ON pt.order_id = ro.order_id
WHERE cancellation is null
GROUP BY ro.runner_id;


--3: The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset -
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS rating_table;
CREATE TEMP TABLE rating_table AS(
SELECT cu.customer_id,
		cu.order_id,
		ru.runner_id,
		cu.order_time,
		ru.pickup_time,
		ru.duration,
		ROUND(ru.distance/(ru.duration/60.0),2) AS km_per_hr,
		CASE WHEN ru.distance/ROUND((ru.duration/60.0),2) >= 0  AND ru.distance/ROUND((ru.duration/60.0),2) < 15 THEN 1
		 	 WHEN ru.distance/ROUND((ru.duration/60.0),2) >= 15 AND ru.distance/ROUND((ru.duration/60.0),2) < 22 THEN 2
			 WHEN ru.distance/ROUND((ru.duration/60.0),2) >= 22 AND ru.distance/ROUND((ru.duration/60.0),2) < 29 THEN 3
			 WHEN ru.distance/ROUND((ru.duration/60.0),2) >= 35 AND ru.distance/ROUND((ru.duration/60.0),2) < 42 THEN 4
			 ELSE 5 END AS rating
FROM runner_orders ru
	JOIN customer_orders_update cu
	ON cu.order_id = ru.order_id
WHERE  ru.distance IS NOT null);
SELECT * FROM rating_table;


--4: Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas
SELECT customer_id,
		order_id,
		runner_id,
		order_time,
		pickup_time,
		duration,
		rating,
		concat(DATE_PART('minutes', pickup_time - order_time),' mins') AS Preparing_time,
		ROUND(AVG(km_per_hr),2) AS avg_speed,
		count(*) AS num_of_pizzass
FROM rating_table
GROUP BY 1,2,3,4,5,6,7,8
ORDER BY order_id;


--5: If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
-- how much money does Pizza Runner have left over after these deliveries?
WITH pizza_type AS (	
SELECT cu.order_id,
		pn.pizza_name,
		cu.extras,
		pn.pizza_id
FROM customer_orders_update cu
	JOIN pizza_names pn
	ON pn.pizza_id = cu.pizza_id
	)
SELECT ro.runner_id,
		SUM(CASE WHEN pt.pizza_id = 1 THEN 12
		ELSE 10 END)
		+ ROUND(SUM(ro.distance*0.3),2) AS collect_money
FROM pizza_type pt
	JOIN runner_orders ro
	ON pt.order_id = ro.order_id
WHERE cancellation is null
GROUP BY ro.runner_id;
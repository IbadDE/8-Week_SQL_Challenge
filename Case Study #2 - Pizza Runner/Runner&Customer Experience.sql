SELECT * FROM customer_orders;
DROP TABLE IF EXISTS customer_orders_temp;
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
  INTO customer_orders_temp
  FROM customer_orders;
  TRUNCATE TABLE customer_orders;
  INSERT INTO customer_orders
  SELECT * FROM customer_orders_temp;
  DROP TABLE customer_orders_temp;  
  
SELECT * FROM runner_orders;
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




---------------------------------------------------------- B. Runner and Customer Experience ---------------------------------------------------------


--1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATE_PART('week', registration_date + 7) AS week_number,
		COUNT(runner_id) AS total_reg
FROM runners
GROUP BY week_number
ORDER BY week_number;

--2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT r.runner_id,
		AVG(DATE_PART('minute', ( r.pickup_time - c.order_time))) as average_time
FROM runner_orders r
	JOIN customer_orders c
	ON r.order_id = c.order_id
WHERE r.pickup_time is not null
GROUP BY r.runner_id;

--3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH CTE AS (
	SELECT c.order_id,
			COUNT(c.order_id) as CNT,
			AVG(DATE_PART('minute', r.pickup_time - c.order_time)) as AVG_time
	FROM runner_orders r
		JOIN customer_orders c
		ON r.order_id = c.order_id
	WHERE r.pickup_time is not null
	GROUP BY c.order_id
	)
SELECT DISTINCT cnt AS num_of_ordered_pizzas,
		AVG(AVG_time) AS Average_time
FROM cte
GROUP BY cnt;
			
--4: What was the average distance travelled for each customer?
SELECT c.customer_id,
		ROUND(AVG(r.distance_km),2) as distance_travelled_km
FROM customer_orders c
	JOIN runner_orders r
	ON c.order_id = r.order_id
WHERE r.distance_km is not null
GROUP BY c.customer_id;

--5: What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(DATE_PART('minute', r.pickup_time - c.order_time)) - MIN(DATE_PART('minute', r.pickup_time - c.order_time)) AS time_diff
FROM customer_orders c
	JOIN runner_orders r
	ON c.order_id = r.order_id
WHERE r.pickup_time is not null;


SELECT * FROM runner_orders;
--6: What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT ro.runner_id, 
		cu.customer_id,
		round(AVG(((ro.distance)/(ro.duration/60.0))),2) as avg_speed
FROM runner_orders ro
	JOIN customer_orders cu
	ON ro.order_id = cu.order_id
WHERE ro.cancellation is null	
GROUP BY 1,2;
	
--7: What is the successful delivery percentage for each runner?
SELECT runner_id, 
		CONCAT(ROUND(COUNT(pickup_time)/COUNT(runner_id) :: decimal, 2)*100,'%') AS success_delivery
FROM runner_orders
GROUP BY runner_id;
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



------------------------------------------------------------- A. Pizza Metrics --------------------------------------------------------------


--1: How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders;

--2: How many unique customer orders were made?
SELECT COUNT( DISTINCT customer_id) AS unique_customer
FROM customer_orders;

--3: How many successful orders were delivered by each runner?
SELECT runner_id,
		COUNT(duration) AS sucess_delivery
FROM runner_orders
GROUP BY runner_id;

--4: How many of each type of pizza was delivered?
SELECT c.pizza_id,
	COUNT(c.pizza_id) AS Total_delievred_pizzas
FROM customer_orders c
	JOIN runner_orders r
	ON c.order_id = r.order_id
WHERE r.cancellation IS null
GROUP BY pizza_id;

--5: How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id, 
		p.pizza_name,
		COUNT(p.pizza_name)
FROM customer_orders c
	JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name

--6: What was the maximum number of pizzas delivered in a single order?
SELECT MAX(sq.cnt) as max_pizzas
FROM (
	SELECT COUNT(c.order_id) AS cnt
	 FROM customer_orders c
	 	JOIN runner_orders r
	  	ON r.order_id = c.order_id
	 WHERE r.cancellation is null
	 GROUP BY c.order_id) sq
	 
--7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH CTE AS (
SELECT c.customer_id,
		CASE WHEN c.extras IS null AND c.exclusions IS null THEN 'NO'
			ElSE 'YES'
			END AS Change
FROM customer_orders c
	JOIN runner_orders r
	ON r.order_id = c.order_id
WHERE r.cancellation is null
			)
SELECT customer_id,
		Change,
		COUNT(change) as num_of_changes
FROM CTE
GROUP BY customer_id, change;

-- 8: How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(CASE WHEN c.extras IS null OR c.exclusions IS null THEN null
					ElSE 'both'
					END) AS Change
FROM customer_orders c
	JOIN runner_orders r
	ON r.order_id = c.order_id
WHERE r.cancellation is null;

--9: What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(hour from order_time) as day_hour,
		COUNT(*) as num_of_pizzas
FROM customer_orders
GROUP BY day_hour;

--10: What was the volume of orders for each day of the week?
SELECT EXTRACT(dow from order_time) as day_of_week,
		COUNT(*) as num_of_pizzas
FROM customer_orders
GROUP BY day_of_week;



SET search_path = 'foodie_fi'


--------------------------------------------------------------------------- D. Outside The Box Questions ---------------------------------------------------

--1: How would you calculate the rate of growth for Foodie-Fi?

WITH monthly_table as (
SELECT DATE_PART('month',start_date) AS month_num,
		sum(pp.price)::decimal as current_total
FROM subscriptions as ss
	JOIN plans pp
	ON pp.plan_id = ss.plan_id
GROUP BY month_num
ORDER BY month_num),
churn_table as (
SELECT DATE_PART('month',start_date) AS month_num,
		count(pp.price)::decimal as current_churn
FROM subscriptions as ss
	JOIN plans pp
	ON pp.plan_id = ss.plan_id
WHERE ss.plan_id = 0
GROUP BY month_num
ORDER BY month_num),
lag_sum as (
SELECT mt.month_num,
		current_total,
		current_churn,
		lag(current_total,1) OVER(ORDER BY mt.month_num)::decimal AS previous_total, 
		lag(current_churn,1) OVER(ORDER BY mt.month_num)::decimal AS previous_churn
FROM monthly_table mt
	JOIN churn_table ct
	ON ct.month_num = mt.month_num)
SELECT month_num,
		ROUND(current_total/previous_total,3) AS month_percent,
		ROUND(current_churn/previous_total,3) AS churn_percent
FROM lag_sum



--2: What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- ANS: To track down customer favourite chef, type of cuisines, watch time(either customer prefer long or short video), 
-- food budget(weather customer prefer to watch expensive food or cheap), vegetiran or non vegetarian, street foods.




--3: What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- ANS: low prices, 30 days to recover his/her account after churn, good quality of video, add subtitles.



--4: If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- ANS: high prices, sound/video quality, old stuff, expensive foods, other(specify)


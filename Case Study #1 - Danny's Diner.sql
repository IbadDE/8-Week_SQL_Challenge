CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
  select * from members;
  select * from menu;
  select * from sales;
  
  
  
  
-- 1: What is the total amount each customer spent at the restaurant?  
  select s.customer_id, sum(m.price) as total_amount
  from sales s
  join menu m
  on s.product_id = m.product_id
  group by s.customer_id;
  
  
  
-- 2: How many days has each customer visited the restaurant?
  select customer_id, count(distinct order_date) as number_of_days
  from sales
  group by customer_id;
  
  
  
-- 3: What was the first item from the menu purchased by each customer?

					-- First Method using subquiries
with cte as (
	select sb.customer_id, sb.min_date, s.product_id,m.product_name
	from (select customer_id, min(order_date) as min_date
	from sales 
	group by customer_id) sb
	join sales s
	on s.customer_id = sb.customer_id and sb.min_date = s.order_date
	join menu m 
	on m.product_id = s.product_id
	)
select customer_id, product_name
from cte
group by 1,2;
	
	    -- ANOTHER METHOD uisng Window function
with cte as (
		select s.customer_id, m.product_name,
		dense_rank () over(partition by s.customer_id order by s.order_date) as dense
		from sales as s
		join menu as m
		on s.product_id = m.product_id
		)		
select customer_id, product_name 
from cte
where dense = 1
group by 1,2




-- 4: What is the most purchased item on the menu and how many times was it purchased by all customers?	
select m.product_name, count(*) as number_of_purchase
from sales s
join menu m
on s.product_id = m.product_id
group by m.product_name;


-- 5: Which item was the most popular for each customer?
with most_popular as (
	select s.customer_id, m.product_name, count(*) as popular,
	dense_rank() over(partition by s.customer_id order by count(*) desc) as dense
	from sales s
	join menu m
	on s.product_id = m.product_id
	group by 1,2
	)	
select customer_id, product_name
from most_popular
where dense = 1



-- 6: Which item was purchased first by the customer after they became a member?
with first_purchase as 
	(
	select s.customer_id,s.order_date,s.product_id 
	from sales s 
	join members m 
	on m.customer_id = s.customer_id 
	and m.join_date <= s.order_date),
rnk as
	(
	select fp.customer_id, fp.order_date, m.product_name,
	dense_rank() over(partition by fp.customer_id order by fp.order_date) as dense
	from first_purchase fp
	join menu m
	on m.product_id = fp.product_id	
	)
select customer_id, product_name
from rnk
where dense = 1;



-- 7: Which item was purchased just before the customer became a member?
with last_purchase as 
	(
	select s.customer_id,s.order_date,s.product_id, menu.product_name,
	dense_rank() over(partition by s.customer_id order by s.order_date desc) as dense
	from sales s 
	join members m 
	on m.customer_id = s.customer_id 
	and m.join_date > s.order_date
	join menu 
	on menu.product_id = s.product_id
	)
select customer_id, product_name
from last_purchase
where dense = 1;



--8: What is the total items and amount spent for each member before they became a member?
select s.customer_id, sum(me.price) as amount_spent,
	count(distinct me.product_id) as total_items
from sales s
join members m
on m.customer_id = s.customer_id
and m.join_date > s.order_date
join menu me
on me.product_id = s.product_id
group by s.customer_id



-- 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
	s.customer_id,
	sum(case when m.product_name = 'sushi' then m.price*20
			 else m.price*10 end) as points
from menu m
join sales s
on m.product_id = s.product_id
group by s.customer_id



-- 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
	select 
	s.customer_id,
	sum(case when (s.order_date between me.join_date + interval '6 day' and Date('2021-02-01'))
				and (m.product_name = 'curry'
				or m.product_name = 'ramen')
				then m.price*20
			when m.product_name = 'sushi'
				then m.price*20
			else m.price*10 end) as points
	from menu m 
	join sales s
	on m.product_id = s.product_id
	join members me
	on me.customer_id = s.customer_id
	group by s.customer_id
	
	
	
	
									/* Bonus Questions
									Join All The Things
The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. */
	


select s.customer_id, s.order_date, m.product_name, m.price,
case when me.join_date <= s.order_date then 'Y'
	 else 'N'end as member
from sales s
left join menu m
on s.product_id = m.product_id
left join members as me
on s.customer_id = me.customer_id
order by s.customer_id, s.order_date;




											/* Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program. */



with cte as (
	select s.customer_id, s.order_date, m.product_name, m.price,
	case when me.join_date <= s.order_date then 'Y'
		 else 'N'end as member
	from sales s
	left join menu m
	on s.product_id = m.product_id
	left join members as me
	on s.customer_id = me.customer_id
	order by s.customer_id, s.order_date
	)
select *,
case when member = 'N' then null
	 else 
	 dense_rank() over(partition by customer_id, member order by order_date)
	 end as ranking
	 from cte
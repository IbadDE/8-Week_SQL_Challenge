
---------------------------------------------------------------- 1.High Level Sales Analysis ---------------------------------------------------------

ALTER TABLE sales
ADD COLUMN total decimal DEFAULT null;
UPDATE sales
SET total = qty*price;


--1: What was the total quantity sold for all products?
SELECT SUM(qty) as total_qunataty_sold
FROM sales;


--2: What is the total generated revenue for all products before discounts?
SELECT SUM(total) as total_revenue
FROM sales;


--3: What was the total discount amount for all products?
SELECT SUM(discount) as total_discount
FROM (SELECT txn_id, discount
		FROM sales
		GROUP BY 1,2) as t1;




select * from sales
select * from product_prices
select * from product_details
select * from product_hierarchy
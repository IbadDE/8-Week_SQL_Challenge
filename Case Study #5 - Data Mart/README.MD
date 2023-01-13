
# Case Study #5 - Data Mart

This is a part of **8 WEEK SQL CHALLANGE** Provided by **DANNY MA**.

These were the questions which were asked during this Challange.


#### 1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format

Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

Add a month_number with the calendar month for each week_date value as the 3rd column

Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees
Add a new demographic column using the following mapping for the first letter in the segment values:
segment	demographic
C	Couples
F	Families
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

#### 2. Data Exploration

What day of the week is used for each week_date value?

What range of week numbers are missing from the dataset?

How many total transactions were there for each year in the dataset?

What is the total sales for each region for each month?

What is the total count of transactions for each platform

What is the percentage of sales for Retail vs Shopify for each month?

What is the percentage of sales by demographic for each year in the dataset?

Which age_band and demographic values contribute the most to Retail sales?

Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

#### 3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

What about the entire 12 weeks before and after?

How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

#### 4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?



These questuon cab be found on this [website](https://8weeksqlchallenge.com/case-study-5/).

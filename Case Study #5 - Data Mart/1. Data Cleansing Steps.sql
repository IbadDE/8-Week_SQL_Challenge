

--------------------------------------------------------------- 1. Data Cleansing Steps --------------------------------------------------------------
-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
-- Convert the week_date to a DATE format
-- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-- Add a month_number with the calendar month for each week_date value as the 3rd column
-- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
-- Add a new demographic column using the following mapping for the first letter in the segment values:
-- ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record



ALTER TABLE weekly_sales
ALTER COLUMN week_date TYPE date USING to_date(week_date, 'DD/MM/YY')


ALTER TABLE weekly_sales
ADD COLUMN week_number varchar(3) DEFAULT null,
ADD COLUMN month_number decimal DEFAULT null,
ADD COLUMN year_number decimal DEFAULT null,
ADD COLUMN age_band varchar(20) DEFAULT null,
ADD COLUMN demographic varchar(20) DEFAULT null,
ADD COLUMN avg_transaction decimal DEFAULT null;
UPDATE weekly_sales
SET week_number = to_char(week_date, 'ww'),
	month_number = date_part('month', week_date),
	year_number = date_part('year', week_date),
	age_band = CASE WHEN segment LIKE '%1' THEN 'Young Adults'
				WHEN segment LIKE '%2' THEN 'Middle Aged'
				WHEN segment = 'null' THEN 'unknown'
				ELSE 'Retirees' END,
	demographic = CASE	WHEN segment LIKE 'C%' THEN 'Couples'
				WHEN segment LIKE 'F%' THEN 'Families'
				ELSE 'unknown' END,
	avg_transaction = ROUND((SALES/transactions::decimal),2);
	



ALTER TABLE weekly_sales
DROP COLUMN segment

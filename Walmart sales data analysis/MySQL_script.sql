use walmart_db;
show tables;

select * from walmart;

select count(distinct branch) from walmart;

-- Analyze Payment Methods and Sales

select
	payment_method,
    count(*) as number_of_transactions,
    sum(quantity) as total_quantity
from
	walmart
group by 1;

/* Identify the Highest-Rated Category in Each Branch */

-- Which category received the highest average rating in each branch?

with avg_rated_category as(
	select
		branch,
		category,
		avg(rating) as avg_rating,
        row_number() over(partition by branch order by avg(rating) desc) as row_numbers
	from
		walmart
	group by 1,2)
    
    select *
    from
		avg_rated_category
	where
		row_numbers=1;

/* Determine the Busiest Day for Each Branch */

-- What is the busiest day of the week for each branch based on transaction volume?

-- Add a new column for the weekday name
ALTER TABLE walmart
ADD weekday_name VARCHAR(20);

-- Update the new column with the weekday name
UPDATE walmart
SET weekday_name = DAYNAME(date);

with ranked_trxn_volume as(
	select 
		branch,
		weekday_name,
		count(*) as trxn_volum,
		rank() over(partition by branch order by count(*) desc) as ranks
	from
		walmart
	group by 1,2)

select *
from ranked_trxn_volume
where ranks = 1;
		
/* Analyze Category Ratings by City */

-- What are the average, minimum, and maximum ratings for each category in each city
select
	city,
	category,
	avg(rating) as avg_rating,
	min(rating) as min_rating,
    max(rating) as max_rating
from
	walmart
group by 1,2
order by city;

/* Total Profit by Category */

-- What is the total profit for each category, ranked from highest to lowest?

ALTER TABLE walmart
ADD total_profit double;

-- Update the new column with the total profit value
UPDATE walmart
SET total_profit = round(profit_margin*total_price, 2);

select
	category,
    sum(total_profit) as total_profits
from
	walmart
group by
	category
order by
	total_profits;
    
/* Determine the Most Common Payment Method per Branch */

-- What is the most frequently used payment method in each branch?

with ranked_payment_method as(
	select
		Branch,
		payment_method,
		count(*) as payment_frq,
		rank() over( partition by Branch order by count(*) desc) as ranks
	from
		walmart
	group by 1,2)

select *
from
	ranked_payment_method
where
	ranks = 1;
    
/* Analyze Sales Shifts Throughout the Day */

-- How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?

with
	trxn_count_by_hour AS(
		select
			Branch,
            HOUR(time) as sale_hour,
			count(*) as trxn_count
		from
			walmart
		group by Branch,HOUR(time)
		),
	sales_hour_shift AS(
		select
			Branch,
			(case
				when sale_hour < 12 then 'Morning'
				when sale_hour between 12 and 17 then 'Afternoon'
				else 'Evening'
			end) as work_hour_shift,
			trxn_count
		from
			trxn_count_by_hour)

select
	Branch,
    work_hour_shift,
	sum(trxn_count) as total_trxns
from
	sales_hour_shift
group by 1,2
order by 1;


/* Identify Branches with Highest Revenue Decline Year-Over-Year */

WITH yearly_sales AS (
    SELECT
        Branch,
        YEAR(date) AS trxn_year,
        ROUND(SUM(total_price), 2) AS total_sales_price
    FROM walmart
    GROUP BY Branch, YEAR(date)
),
sales_with_lag AS (
    SELECT
        Branch,
        trxn_year,
        total_sales_price,
        LAG(total_sales_price) OVER (PARTITION BY Branch ORDER BY trxn_year) AS prev_year_sales
    FROM yearly_sales
)
SELECT
    Branch,
    trxn_year,
    total_sales_price,
    prev_year_sales,
    ((total_sales_price - prev_year_sales)/prev_year_sales) AS pct_revenue_change
FROM sales_with_lag
WHERE prev_year_sales IS NOT NULL
	and trxn_year = 2023
    and ((total_sales_price - prev_year_sales)/prev_year_sales) < 0
ORDER BY pct_revenue_change ASC
limit 5;

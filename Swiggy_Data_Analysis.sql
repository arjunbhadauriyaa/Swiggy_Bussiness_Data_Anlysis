CREATE TABLE swiggy_restaurants_table (
    state VARCHAR(100),
    city VARCHAR(100),
    order_date DATE,
    restaurant_name VARCHAR(255),
    location VARCHAR(255),
    category VARCHAR(100),
    dish_name VARCHAR(255),
    price_inr DECIMAL(10,2),
    rating DECIMAL(2,1),
    rating_count INT
);

select * from  swiggy_restaurants_table

-- Data Cleaning and Validation
-- Null Check
select 
     sum(CASE WHEN state IS NULL THEN 1 ELSE 0 END) as null_state,
	 sum(CASE WHEN city IS NULL THEN 1 ELSE 0 END) as null_city,
	 sum(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) as null_order_date,
	 sum(CASE WHEN restaurant_name IS NULL THEN 1 ELSE 0 END) as null_restaurant_name,
     sum(CASE WHEN location IS NULL THEN 1 ELSE 0 END) as null_location,
	 sum(CASE WHEN category IS NULL THEN 1 ELSE 0 END) as null_category,
	 sum(CASE WHEN dish_name IS NULL THEN 1 ELSE 0 END) as null_dish_name,
	 sum(CASE WHEN price_inr IS NULL THEN 1 ELSE 0 END) as null_price_inr,
     sum(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) as null_rating,
	 sum(CASE WHEN rating_count IS NULL THEN 1 ELSE 0 END) as null_rating_count

	 from  swiggy_restaurants_table; 


-- Blank or Empty Strings

select * from  swiggy_restaurants_table
where 
State='' or city='' or restaurant_name='' or location=''or 
category='' or dish_name='';



-- Duplication Detection

select
state,city,order_date,restaurant_name,location,category,
dish_name,price_INR,rating,rating_count,count(*) as Count
from swiggy_restaurants_table
group by
state,city,order_date,restaurant_name,location,category,
dish_name,price_INR,rating,rating_count
having count(*)>1

-- We see here 27 data is duplicate

-- Delete Duplicate
 -- To check for the duplicate only
WITH cte AS (
    SELECT 
        ctid,
        ROW_NUMBER() OVER (
            PARTITION BY state, city, order_date,
                         restaurant_name, location,
                         category, dish_name,
                         price_inr, rating, rating_count
            ORDER BY ctid
        ) AS rn
    FROM swiggy_restaurants_table
)

SELECT *
FROM cte
WHERE rn > 1;


-- To Delete the Actual Duplicates
BEGIN;

WITH cte AS (
    SELECT ctid,ROW_NUMBER() OVER (PARTITION BY state, city, order_date,
                         restaurant_name, location,
                         category, dish_name,
                         price_inr, rating, rating_count ORDER BY ctid) AS rn
FROM swiggy_restaurants_table)
DELETE FROM swiggy_restaurants_table
WHERE ctid IN (
    SELECT ctid
    FROM cte
    WHERE rn > 1);
COMMIT;



-- CREATING SCHEMA
-- CREATING DIMENSION TABLE
-- DATE TABLE

Create table dim_date(
date_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Full_date Date,
Year Int,
Month int,
Month_Name varchar(20),
Quarter int,
Day int,
Week int)

select * from dim_date

-- dim_location

create table dim_location(
location_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
state  varchar(100),
city varchar(100),
location varchar(200))

-- dim_restaurant

create table dim_restaurant(
restaurant_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Restaurant_name varchar(200)   )


-- dim_category

create table dim_category(
category_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Category varchar(200)
)

-- dim dish

create table dim_dish(
dish_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
Dish_name varchar(200)
)

-- fact Table

create table fact_swiggy_orders(
order_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

date_id int,
price_inr decimal(10,2),
rating decimal(4,2),
rating_count int,

location_id int,
restaurant_id int,
category_id int,
dish_id int,

foreign key (date_id) references dim_date(date_id),
foreign key (location_id) references dim_location(location_id),
foreign key (restaurant_id) references dim_restaurant(restaurant_id),
foreign key (category_id) references dim_category(category_id),
foreign key (dish_id) references dim_dish(dish_id)
)


select * from fact_swiggy_orders


-- Insert data in tables
-- dim location
INSERT INTO dim_location (state, city, location)
SELECT DISTINCT state,city,location
FROM swiggy_restaurants_table
ORDER BY state, city, location;

-- dim resaturant
INSERT INTO dim_restaurant (restaurant_name)
SELECT DISTINCT restaurant_name
FROM swiggy_restaurants_table
ORDER BY restaurant_name;

-- dim category

INSERT INTO dim_category (category)
SELECT DISTINCT category
FROM swiggy_restaurants_table
ORDER BY category;

-- dim restaurant
INSERT INTO dim_dish (dish_name)
SELECT DISTINCT dish_name
FROM swiggy_restaurants_table
ORDER BY dish_name;

-- dim_date
INSERT INTO dim_date (full_date,year,month,month_name,quarter,day,week)
SELECT DISTINCT
    order_date,
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date),
    TO_CHAR(order_date, 'Month'),
    EXTRACT(QUARTER FROM order_date),
    EXTRACT(DAY FROM order_date),
    EXTRACT(WEEK FROM order_date)
FROM swiggy_restaurants_table
WHERE order_date IS NOT NULL
ORDER BY order_date;

select * from dim_date

-- dim fact_swiggy_orders
INSERT INTO fact_swiggy_orders (
    date_id,
    price_inr,
    rating,
    rating_count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)

SELECT
    dd.date_id,
    s.price_inr,
    s.rating,
    s.rating_count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id

FROM swiggy_restaurants_table s

JOIN dim_date dd
ON dd.full_date = s.order_date

JOIN dim_location dl
ON dl.state = s.state
AND dl.city = s.city
AND dl.location = s.location

JOIN dim_restaurant dr
ON dr.restaurant_name = s.restaurant_name

JOIN dim_category dc
ON dc.category = s.category

JOIN dim_dish dsh
ON dsh.dish_name = s.dish_name;


select * from fact_swiggy_orders

select count(*) from fact_swiggy_orders


select * from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
join dim_location l on f.location_id=l.location_id
join dim_restaurant r on f.restaurant_id=r.restaurant_id
join dim_category c on f.category_id=c.category_id
join dim_dish di on f.dish_id=di.dish_id
-- By this complte table is form

-- Untill we doing only data cleaning and data preprocessing

-- KPI Questions for Swiggy Data Analytics and Bussiness Requirement

-- What is the total number of orders placed on the platform?
select count(*) as  Total_Orders
from fact_swiggy_orders


-- What is the revenue generated in INR(Indian National Rupees) Millions?
SELECT 
ROUND(SUM(price_inr)::NUMERIC / 1000000, 2) || ' INR Million' AS Total_revenue
FROM fact_swiggy_orders;


--  What is the average selling price of dishes?
SELECT 
ROUND(avg(price_inr)::NUMERIC, 2) || ' INR' AS  Average_Dish_Price
FROM fact_swiggy_orders;



-- What is the average customer rating across all dishes?
select 
round(avg(rating),2) as Avg_Rating
from fact_swiggy_orders


-- Deep-Dive Business Analysis

-- How do order volumes vary month-wise? (Monthly order trends) as per Total_Revenue

select
d.year,
d.month,
d.month_name,
sum(price_inr) as Total_Revenue
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year,d.month,d.month_name
order by sum(price_inr) asc

 -- How do order volumes vary month-wise? (Monthly order trends) as per Total_order
select
d.year,
d.month,
d.month_name,
count(*) as Total_orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year,d.month,d.month_name
order by Total_orders asc


--  Which quarter has the highest customer engagement? (Quarterly order trends)

select
d.year,
d.quarter,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year,d.quarter
order by Total_Orders  desc

--  What is the year-over-year growth in orders? (Year-wise growth) as per revenue
select
d.year,
sum(price_inr) as Total_Revenue
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year
order by sum(price_inr)

-- What is the year-over-year growth in orders? (Year-wise growth) as per orders
select
d.year,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by d.year
order by count(*) asc

-- Which weekday receives the highest number of orders?

SELECT 
    TRIM(TO_CHAR(d.full_date, 'Day')) AS day_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d 
    ON f.date_id = d.date_id
GROUP BY 
    TRIM(TO_CHAR(d.full_date, 'Day')),
    EXTRACT(DOW FROM d.full_date)
ORDER BY 
    EXTRACT(DOW FROM d.full_date) desc

-- Which are the top 10 cities by order volume?

select 
l.city,
count(*) as Total_orders from fact_swiggy_orders f
join dim_location l
on
l.location_id=f.location_id
group by l.city
order by count(*) desc limit 10

-- Which regions show strong food delivery demand?

select 
l.city,
sum(f.price_inr) as Total_revenue from fact_swiggy_orders f
join dim_location l
on
l.location_id=f.location_id
group by l.city
order by sum(f.price_inr) desc limit 10

-- Which states contribute the most to total revenue?

select 
l.state,
sum(f.price_inr) as Total_revenue from fact_swiggy_orders f
join dim_location l
on
l.location_id=f.location_id
group by l.state
order by sum(f.price_inr) desc 


-- Food Performance bussiness Analysis of swiggy

-- Which restaurants receive the highest number of orders?(Top 10)
select 
r.restaurant_name,
count(*) as Total_orders from fact_swiggy_orders f
join dim_restaurant r
on
r.restaurant_id=f.restaurant_id
group by r.restaurant_name
order by count(*) desc limit 10

-- Which cuisine category is most popular?
select 
c.category,
count(*) as Total_orders from fact_swiggy_orders f
join dim_category c
on
c.category_id=f.category_id
group by c.category
order by count(*) desc 


-- What are the most ordered dishes?
select 
d.dish_name,
count(*) as Order_count
from fact_swiggy_orders f
join dim_dish d
on
d.dish_id=f.dish_id
group by d.dish_name
order by Order_count desc 

-- Which cuisine balances both high orders and high ratings?


select 
c.category,
count(*) as Total_orders,
round(avg(f.rating),2) as avg_rating
from fact_swiggy_orders f
join dim_category c on f.category_id=c.category_id
group by c.category
order by Total_Orders desc;

-- How are customer orders distributed across spending ranges?

SELECT
    CASE
        WHEN price_inr::FLOAT < 100 THEN 'Under 100'
        WHEN price_inr::FLOAT BETWEEN 100 AND 199 THEN '100-199'
        WHEN price_inr::FLOAT BETWEEN 200 AND 299 THEN '200-299'
        WHEN price_inr::FLOAT BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END AS price_range,

    COUNT(*) AS total_orders

FROM fact_swiggy_orders

GROUP BY
    CASE
        WHEN price_inr::FLOAT < 100 THEN 'Under 100'
        WHEN price_inr::FLOAT BETWEEN 100 AND 199 THEN '100-199'
        WHEN price_inr::FLOAT BETWEEN 200 AND 299 THEN '200-299'
        WHEN price_inr::FLOAT BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END

ORDER BY total_orders DESC;


-- Rating Count Distribution
select rating,
              count(*) as rating_count
			  from fact_swiggy_orders
			  group by rating
			  order by rating

--  
-- 
-- 
-- 
-- 
-- 
-- 
-- 
-- 
-- 














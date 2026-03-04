select * 
from [sql work].dbo.[gold.fact_sales];

--analyze sales performance over time
select order_date,sum(sales_amount) as total_sales
from [sql work].dbo.[gold.fact_sales]
where order_date is not null
group by order_date
order by order_date ;

select year(order_date) as order_year
,sum(sales_amount) as total_sales
from [sql work].dbo.[gold.fact_sales]
where order_date is not null
group by year(order_date)
order by year(order_date) ;


select year(order_date) as order_year
,sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [sql work].dbo.[gold.fact_sales]
where order_date is not null
group by year(order_date)
order by year(order_date);


select year(order_date) as order_year,
month(order_date) as order_month
,sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [sql work].dbo.[gold.fact_sales]
where order_date is not null
group by month(order_date), year(order_date)
order by month(order_date),year(order_date)
;

---commulative analysis
select order_date, total_sales,
sum(total_sales) over (partition by order_date order by order_date) as running_total_sales
from
(
select datetrunc(month,order_date) as order_date,
sum(sales_amount) as total_sales
from [sql work].dbo.[gold.fact_sales]
where order_date is not null 
group by datetrunc(month,order_date)
)t


select order_date, total_sales,
sum(total_sales) over ( order by order_date) as running_total_sales,
avg(avg_price) over (order by order_date) as moving_avg_price
from
(
select datetrunc(YEAR,order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from [sql work].dbo.[gold.fact_sales]
where order_date is not null 
group by datetrunc(year,order_date)
)t

--performance analysis 

with yearly_sales as
(
select 
year(f.order_date) as order_year, p.product_name,sum(f.sales_amount) as current_sales
from [sql work].dbo.[gold.fact_sales] as f
left join [sql work].dbo.[gold.dim_products] as p
on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name
)
select order_year,product_name,current_sales,
avg(current_sales) over (partition by product_name ) as moving_avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
ELSE 'Avg'
END avg_change,
lag(current_sales) over (partition by product_name order by order_year) as previous_year_sales,
current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_previous_year,
CASE WHEN current_sales - lag(current_sales) over (partition by product_name order by order_year    
) > 0 THEN 'Above Previous Year'
WHEN current_sales - lag(current_sales) over (partition by product_name order by order_year) < 0 THEN 'Below Previous Year'
ELSE 'Same as Previous Year'
END previous_year_change
FROM yearly_sales
ORDER BY product_name, order_year
;
 
 ---- part to whole


with category_sales as (
SELECT
category,
sum(sales_amount) as total_sales
FROM [sql work].dbo.[gold.fact_sales] f
LEFT JOIN [sql work].dbo.[gold.dim_products] p
ON p.product_key = f.product_key 
group by category
)
select category,total_sales,
SUM(total_sales) OVER () overall_sales,
concat(round((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100,2) , '%' ) AS percentage_of_total
from category_sales
group by category,total_sales  
order by percentage_of_total desc;


with product_segmentation as (
SELECT
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
WHEN cost BETWEEN 100 AND 500 THEN '100-500'
WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
ELSE 'Above 1000'
END cost_range
FROM [sql work].dbo.[gold.dim_products]
)
select cost_range,
count(product_key) as total_products
from product_segmentation
group by cost_range
order by cost_range desc;


WITH customer_spending AS (
SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX (order_date) AS last_order,
DATEDIFF (month, MIN(order_date), MAX(order_date)) AS lifespan
FROM [sql work].dbo.[gold.fact_sales] f
LEFT JOIN [sql work].dbo.[gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key 
)
select
customer_key,
total_spending,
lifespan,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
ELSE 'New'
END customer_segment
FROM customer_spending;





WITH customer_spending AS (
SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX (order_date) AS last_order,
DATEDIFF (month, MIN(order_date), MAX(order_date)) AS lifespan
FROM [sql work].dbo.[gold.fact_sales] f
LEFT JOIN [sql work].dbo.[gold.dim_customers] c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key 
)
SELECT
customer_segment,
COUNT (customer_key) AS total_customers
FROM (
select
customer_key,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
ELSE 'New'
END customer_segment
FROM customer_spending)t
group by customer_segment
order by total_customers desc;

--CUSTOMER REPORT  
USE [sql work]
GO 
create view dbo.customer_report_gold as
with base_query as (
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, c.last_name) AS customer_name,
datediff(year,c.birthdate, getdate()) as customer_age
FROM [sql work].dbo.[gold.fact_sales] f
LEFT JOIN [sql work].dbo.[gold.dim_customers] c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
)
,customer_aggregation AS 
(
select 
customer_key,
customer_number,
customer_name,
customer_age,
COUNT (DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT (DISTINCT product_key) AS total_products,
max(order_date) as last_order_date,
datediff(month,min(order_date), max(order_date)) as customer_lifespan_months
from base_query
group by customer_key,
customer_number, 
customer_name, 
customer_age
)
SELECT
customer_key,
customer_number,
customer_name,
customer_age,
CASE
WHEN customer_age < 20 THEN 'Under 20'
WHEN customer_age between 20 and 29 THEN '20-29'
WHEN customer_age between 30 and 39 THEN '30-39'
WHEN customer_age between 40 and 49 THEN '40-49'
ELSE '50 and above' 
END AS age_group,
CASE
WHEN customer_lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
WHEN customer_lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
ELSE 'New'
END AS customer_segment,
total_orders,
total_sales,
total_quantity,
total_products,
last_order_date,
DATEDIFF (month, last_order_date, GETDATE()) AS recency,
customer_lifespan_months,
CASE WHEN total_sales = 0 THEN 0
ELSE total_sales / total_orders
end as avg_order_value,
case when customer_lifespan_months = 0 then total_sales
else total_sales / customer_lifespan_months
end as avg_monthly_sales
FROM customer_aggregation;


--PRODUCT REPORT
use [sql work]
go
create view dbo.product_report as
with base_query as (
SELECT
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_name, 
p.product_key,
p.category,
p.subcategory,
p.cost
FROM [sql work].dbo.[gold.fact_sales] f
LEFT JOIN [sql work].dbo.[gold.dim_products] p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL 
),
product_aggregation AS (
SELECT
product_key,
product_name,
category,
subcategory,
cost,
	DATEDIFF (MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
	MAX (order_date) AS last_sale_date,
	COUNT (DISTINCT order_number) AS total_orders,
	COUNT (DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND (AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query
GROUP BY
product_key,
product_name,
category,
subcategory,
cost
)

SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
datediff(month, last_sale_date, getdate()) as recency_in_months,
case 
	when total_sales > 50000 then 'Best Seller'
	when total_sales >=10000  then 'Average Seller'
	else 'Low Seller'
end as product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
case 
	when total_orders = 0 then 0
	else total_sales / total_orders
	end as avg_order_value,
case 
	when lifespan = 0 then total_sales
	else total_sales / lifespan
	end as avg_monthly_sales
FROM product_aggregation


select * from dbo.product_report;

select * from dbo.customer_report_gold;
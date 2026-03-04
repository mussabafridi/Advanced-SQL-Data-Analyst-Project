Sales & Customer Strategic Analytics (T-SQL)
Project Overview
This repository contains a comprehensive SQL-based data analysis project designed to transform raw transactional data into high-level business intelligence. The project utilizes a Gold Layer architecture to provide a "single source of truth" for sales performance, customer behavior, and product lifecycle metrics.

Key Technical Features
Time-Series Analysis: Implemented monthly and yearly sales trends using DATETRUNC and GROUP BY functions to track growth.

Advanced Window Functions: Developed cumulative "Running Totals" and "Moving Averages" to benchmark current performance against historical data.

RFM-Based Segmentation: Built logic to classify customers into VIP, Regular, or New categories based on spending thresholds (e.g., > 5000) and relationship lifespan.

Automated Reporting Views: Created permanent SQL Views (dbo.customer_report_gold and dbo.product_report) to automate complex calculations like Average Order Value (AOV) and Recency.

Product Performance Matrix: Categorized products into "Best Seller," "Average Seller," or "Low Seller" based on total revenue contributions.

Repository Structure
SQLQuery6.sql: The primary script containing the data transformation pipeline, CTEs, and View creation.

README.md: Project documentation, business insights, and technical details.

Business Logic & Metrics
The analysis provides answers to critical business questions:

Who are our most valuable customers? (Based on lifespan and total spending).

Which products are driving the most revenue? (Segmented by category and subcategory).

How is our sales momentum changing? (Year-over-Year comparison and Running Totals).

What is the demographic breakdown of our sales? (Segmented by age groups).

Technical Stack
Language: T-SQL (SQL Server)

Key Concepts: CTEs, Window Functions (OVER, PARTITION BY, LAG), Joins, Data Aggregation, and View Schema Design.

#1. Provide the list of markets in which customer "Atliq Exclusive" operates its
#business in the APAC region.
select distinct(market) as APAC_AtliqExclusive_Markets
from dim_customer
where customer = "Atliq Exclusive"
and region='APAC';

#2.What is the percentage of unique product increase in 2021 vs. 2020? The
#final output contains these fields,
#unique_products_2020
#unique_products_2021
#percentage_chg

with cte1 as
(
select count(distinct(product_code)) as unique_products_2020
 from fact_sales_monthly 
where fiscal_year = 2020 and 
sold_quantity>0
),
cte2 as
(
select count(distinct(product_code)) as unique_products_2021
from fact_sales_monthly 
where fiscal_year = 2021 and 
sold_quantity>0
)
select cte1.unique_products_2020 , 
		cte2.unique_products_2021,
        round(((cte2.unique_products_2021-cte1.unique_products_2020)/cte1.unique_products_2020)*100,2) as percentage_chg
from cte1, cte2;

#3. Provide a report with all the unique product counts for each segment and
#sort them in descending order of product counts. The final output contains
#2 fields,
#segment
#product_count
select segment,count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

#4. Follow-up: Which segment had the most increase in unique products in
#2021 vs 2020? The final output contains these fields,
#segment
#product_count_2020
#product_count_2021
#difference
with cte1 as
(
select
		p.segment, 
		count(distinct(s.product_code)) as unique_products_2020
from fact_sales_monthly s
join dim_product p on p.product_code = s.product_code
where s.fiscal_year = 2020 and s.sold_quantity>0
group by p.segment
),
cte2 as
(
select 
		p.segment,
		count(distinct(s.product_code)) as unique_products_2021
from fact_sales_monthly s
join dim_product p on p.product_code = s.product_code
where s.fiscal_year = 2021 and s.sold_quantity>0
group by p.segment
)
select
		cte1.segment,
        #cte2.segment,
        cte2.unique_products_2021,
		cte1.unique_products_2020 , 
		
        cte2.unique_products_2021-cte1.unique_products_2020 as difference
       
from cte1, cte2 where cte1.segment = cte2.segment
group by cte1.segment 
order by difference desc;

#5. Get the products that have the highest manufacturing costs.
#The final output should contain these fields,
#product_code
#product
#manufacturing_cost
with cte1 as
(
select product_code,
		product,
        manufacturing_cost
from fact_manufacturing_cost 
join dim_product using(product_code)
order by manufacturing_cost desc
)
SELECT * from cte1
where manufacturing_cost in(
							(select max(manufacturing_cost) from cte1),
                            (select min(manufacturing_cost) from cte1)
                            )

#6. Generate a report which contains the top 5 customers who received an
#average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#Indian market. The final output contains these fields,
#customer_code
#customer
#average_discount_percentage
select 
	c.customer_code,
    c.customer,
    round(avg(pre.pre_invoice_discount_pct)*100,2) as Average_Discount_Percentage
    #round(Avg(pre.pre_invoice_discount_pct),2) as average_discount_percentage
from fact_pre_invoice_deductions as pre
join dim_customer c on c.customer_code = pre.customer_code
where pre.fiscal_year = 2021 and c.market='India'
group by c.customer_code , c.customer
order by average_discount_percentage desc
limit 5;

#7. Get the complete report of the Gross sales amount for the customer “Atliq
#Exclusive” for each month. This analysis helps to get an idea of low and
#high-performing months and take strategic decisions.
#The final report contains these columns:
#Month
#Year
#Gross sales Amount
select
	monthname(s.date) as Month, s.fiscal_year as Year,
    round((sum(s.sold_quantity * g.gross_price)/1000000),2) as Gross_Sale_Amount_Mil
 from fact_sales_monthly s
join fact_gross_price g on g.fiscal_year=s.fiscal_year and
	g.product_code=s.product_code
join dim_customer c on c.customer_code=s.customer_code
where c.customer = 'Atliq Exclusive'
group by monthname(s.date) , s.fiscal_year
order by year;


#8. In which quarter of 2020, got the maximum total_sold_quantity? The final
#output contains these fields sorted by the total_sold_quantity,
#Quarter
#total_sold_quantity

with cte1 as
(
SELECT
    fiscal_year,
    CASE
        WHEN MONTH(date) in(9,10,11) THEN 'Q1'
        WHEN MONTH(date) in(12,01,02) THEN 'Q2'
        WHEN MONTH(date) in(3,4,5) THEN 'Q3'
        WHEN MONTH(date) in(6,7,8) THEN 'Q4'
    END AS quarter,
    sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020

ORDER BY
    quarter
)
select quarter, sum(sold_quantity) as total_sold_qty from cte1
group by quarter
order by total_sold_qty desc;

#9. Which channel helped to bring more gross sales in the fiscal year 2021
#and the percentage of contribution? The final output contains these fields,
#channel
#gross_sales_mln
#percentage
with cte1 as
(
select 
		c.channel,
        round((sum(s.sold_quantity * g.gross_price))/1000000,2) as gross_sales_mln
from fact_sales_monthly s
join fact_gross_price g on g.product_code = s.product_code and
							g.fiscal_year = s.fiscal_year
join dim_customer c on c.customer_code = s.customer_code
where s.fiscal_year = 2021
group by c.channel
)
select 
		cte1.channel,
        cte1.gross_sales_mln,
        round((cte1.gross_sales_mln *100 / (select sum(cte1.gross_sales_mln) from cte1)),2) as percentage
from cte1 
group by cte1.channel
order by cte1.gross_sales_mln desc;

#10. Get the Top 3 products in each division that have a high
#total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields,
#division
#product_code
#product
#total_sold_qty
#rank_order
with cte1 as 
(
select 
	p.division,
    p.product_code,
    p.product,
    sum(s.sold_quantity) as total_sold_qty
 from fact_sales_monthly s
join dim_product p on p.product_code = s.product_code
where s.fiscal_year= 2021 
group by p.division, p.product_code, p.product 
),
cte2 as
( 
select *,
		dense_rank() over(partition by cte1.division order by cte1.total_sold_qty desc) as Rank_Order
from cte1
)
select * from cte2 where cte2.rank_order <=3;


--Look tables

SELECT * FROM market_fact
SELECT * FROM cust_dimen
SELECT * FROM orders_dimen
SELECT * FROM prod_dimen
SELECT * FROM shipping_dimen

--1.join all the tables and create a new table called combined_table(market_fact,cust_dimen,orders_dimen,prod_dimen,shipping_dimen)

--Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”, 
--“prod_dimen”, “shipping_dimen”, Create a new table, named as
--“combined_table”. 

SELECT  cd.*, od.*, pd.*, sd.* ,
        mf.Sales, mf.Discount, mf.Order_Quantity, mf.Product_Base_Margin
FROM    market_fact mf, cust_dimen cd, orders_dimen od, prod_dimen pd, shipping_dimen sd
WHERE   mf.Cust_id=cd.Cust_id
        and mf.Ord_id=od.Ord_id
        and mf.Prod_id=pd.Prod_id
        and mf.Ship_id=sd.Ship_id
order by 1

SELECT * INTO combined_table 
FROM
    (SELECT  cd.*, od.*, pd.*, sd.* ,
        mf.Sales, mf.Discount, mf.Order_Quantity, mf.Product_Base_Margin
FROM    market_fact mf, cust_dimen cd, orders_dimen od, prod_dimen pd, shipping_dimen sd
WHERE   mf.Cust_id=cd.Cust_id
        and mf.Ord_id=od.Ord_id
        and mf.Prod_id=pd.Prod_id
        and mf.Ship_id=sd.Ship_id
)A
;


SELECT * 
FROM combined_table

--2. Find the top 3 customers who have the maximum count of orders.

   
SELECT TOP 3 Cust_id , Customer_Name, COUNT(distinct Ord_id) AS count_order
FROM combined_table
GROUP BY Cust_id, Customer_Name
ORDER BY count_order DESC;

--3. Create a new column at combined_table as DaysTakenForDelivery 
--that contains the data difference of Order_Date and Ship_Date

ALTER TABLE combined_table
ADD DaysTakenForDelivery INT;

UPDATE combined_table
SET DaysTakenForDelivery = DATEDIFF(day, Order_Date, Ship_date)

SELECT * FROM combined_table

--4. Find the customer whose order took the maximum time to get delivered.

SELECT TOP 1 Cust_id,Customer_Name, DaysTakenForDelivery 
FROM combined_table
ORDER BY DaysTakenForDelivery DESC

--5.Count the total number of unique customers in January and how many of them 
--came back every month over the entire year in 2011


SELECT DISTINCT Cust_id,Customer_Name
FROM combined_table
WHERE YEAR(Order_Date) = 2011 AND MONTH(Order_Date) =1


----
--6. Write a query to return for each user the time elapsed between the first 
--purchasing and the third purchasing, in ascending order by Customer ID



SELECT DISTINCT Cust_id,
		Order_date,
		dense_num,
		first_ord_date,
		DATEDIFF(day, first_ord_date, order_date) AS Date_diff

FROM (SELECT Cust_id, Order_Date,
			MIN (Order_Date) OVER (PARTITION BY Cust_id) AS first_ord_date,
			DENSE_RANK () OVER (PARTITION BY Cust_id ORDER BY Order_date) AS dense_num
FROM combined_table) A
WHERE	dense_num = 3




--7.Write a query that returns customers who purchased both product 11 and 
--product 14, as well as the ratio of these products to the total number of 
--products purchased by the customer.



SELECT * FROM combined_table

SELECT Cust_id,
       SUM(CASE WHEN Prod_id = 11 THEN Order_Quantity ELSE 0 END) AS P11,
	   SUM(CASE WHEN Prod_id = 14 THEN Order_Quantity ELSE 0 END) AS P14,
	   SUM(Order_Quantity) AS Sum_prod,
       ROUND(CAST(SUM(CASE WHEN Prod_id = 11 THEN Order_Quantity ELSE 0 END) AS FLOAT)/ SUM(Order_Quantity),2 )AS ratio_11,
	   ROUND(CAST(SUM(CASE WHEN Prod_id = 14 THEN Order_Quantity ELSE 0 END) AS FLOAT) / SUM(Order_Quantity),2) AS ratio_14

FROM combined_table
--WHERE Prod_id in(11,14)

WHERE Cust_id IN (SELECT Cust_id
                 FROM combined_table
                  WHERE Prod_id IN (11,14) 
                  GROUP BY Cust_id
				  HAVING COUNT(DISTINCT Prod_id)=2)
GROUP BY Cust_id;


--CUSTOMER SEGMENTATION

--1. Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)

CREATE VIEW visit_log_of_customer AS 

SELECT distinct cust_id,
				DATEPART(YEAR,Order_Date) AS [YEAR],
				DATEPART(MONTH, Order_date) AS [MONTH]
				
FROM combined_table

SELECT * FROM visit_log_of_customer


--2. Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)

CREATE VIEW monthly_visit AS

      
SELECT Cust_id, [YEAR], [MONTH],
       COUNT(*) as count_of_month_visits
	      
       FROM visit_log_of_customer
       GROUP BY Cust_id, [YEAR], [MONTH]

SELECT * FROM monthly_visit


	    
--3.For each visit of customers, create the next month of the visit as a separate column

SELECT Cust_id,[YEAR],[MONTH],

   LEAD([MONTH]) OVER (PARTITION BY Cust_id, [YEAR] ORDER BY [MONTH]) AS next_month

FROM monthly_visit
	

--4.Calculate the monthly time gap between two consecutive visits by each customer.

SELECT * , next_month - count_of_month_visits AS a

FROM monthly_visit


--SQL Advance Case Study
SELECT * FROM DIM_CUSTOMER;
SELECT * FROM DIM_DATE;
SELECT * FROM DIM_LOCATION;
SELECT * FROM DIM_MANUFACTURER;
SELECT * FROM DIM_MODEL;
SELECT * FROM FACT_TRANSACTIONS;

--Q1--BEGIN 
--List all the states in which we have customers who have bought cellphones  from 2005 till today. 
	select distinct state
	from (
	select k.state, sum(quantity) as total_qty , year(p.date) as years
	from FACT_TRANSACTIONS p
	left join DIM_LOCATION k
	on p.IDLocation =k.IDLocation
	where year(p.date)>= '2005'
	group by k.state, year(p.date)
	) as h;







--Q1--END

--Q2--BEGIN
---What state in the US is buying the most 'Samsung' cell phones?
select top 1 state, count(*) as cnt from DIM_LOCATION p
join FACT_TRANSACTIONS d
on p.IDLocation=d.IDLocation 
join DIM_MODEL h
on d.IDModel=h.IDModel
join DIM_MANUFACTURER g
on h.IDManufacturer=g.IDManufacturer
where country = 'us' and Manufacturer_Name= 'samsung'
group by state 
order by cnt desc;	









--Q2--END

--Q3--BEGIN -Show the number of transactions for each model per zip code per state.     
	select h.Model_Name, g.zipcode, g.state, count(p.IDModel) as number_transaction 
	from FACT_TRANSACTIONS p
	join DIM_LOCATION g
	on g.IDLocation=p.IDLocation
	join DIM_MODEL h
	on p.IDModel=h.IDModel
	group by  h.Model_Name, g.zipcode, g.state;












--Q3--END

--Q4--BEGIN Show the cheapest cellphone (Output should contain the price also) 
select top 1 model_name, min(unit_price) as cheap_price
from FACT_TRANSACTIONS p
join DIM_MODEL h
on p.IDModel = h.IDModel
group by Model_Name
order by cheap_price;





--Q4--END

--Q5--BEGIN- Find out the average price for each model in the top5 manufacturers in  
--terms of sales quantity and order by average price. 
select P.IDMODEL, AVG(TOTALPRICE) AS AVG_PRICE, SUM(QUANTITY) AS TOTAL_SALES
FROM FACT_TRANSACTIONS P
JOIN DIM_MODEL H
ON P.IDModel=H.IDModel
JOIN DIM_MANUFACTURER J
ON J.IDManufacturer=H.IDManufacturer
WHERE Manufacturer_Name IN ( SELECT TOP 5 MANUFACTURER_NAME
FROM FACT_TRANSACTIONS P
JOIN DIM_MODEL H
ON P.IDModel=H.IDModel
JOIN DIM_MANUFACTURER J
ON J.IDManufacturer=H.IDManufacturer
GROUP BY Manufacturer_Name
ORDER BY SUM(TOTALPRICE) DESC)
Group By P.IDModel
order by avg_price Desc;
















--Q5--END

--Q6--BEGIN List the names of the customers and the average amount spent in 2009,  
--where the average is higher than 500
SELECT H.Customer_Name, AVG(TOTALPRICE) AS AVG_AMOUNT 
FROM FACT_TRANSACTIONS P
JOIN DIM_CUSTOMER H
ON H.IDCustomer=P.IDCustomer 
WHERE YEAR(DATE)= 2009
GROUP BY H.Customer_Name
HAVING AVG(TOTALPRICE)>500;












--Q6--END
	
--Q7--BEGIN  List if there is any model that was in the top 5 in terms of quantity,  
--simultaneously in 2008, 2009 and 2010
WITH TOP_5_2008 AS
(
SELECT TOP 10 T.IDModel,M.Model_Name
FROM FACT_TRANSACTIONS T
JOIN 
dIM_MODEL M
ON T.IDModel = M.IDModel
WHERE YEAR(T.Date) = 2008
Group by T.IDModel,M.Model_Name
ORDER BY COUNT(T.Quantity) DESC
),
TOP_5_2009 AS
(
SELECT TOP 10 T.IDModel,M.Model_Name
FROM FACT_TRANSACTIONS T
JOIN 
dIM_MODEL M
ON T.IDModel = M.IDModel
WHERE YEAR(T.Date) = 2009
Group by T.IDModel,M.Model_Name
ORDER BY COUNT(T.Quantity) DESC
),
TOP_5_2010 AS
(
SELECT TOP 10 T.IDModel,M.Model_Name
FROM FACT_TRANSACTIONS T
JOIN 
dIM_MODEL M
ON T.IDModel = M.IDModel
WHERE YEAR(T.Date) = 2010
Group by T.IDModel,M.Model_Name
ORDER BY COUNT(T.Quantity) DESC
)
SELECT Model_Name FROM TOP_5_2008
INTERSECT
SELECT Model_Name FROM TOP_5_2009
INTERSECT
SELECT Model_Name FROM TOP_5_2010;
	
















--Q7--END	
--Q8--BEGIN--Show the manufacturer with the 2nd top sales in the year of 2009 and the  
--manufacturer with the 2nd top sales in the year of 2010.
SELECT * FROM(
		SELECT Top 1 * FROM
		(
			SELECT TOP 2 Manufacturer_Name,YEAR(T.Date) as year,sum(TotalPrice) as Total_sales
			FROM FACT_TRANSACTIONS T
			JOIN
			DIM_MODEL M
			ON T.IDModel=M.IDModel
			JOIN
			DIM_MANUFACTURER U
			ON M.IDManufacturer=U.IDManufacturer
			WHERE YEAR(T.Date)= 2009 
			GROUP BY U.Manufacturer_Name,YEAR(T.Date)
			order By Total_sales DESC
		) AS A
		order by Total_sales
) AS t2
UNION
SELECT * FROM(
			SELECT Top 1 * FROM
			(
				SELECT TOP 2 Manufacturer_Name,YEAR(T.Date) as year,sum(TotalPrice) as Total_sales
				FROM FACT_TRANSACTIONS T
				JOIN
				DIM_MODEL M
				ON T.IDModel=M.IDModel
				JOIN
				DIM_MANUFACTURER U
				ON M.IDManufacturer=U.IDManufacturer
				WHERE YEAR(T.Date)= 2010 
				GROUP BY U.Manufacturer_Name,YEAR(T.Date)
				order By Total_sales DESC
			) AS A
			order by Total_sales
) as t2;


















--Q8--END
--Q9--BEGIN--Show the manufacturers that sold cellphones in 2010 but did not in 2009.
	
(SELECT  M.IDManufacturer,U.Manufacturer_Name
FROM FACT_TRANSACTIONS T
JOIN
DIM_MODEL M
ON T.IDModel=M.IDModel
JOIN
DIM_MANUFACTURER U
ON M.IDManufacturer=U.IDManufacturer
WHERE YEAR(T.Date)= 2010 
GROUP BY M.IDManufacturer,U.Manufacturer_Name)
EXCEPT
(SELECT  M.IDManufacturer,U.Manufacturer_Name
FROM FACT_TRANSACTIONS T
JOIN
DIM_MODEL M
ON T.IDModel=M.IDModel
JOIN
DIM_MANUFACTURER U
ON M.IDManufacturer=U.IDManufacturer
WHERE YEAR(T.Date)= 2009 
GROUP BY M.IDManufacturer,U.Manufacturer_Name);

















--Q9--END

--Q10--BEGINFind top 100 customers and their average spend, average quantity by each  
-- year. Also find the percentage of change in their spend.
SELECT *,((avg_price - lag_price)/lag_price) as percentage_change
from
(
	SELECT *,
	Lag(avg_price,1) over(partition by IDCustomer order by year) as lag_price
	from
	(
		SELECT IDCustomer,year(date) as year,
		avg(totalprice) as avg_price,
		Sum(Quantity) as qty 
		from FACT_TRANSACTIONS
		where IDCustomer in ( SELECT TOP 100 IDCustomer
								from FACT_TRANSACTIONS
								Group by IDCustomer
								order by sum(totalprice) desc)
		Group by IDCustomer,year(date)
	) as c
)as b;
	


















--Q10--END
	
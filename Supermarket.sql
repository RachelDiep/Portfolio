
/* With a flat table tracking transaction data of a Supermarket chain: 
-TASK 1: Reform it to be ready for later analysis (split table/ create relationships/ clean data/...)
-TASK 2: Answer ad-hoc questions
-TASK 3: Create a DAR to track Sales Performance for skateholders (practise in Power BI) 
*/ 

----------------------------------------------------------------- 
---TASK 1: CONVERT A FLAT TABLE TO DIMENSIONAL AND FACT TABLES FOR LATER ANALYSIS

--(1) SPLIT FLAT TABLES

--- Create a NEW DATABASE to store Supermarket data 
CREATE DATABASE Supermarket
GO 

---CUSTOMERS TABLE:
SELECT [Customer ID], Gender, [Marital Status], Homeowner, Children,[Annual Income], COUNT(*) as [count]
INTO Customers
FROM flattable
GROUP BY [Customer ID], Gender, [Marital Status], Homeowner, Children,[Annual Income]
-----Set Customer ID col to PRIMARY KEY, after alter the column to NOT NULL
ALTER TABLE Customers
ALTER COLUMN [Customer ID] INT NOT NULL
GO 
ALTER TABLE Customers
ADD CONSTRAINT Customers_PK PRIMARY KEY ([Customer ID])
GO
-----Delete count col, since we donnot need it 
ALTER TABLE Customers
DROP COLUMN [count]


---GEOGRAPHY TABLE:
Select City,[State or Province],Country, count(*) as [count]
INTO [Geography]
FROM flattable
GROUP BY City,[State or Province],Country
-----Again, delete count col
ALTER TABLE [Geography]
DROP COLUMN [count]
-----Add an ID col and define it as a Primary Key
ALTER TABLE [Geography]
ADD [Geography ID] INT IDENTITY
CONSTRAINT PK_geo PRIMARY KEY ([Geography ID])


---PRODUCT TABLE:
SELECT [Product Family],[Product Department],[Product Category], COUNT(*) as [count]
INTO [Products]
FROM flattable
GROUP BY [Product Family],[Product Department],[Product Category]
-----Delete count col
ALTER TABLE Products
DROP COLUMN [count]
-----Add an ID col and define it as a PRIMARY KEY
ALTER TABLE [Products]
ADD [Product ID] INT IDENTITY
CONSTRAINT PK_prod PRIMARY KEY ([Product ID])



---CALENDAR table:
/*
If there is the case that dataset will be updated or added more data,
I will use full calendar which download from the Internet
to make sure the date in dataset will be covered all time
*/
SELECT [Purchase Date] as [Date], [Weekday], [Day Purchase], [Year Purchase], count(*) as [count]
INTO Calendar
FROM flattable
GROUP BY [Purchase Date], [Weekday], [Day Purchase], [Year Purchase]
----Drop count col
ALTER TABLE Calendar
DROP COLUMN [count]
----Set Purchase Date to PRIMARY KEY
ALTER TABLE Calendar
ADD [Date ID] INT IDENTITY
CONSTRAINT calendar_PK PRIMARY KEY ([Date ID])


--SALES TABLE: 

---clean up Flattable : add ID columns from Dimentional Tables, drop unnessesary columns
Select flat.*, prod.[Product ID], geo.[Geography ID], cal.[Date ID]
INTO Sales
FROM flattable flat
LEFT JOIN Products prod 
	ON prod.[Product Category] = flat.[Product Category]
		AND prod.[Product Family] = flat.[Product Family]
		AND prod.[Product Department] = flat.[Product Department]
LEFT JOIN Geography geo 
	ON geo.City = flat.City
		AND geo.Country = flat.Country
		AND geo.[State or Province] = flat.[State or Province]
LEFT JOIN Calendar cal 
	ON cal.[Day Purchase]= flat.[Day Purchase]
		AND cal.Date = flat.[Purchase Date]
		AND cal.[Year Purchase] = flat.[Year Purchase]


---We'll drop columns by just choosing neccessary columns and copy them into a new table
SELECT [Transaction] as [Sales Key]
	,[Purchase Date]
	, [Date ID]
	, [Customer ID]
	,[Geography ID]
	, [Product ID]
	, [Units Sold]
	, Revenue
INTO Sales_tab
FROM Sales

---Create PRIMARY KEY FOR Sales Key col, after changing data type to not-null 
ALTER TABLE Sales_tab
ALTER COLUMN [Sales Key] INT NOT NULL
GO
ALTER TABLE Sales_tab
ADD CONSTRAINT sales_pk PRIMARY KEY([Sales Key])
---Change data type of Customer ID col in Sales_tab
ALTER TABLE Sales_tab
ALTER COLUMN [Customer ID] int 


---Connect primary keys of dimentional tables with key cols as FOREIGN KEYS of Sales_tab
----to CREATE STAR SCHEMA 
ALTER TABLE Sales_tab
ADD CONSTRAINT customers_FK FOREIGN KEY ([Customer ID]) REFERENCES Customers([Customer ID]), 
CONSTRAINT geography_FK FOREIGN KEY ([Geography ID]) REFERENCES [Geography]([Geography ID]),
CONSTRAINT products_FK FOREIGN KEY ([Product ID]) REFERENCES Products([Product ID]),
CONSTRAINT calendar_FK FOREIGN KEY ([Date ID]) REFERENCES Calendar([Date ID])


--STEP 2: ADDING MORE NECESSARY COLUMNS
----Add MONTH col to CALENDAR table
USE Supermarket
ALTER TABLE Calendar
ADD [Month Purchase] INT, [Quarter Purchase] INT 

UPDATE Calendar
SET [Month Purchase] = MONTH(Date)
GO
UPDATE Calendar
SET [Quarter Purchase] = DATEPART(quarter, [Date])

--------------------------------------------

---TASK 2: COMPARE REVENUE AMONG COUNTRIES IN THE 2 LATEST YEAR. 
-----(1) FIGURE OUT: WHICH COUNTRY WAS THE STRONGEST COUNTRY FOR REVENUE?
-----(2) WHICH COUNTRY HAD THE HIGHEST Y/Y GROWTH?

--(1) WHICH COUNTRY HAVING THE HIGHEST REVENUE IN THE LATEST YEAR (according to the dataset)? 

---- Create a procedure to GET THE BEST COUNTRY NAME, for later utilization
CREATE PROCEDURE get_thebestcountry AS
WITH RevenueByCountry AS (
		SELECT G.Country ,SUM(S.Revenue) as Total_revenue
		FROM Sales_tab S
		LEFT JOIN Geography G 
			ON S.[Geography ID] = G.[Geography ID]
		WHERE YEAR(S.[Purchase Date]) = ( SELECT MAX(YEAR([Purchase Date])) FROM Sales_tab )
		GROUP BY G.Country
)
SELECT Country 
FROM RevenueByCountry 
WHERE Total_revenue = ( SELECT MAX(Total_revenue) FROM RevenueByCountry)

---Excecute the country name for everytime the data is updated 
EXEC get_thebestcountry

---(2) WHICH COUNTRY HAD THE HIGHEST Y/Y GROWTH FROM 2015-2016?

WITH CTE AS
(
	SELECT G.Country
	, YEAR(S.[Purchase Date]) as [Year]
	, SUM(S.Revenue) as Total_revenue
	FROM Sales_tab S
	LEFT JOIN Geography G 
		ON S.[Geography ID] = G.[Geography ID]
	WHERE YEAR(S.[Purchase Date]) IN (2015,2016)
	GROUP BY G.Country, YEAR([Purchase Date]) 
)

SELECT a.Country, a.[Year], a.Total_revenue
	,b.[Year], b.Total_revenue 
	,((b.Total_revenue- a.Total_revenue)/a.Total_revenue)*100  as [YoY revenue]
FROM CTE a, CTE b
WHERE a.[Year] = 2015 
	AND b.[Year]=2016
	AND a.Country = b.Country





/*
TASK: 
WRITING SQL CODE TO GET CHANGABLE DATA FROM EXCEL
INTO A LIVE DASHBOARD IN POWER BI, AS LONG AS WHEN 
EXCEL DATA IS CHANGED OR UPDATED, DASHBOARD WILL CHANGES TOO. 
*/


--(1) Create a command to DELETE SALES TABLE which existing for creating old reports 
----INTERPET: If Sales table is already existing in this database, 
-----delete it, then create a new one to load current data for creating reports.
IF OBJECT_ID('Sales') IS NOT NULL
DROP TABLE Sales
GO

--(2) Create an EMPTY TABLE, with similar headers and data types with dataset in EXCEL
----With a PRIMARY key and FOREIGN Keys (to create a star schema).
CREATE TABLE Sales 
	( SalesKey INT PRIMARY KEY
	,ChannelKey INT FOREIGN KEY REFERENCES Channels(ChannelKey)
	, UnitPrice float
	, SalesQuantity INT
	, ReturnQuantity INT
	,ReturnAmount float
	, SalesAmount float
	, GeographyKey INT REFERENCES [Geography](GeographyKey)
	, [Date] date )
GO

--(3) LOAD DATA from EXCEL file to Sales table
/* 
Remember to delete headers in EXCEL file before loading in 
In the future, if want to load new excel file to SQL server, 
just change name file to 'SalesforReport' in EXCEL, then run this code again.
*/
BULK INSERT Sales 
FROM 'C:\Users\Admin\Downloads\csv-contoso\SalesforReport.csv'
WITH (FORMAT = 'CSV')
GO

--(4) Create VIEW TABLE to collect variables we want to use in Power BI report
---In this situation, I will have all data.
CREATE VIEW sales_tab AS
	SELECT * FROM Sales 

--(5) We already have Geography table in the database, Let's create CHANNELS TABLE
CREATE TABLE Channels
(ChannelKey int IDENTITY PRIMARY KEY, ChannelName varchar(30) )
GO
INSERT Channels(ChannelName)
VALUES ('Store'),('Online'),('Catalog'),('Reseller')
GO


--(6) Create A STORED PROCEDURE to load in new sales data into this data base monthly
---by copying steps above
CREATE PROCEDURE load_sales_data AS
	--step 1: drop existing Sales table
	IF OBJECT_ID('Sales') IS NOT NULL
	DROP TABLE Sales
	
	--step 2: create sales table with headers 
	CREATE TABLE Sales 
	( SalesKey INT PRIMARY KEY
	,ChannelKey INT FOREIGN KEY REFERENCES Channels(ChannelKey)
	, UnitPrice float
	, SalesQuantity INT
	, ReturnQuantity INT
	,ReturnAmount float
	, SalesAmount float
	, GeographyKey INT REFERENCES [Geography](GeographyKey)
	, [Date] date )
	
	--step 3:Load data from EXCEL file to Sales table
	BULK INSERT Sales 
	FROM 'C:\Users\Admin\Downloads\csv-contoso\SalesforReport.csv'
	WITH (FORMAT = 'CSV')
	

--LET THE PROCEDURE RUN, to load in new sales data from EXCEL
EXEC load_sales_data

--when we need to update current data: change file excel name to 'SalesforReport',
---then Execute load_sales_data procedure in SQL server, finally refresh table in Power BI


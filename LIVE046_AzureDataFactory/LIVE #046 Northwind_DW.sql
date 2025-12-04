/****************************************
 Live #046 Azure Data Factory (ADF)
*****************************************/

/***********************************************
 DimCustomer
 - Transformação SCD
***********************************************/
-- TRUNCATE TABLE dbo.DimCustomer
DROP TABLE IF exists dbo.DimCustomer
go
CREATE TABLE dbo.DimCustomer (
DimCustomer_ID int NOT NULL identity primary key,
DimCustomer_APP nchar(5) NOT NULL,
CompanyName nvarchar(40) NOT NULL,
ContactName nvarchar(30) NULL,
ContactTitle nvarchar(30) NULL,
Address nvarchar(60) NULL, -- Tipo 2
City nvarchar(15) NULL, -- Tipo 2
Region nvarchar(15) NULL, -- Tipo 2
PostalCode nvarchar(10) NULL, -- Tipo 2
Country nvarchar(15) NULL, -- Tipo 2
Phone nvarchar(24) NULL,
Fax nvarchar(24) NULL)
go

/***************
 Origem
****************/
SELECT CustomerID as DimCustomer_APP, CompanyName, ContactName, ContactTitle, 
Address, City, Region, PostalCode, Country, Phone, Fax
FROM dbo.Customers

-- Teste Alteração
SELECT * FROM dbo.Customers
WHERE CustomerID in ('SQLEX','ALFKI')

UPDATE dbo.Customers SET City = 'London' WHERE CustomerID = 'ALFKI'

INSERT dbo.Customers
(CustomerID, CompanyName, ContactName, ContactTitle, 
Address, City, Region, PostalCode, Country, Phone, Fax)
VALUES ('SQLEX','SQL Server Expert','Landry','DBA','Datacenter, 55','Rio de Janeiro','RJ','1234','Brazil','(21)92929292',null)


-- Retornar valor original
UPDATE dbo.Customers SET City = 'Berlin' WHERE CustomerID = 'ALFKI'
DELETE dbo.Customers WHERE CustomerID = 'SQLEX'

/**************
 Destino
***************/
SELECT * FROM dbo.DimCustomer
WHERE DimCustomer_APP in ('SQLEX','ALFKI')
-- Berlin



use master
go

CREATE DATABASE DB_Tuning
go
ALTER DATABASE DB_Tuning SET RECOVERY simple
go

use DB_Tuning
go

/***********************************
 Cria duas tabelas para o Hends On
************************************/

-- Tabela Customer
DROP TABLE IF exists dbo.Customer
go
CREATE TABLE dbo.Customer (
CustomerID int not null CONSTRAINT pk_Customer PRIMARY KEY, 
Title nvarchar(8) null, 
FirstName nvarchar(50) null, 
MiddleName nvarchar(50) null, 
LastName nvarchar(50) null,
[Name] nvarchar(160) null) 
go

-- Carrega linhas a partir do AdventureWorks
set nocount on
INSERT dbo.Customer (CustomerID, Title, FirstName, MiddleName, LastName, [Name])
SELECT c.CustomerID, Title, FirstName, MiddleName, LastName, FirstName + isnull(' ' + MiddleName,'') + isnull(' ' + LastName,'') as [Name]
FROM AdventureWorks.Sales.Customer c
JOIN AdventureWorks.Person.Person p on p.BusinessEntityID = c.PersonID

-- Tabela SalesOrderHeader
DROP TABLE IF exists dbo.SalesOrderHeader
go
CREATE TABLE dbo.SalesOrderHeader(
SalesOrderID int NOT NULL identity CONSTRAINT pk_SalesOrderHeader PRIMARY KEY,
OrderDate datetime NOT NULL,
Status tinyint NOT NULL,
OnlineOrderFlag bit NOT NULL,
SalesOrderNumber char(200) NOT NULL,
CustomerID int NOT NULL,
SalesPersonID int NULL,
TerritoryID int NULL,
SubTotal money NOT NULL,
TaxAmt money NOT NULL,
Freight money NOT NULL,
TotalDue money NOT NULL,
Comment nvarchar(128) NULL)
go

-- Alimenta tabela com 31.465.000 linhas
set nocount on

INSERT dbo.SalesOrderHeader (OrderDate, [Status], OnlineOrderFlag, SalesOrderNumber, CustomerID, SalesPersonID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue, Comment)
SELECT OrderDate, Status, OnlineOrderFlag, 
SalesOrderNumber, CustomerID, SalesPersonID, TerritoryID,  
SubTotal, TaxAmt, Freight, TotalDue, Comment
FROM AdventureWorks.Sales.SalesOrderHeader
go 1000

set nocount off

-- SELECT count(*) as QtdLinhas FROM dbo.SalesOrderHeader
/************************* FIM Prepara Hands On ******************************/



/******************************
 Tuning de Consulta
*******************************/
set statistics io on

SELECT c.Name as Customer, count(*) as Sales_Qty, sum(h.TotalDue) as Total
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE year(h.OrderDate) = 2014
GROUP BY c.Name
ORDER BY Total desc


/* 22 seg
Table 'Customer'. Scan count 4, logical reads 550
Table 'SalesOrderHeader'. Scan count 4, logical reads 1053954

Total de IO: 1054504 x 8 KB = 8.436.032 KB = 8.238 MB = 8 GB
*/

CREATE NONCLUSTERED INDEX ix_SalesOrderHeader_OrderDate
ON dbo.SalesOrderHeader (OrderDate)
INCLUDE (CustomerID,TotalDue)
/*
Table 'Customer'. Scan count 4, logical reads 550
Table 'SalesOrderHeader'. Scan count 4, logical reads 118367

Total de IO = 118917 x 8 KB = 951.336 KB = 929 mb
*/















-- Alteração da consulta para utilizar o índice com busca binária
SELECT c.Name as Customer, count(*) as Sales_Qty, sum(h.TotalDue) as Total
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE h.OrderDate >= '20140101' and h.OrderDate < '20150101'
GROUP BY c.Name
ORDER BY Total desc
/*
Table 'Customer'. Scan count 4, logical reads 550
Table 'SalesOrderHeader'. Scan count 4, logical reads 44298

Total de IO = 44848 x 8 KB = 358.784 KB = 350 MB
*/



/*****************************
 Habilitando o Query Store
******************************/
use master
go
ALTER DATABASE DB_Tuning SET QUERY_STORE = ON
go
ALTER DATABASE DB_Tuning SET QUERY_STORE (OPERATION_MODE = READ_WRITE)
go


-- Mostrar a diferença da quantidade de eventos entre SQL Server 2019 e 2022
SELECT xo.name, xo.description
FROM sys.dm_xe_packages as xp
JOIN sys.dm_xe_objects xo on xp.guid = xo.package_guid
WHERE xp.name = 'qds' and xo.object_type = 'event'

-- Limpar os dados no Query Store
ALTER DATABASE DB_Tuning SET QUERY_STORE CLEAR ALL


-- Consulta 1
SELECT * FROM dbo.Customer WHERE CustomerID = 11000

-- Consulta 2
SELECT c.Name as Customer, count(*) as Sales_Qty, sum(h.TotalDue) as Total
FROM dbo.SalesOrderHeader h
JOIN dbo.Customer c on c.CustomerID = h.CustomerID
WHERE h.OrderDate >= '20140101' and h.OrderDate < '20150101'
GROUP BY c.Name
ORDER BY Total desc

-- Abrir outra sessão
BEGIN TRAN
	UPDATE dbo.Customer SET Title = 'Sr' WHERE CustomerID = 11000
ROLLBACK


/*************************
 Exclui o banco
**************************/
use master
go
ALTER DATABASE DB_Tuning SET READ_ONLY WITH ROLLBACK IMMEDIATE
go
DROP DATABASE IF exists DB_Tuning


/************************************
 Demonstração Data Flow
 https://dataedo.com/samples/html/AdventureWorks/doc/AdventureWorks_2/home.html
*************************************/
use AdventureWorks
go

SELECT * FROM Sales.SalesTerritory
SELECT * FROM Sales.Customer
SELECT * FROM Sales.SalesPerson
SELECT * FROM Person.Person
/* PersonType
 SC = Store Contact
 IN = Individual (retail) customer
 SP = Sales person
 EM = Employee (non-sales)
 VC = Vendor contact
 GC = General contact 
 */

-- Lookup
SELECT TerritoryID,Name as Territory, CountryRegionCode as CountryRegion, [Group] as GroupRegion
FROM Sales.SalesTerritory

-- Customer
SELECT a.BusinessEntityID as CustomerID,a.PersonType, -- SC = Store Contact
a.FirstName, a.MiddleName, a.LastName,
b.StoreID, c.[Name] as Store
FROM Person.Person a
JOIN Sales.Customer b on b.PersonID = a.BusinessEntityID
JOIN Sales.Store c on c.BusinessEntityID = b.StoreID

-- SalesPerson
SELECT a.BusinessEntityID as CustomerID,a.PersonType, -- SP = Sales person
a.FirstName, a.MiddleName, a.LastName,
b.TerritoryID,b.CommissionPct
FROM Person.Person a
JOIN Sales.SalesPerson b on b.BusinessEntityID = a.BusinessEntityID

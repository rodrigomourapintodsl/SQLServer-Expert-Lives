/*****************************************************************
 Autor: Landry

 Live #010
 Microsoft SQL Server Reporting Services (SSRS)
******************************************************************/
use AdventureWorks
go

-- Consulta original
SELECT a.FirstName + '' + a.LastName AS Funcionario, b.JobTitle as Cargo, 
b.BirthDate as DataAniversario, b.MaritalStatus as EstadoCivil, b.Gender as Sexo
FROM Person.Person AS a 
JOIN HumanResources.Employee AS b ON a.BusinessEntityID = b.BusinessEntityID
ORDER BY Cargo


-- Consulta com Parâmetro
go
DECLARE @Cargo nvarchar(50) = 'Buyer' --'<TODOS>'

SELECT a.FirstName + '' + a.LastName AS Funcionario, b.JobTitle as Cargo, 
b.BirthDate as DataAniversario, b.MaritalStatus as EstadoCivil, b.Gender as Sexo
FROM Person.Person a 
JOIN HumanResources.Employee b ON a.BusinessEntityID = b.BusinessEntityID
WHERE b.JobTitle = @Cargo  
ORDER BY Funcionario
go

-- Parâmetro Cargo

SELECT distinct JobTitle as Cargo
FROM HumanResources.Employee
ORDER BY Cargo

-- Parâmetro Cargo com <TODOS>

SELECT distinct JobTitle as Cargo
FROM HumanResources.Employee
UNION ALL
SELECT '<TODOS>'
ORDER BY Cargo

go
DECLARE @Cargo nvarchar(50) = 'Buyer' --'<TODOS>'

SELECT a.FirstName + '' + a.LastName AS Funcionario, b.JobTitle as Cargo, 
b.BirthDate as DataAniversario, b.MaritalStatus as EstadoCivil, b.Gender as Sexo
FROM Person.Person a 
JOIN HumanResources.Employee b ON a.BusinessEntityID = b.BusinessEntityID
WHERE (b.JobTitle = @Cargo or @Cargo = '<TODOS>')
ORDER BY Funcionario
go


/****************************************
 Autor: Landry

 Hands On: BCP.exe e Bulk Insert

 BCP.exe
 https://learn.microsoft.com/en-us/sql/tools/bcp-utility?view=sql-server-ver16

 BULK INSERT
 https://learn.microsoft.com/en-us/sql/t-sql/statements/bulk-insert-transact-sql?view=sql-server-ver16
*****************************************/
use Aula
go

-- TRUNCATE TABLE Municipio
DROP TABLE If exists Municipio
go
CREATE TABLE Municipio (
UF varchar(50) NULL,
Nome_UF varchar(50) NULL,
MesorregiaoGeografica_COD varchar(50) NULL,
MesorregiaoGeografica varchar(100) NULL,
MicrorregiaoGeografica_COD varchar(50) NULL,
MicrorregiaoGeografica varchar(100) NULL,
Municipio_COD varchar(50) NULL,
Municipio_COD_Completo varchar(50) NULL,
Municipio varchar(100) NULL)
go

/****************************************************
Exportação

- Separado por tabulação (default)
BCP AdventureWorks.Production.ProductCategory out "C:\_LIVE\ProductCategory.txt" -S SRVSQL2022 -T -c –t

- Separado por ;
BCP AdventureWorks.Production.ProductCategory out "C:\_LIVE\ProductCategory.txt" -S SRVSQL2022 -T -c –t;

- Resultado de uma consulta queryout
BCP "SELECT BusinessEntityID, Title, FirstName, MiddleName, LastName, ModifiedDate FROM AdventureWorks.Person.Person" queryout "C:\_LIVE\Person.txt" -S SRVSQL2022 -T -c –t

- Binário modo nativo -n
BCP "SELECT BusinessEntityID, Title, FirstName, MiddleName, LastName, ModifiedDate FROM AdventureWorks.Person.Person" queryout "C:\_LIVE\Person.txt" -S SRVSQL2022 -T -c –t -n

-- Header com nome das colunas
BCP "SELECT 'BusinessEntityID', 'Title', 'FirstName', 'MiddleName', 'LastName', 'ModifiedDate' UNION ALL SELECT ltrim(str(BusinessEntityID)), Title, FirstName, MiddleName, LastName, convert(varchar(12),ModifiedDate,103) FROM AdventureWorks.Person.Person" queryout "C:\_LIVE\Person.txt" -S SRVSQL2022 -T -c –t

SELECT 'BusinessEntityID', 'Title', 'FirstName', 'MiddleName', 'LastName', 'ModifiedDate' 
UNION ALL 
SELECT ltrim(str(BusinessEntityID)), Title, FirstName, MiddleName, LastName, convert(varchar(12),ModifiedDate,103) 
FROM AdventureWorks.Person.Person
*****************************************************/
SELECT BusinessEntityID, Title, FirstName, MiddleName, LastName, ModifiedDate FROM AdventureWorks.Person.Person

SELECT 'BusinessEntityID', 'Title', 'FirstName', 'MiddleName', 'LastName', 'ModifiedDate' 
UNION ALL 
SELECT ltrim(str(BusinessEntityID)), Title, FirstName, MiddleName, LastName, convert(varchar(12),ModifiedDate,103) 
FROM AdventureWorks.Person.Person


/****************************************************
Importação

- Arquivo formação Texto
BCP Aula.dbo.Municipio format nul -c -f "C:\_LIVE\MUNICIPIOS.fmt" -T -t,

- Arquivo formação XML
BCP Aula.dbo.Municipio format nul -c -x -f "C:\_LIVE\MUNICIPIOS.xml" -T -t,

- Importa com BCP
SQLCMD -Q "TRUNCATE TABLE Aula.dbo.Municipio"

-- Problema de acentos devido a conversão de Code Page
BCP Aula.dbo.Municipio IN "C:\_LIVE\MUNICIPIOS.csv" -T -c -t, -F 2

-- Para resolver -C RAW para não ter conversão de Code Page
BCP Aula.dbo.Municipio IN "C:\_LIVE\MUNICIPIOS.csv" -T -c -t, -F 2 -C RAW

BCP Aula.dbo.Municipio IN "C:\_LIVE\MUNICIPIOS.csv" -f "C:\_LIVE\MUNICIPIOS.fmt" -T -F 2 -C RAW

*****************************************************/

TRUNCATE TABLE Aula.dbo.Municipio

SELECT * FROM Aula.dbo.Municipio

/*****************************************************************************************************
- Ordem diferente do arquivo duas primeiras colunas, inverter numeração

BCP Aula.dbo.Municipio_Dif IN "C:\_LIVE\MUNICIPIOS.csv" -f "C:\_LIVE\MUNICIPIOS.fmt" -T -F 2 -C RAW
******************************************************************************************************/
DROP TABLE If exists Municipio_Dif
go
CREATE TABLE Municipio_Dif (
Nome_UF varchar(50) NULL,
UF varchar(50) NULL,
MesorregiaoGeografica_COD varchar(50) NULL,
MesorregiaoGeografica varchar(100) NULL,
MicrorregiaoGeografica_COD varchar(50) NULL,
MicrorregiaoGeografica varchar(100) NULL,
Municipio_COD varchar(50) NULL,
Municipio_COD_Completo varchar(50) NULL,
Municipio varchar(100) NULL)
go

SELECT * FROM Aula.dbo.Municipio_Dif

/**************************************
 BULK INSERT 
***************************************/

TRUNCATE TABLE Aula.dbo.Municipio

BULK INSERT Aula.dbo.Municipio
FROM 'C:\_LIVE\MUNICIPIOS.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', CODEPAGE = 'RAW')

SELECT * FROM Aula.dbo.Municipio

-- Exclui Tabelas
DROP TABLE If exists Municipio
go
DROP TABLE If exists Municipio_Dif
go
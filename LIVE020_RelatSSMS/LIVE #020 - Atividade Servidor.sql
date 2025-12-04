/*****************************************************
 Autor: Landry Duailibe

 Relatório Atividade Servidor para Management Studio
******************************************************/
USE master
go

/***************************************
 Stored Procedure coleta contadores
****************************************/
go
CREATE or ALTER PROC dbo.DBA_Contadores
AS
set nocount on

SELECT counter_name as Contador,cntr_value as Valor
INTO #PrimeiraColeta
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in ('Lock Waits/sec',
'Number of Deadlocks/sec',
'Transactions/sec',
'Log Flush Waits/sec','Latch Waits/sec',
'Full Scans/sec','Index Searches/sec',
'Forwarded Records/sec','Page Splits/sec',
'Batch Requests/sec','Page lookups/sec')
ORDER BY 1,2

WAITFOR DELAY '00:00:5'

-- 2a Coleta
SELECT counter_name as Contador,cntr_value as Valor
INTO #SegundaColeta
FROM sys.dm_os_performance_counters
WHERE cntr_type = 272696576
and instance_name in ('_Total','')
and counter_name in ('Lock Waits/sec',
'Number of Deadlocks/sec',
'Transactions/sec',
'Log Flush Waits/sec','Latch Waits/sec',
'Full Scans/sec','Index Searches/sec',
'Forwarded Records/sec','Page Splits/sec',
'Batch Requests/sec','Page lookups/sec')
ORDER BY 1,2

DECLARE @DataColeta datetime
SET @DataColeta = getdate()

/****************************
 CTE Duas Coletas
*****************************/
;WITH CTE_DuasColetas as (
SELECT @DataColeta as DataColeta,*
FROM (
SELECT a.Contador, (b.Valor - a.Valor) / 5 as Valor
FROM #PrimeiraColeta a
JOIN #SegundaColeta b ON a.Contador = b.Contador) a
PIVOT (max(Valor) FOR Contador in 
([Forwarded Records/sec],[Full Scans/sec],[Index Searches/sec],
[Page Splits/sec],[Log Flush Waits/sec],[Transactions/sec],
[Latch Waits/sec],[Lock Waits/sec],[Number of Deadlocks/sec],
[Batch Requests/sec],[Page lookups/sec]) ) b),

/***********************
 CTE Valor direto
************************/
CTE_UmaColeta as (
SELECT @DataColeta as DataColeta,
(select 
cast((total_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_RAM_GB
from sys.dm_os_sys_memory) as MEM_RAM_GB,
(select 
cast((available_physical_memory_kb/1024.00)/1024.00 as decimal(16,2)) as MEM_Livre_GB
from sys.dm_os_sys_memory) as MEM_Livre_GB,* 

FROM (
SELECT counter_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type = 65792
and instance_name in ('_Total','')
and counter_name in ('Page life expectancy',
'Total Server Memory (KB)','Target Server Memory (KB)',
'Database pages','User Connections')) a
PIVOT (max(cntr_value) FOR counter_name in 
([Page life expectancy],[Total Server Memory (KB)],[Target Server Memory (KB)],
[Database pages],[User Connections]) ) b)


/*****************************
 Inclusão dados de contadores
******************************/

SELECT a.DataColeta, @@SERVERNAME as Instancia, MEM_RAM_GB, MEM_Livre_GB,
[Forwarded Records/sec], [Full Scans/sec], [Index Searches/sec], [Page Splits/sec], 
[Log Flush Waits/sec], [Transactions/sec], [Latch Waits/sec], [Lock Waits/sec], 
[Number of Deadlocks/sec], [Batch Requests/sec], [Page life expectancy], 
[Total Server Memory (KB)], [Target Server Memory (KB)], [Database pages],[User Connections],
[Page lookups/sec]
FROM CTE_UmaColeta a 
JOIN CTE_DuasColetas b ON b.DataColeta = a.DataColeta

DROP TABLE IF exists #PrimeiraColeta
DROP TABLE IF exists #SegundaColeta
go
/************************* FIM SP ******************************/


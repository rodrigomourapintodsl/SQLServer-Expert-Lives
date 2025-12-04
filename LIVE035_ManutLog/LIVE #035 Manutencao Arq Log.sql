/*********************************************
 Autor: Landry Duailibe

 Hands On: Recovery Model X Arquivo de Log
**********************************************/
use master
go

/**************************
 Cria Banco HandsOn
***************************/
DROP DATABASE IF exists HandsOn
go
CREATE DATABASE HandsOn ON  PRIMARY 
(NAME = N'HandsOn', FILENAME = N'C:\MSSQL_Data\HandsOn.mdf',SIZE = 10MB,FILEGROWTH = 1024KB)
LOG ON 
(NAME = N'HandsOn_log',FILENAME = N'C:\MSSQL_Data\HandsOn_log.ldf',SIZE = 8MB,FILEGROWTH = 2MB)
go

-- Altera Recovery Model
ALTER DATABASE HandsOn SET RECOVERY FULL


--  Cria tabela 
DROP TABLE IF exists HandsOn.dbo.Cliente
go
CREATE TABLE HandsOn.dbo.Cliente ( 
Cliente_ID int not null identity CONSTRAINT pk_Cliente PRIMARY KEY,
Nome varchar(1200) not null,
Renda bigint null)
go

-- Backup FULL
BACKUP DATABASE HandsOn TO DISK = 'C:\_LIVE\Backup\HandsOn_Full.bak' WITH format, compression

	
-- View database file space
use HandsOn
go
SELECT name AS Name, type, size * 8 /1024. as SizeinMB,  
FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as SpaceUsedInMB,
CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
/ CAST(size as decimal(10,4)) * 100 as PercentSpaceUsed	
FROM sys.database_files
WHERE type = 1
/*
Name		type	SizeinMB	SpaceUsedInMB	PercentSpaceUsed
HandsOn		0		10.000000	3.000000		30.000000000000000
HandsOn_log	1		 8.000000	0.531250		 6.640625000000000
*/

--  Inclui 10.000 linhas
set nocount on

INSERT HandsOn.dbo.Cliente (Nome,Renda)
VALUES('Bla Bla Bla...',12345)
go 10000

/*
Name		type	SizeinMB	SpaceUsedInMB	PercentSpaceUsed
HandsOn_log	1		40.000000	39.953125		99.882812500000000
*/

-- Verifica Status do Log Reuse
SELECT name as Banco, log_reuse_wait_desc 
FROM sys.databases WHERE name = 'HandsOn'
-- LOG_BACKUP

/*******************************************
 Mostrar os Logs Virtuais e porção ativa
********************************************/
-- DBCC LOGINFO não documentado
DBCC LOGINFO ('HandsOn') 

-- Nova visão a partir do SQL Server 2016
SELECT * FROM sys.dm_db_log_info(db_id('HandsOn'))
/*
https://learn.microsoft.com/pt-br/sql/relational-databases/system-dynamic-management-views/sys-dm-db-log-info-transact-sql?view=sql-server-ver16

vlf_active (0 livre / 1 ativo)
vlf_status (0 livre / 1 inicializado mas sem uso / 2 em uso)
*/

/*****************************************************
 Backup do Log
 - Copia o conteúdo do Arquivo de Log uma arquivo.
 - Trunca o Arquivo de Log internamente.
 - NÃO reduz o tamanho do arquivo no SO!
******************************************************/
BACKUP LOG HandsOn TO DISK = 'C:\_LIVE\Backup\HandsOn_01.trn' WITH INIT, COMPRESSION


-- Ocupação do Arquivo de Log 
SELECT name AS Name, size * 8 /1024. as SizeinMB,  
FILEPROPERTY(name,'SpaceUsed') * 8 /1024. as SpaceUsedInMB,
CAST(FILEPROPERTY(name,'SpaceUsed') as decimal(10,4))
/ CAST(size as decimal(10,4)) * 100 as PercentSpaceUsed	
FROM sys.database_files 
WHERE type = 1
	
/*
Name		SizeinMB	SpaceUsedInMB	PercentSpaceUsed
HandsOn_log	40.000000	2.601562		6.503906250000000
*/


/************************************
 Reduzindo o arquivo de Log
*************************************/
SELECT * FROM sys.dm_db_log_info(db_id('HandsOn'))

use HandsOn
go
DBCC SHRINKFILE ('HandsOn_log',10)
-- 1a execução força o Log Circular

-- Trunca o VLF no final do arquivo
BACKUP LOG HandsOn TO DISK = 'C:\_LIVE\Backup\HandsOn_02.trn' WITH INIT, COMPRESSION

use HandsOn
go
DBCC SHRINKFILE ('HandsOn_log',10)
-- 2a execução consegue reduzir

/*********************
 Remove o Banco
**********************/
use master
go
ALTER DATABASE HandsOn SET READ_ONLY WITH ROLLBACK IMMEDIATE
go
DROP DATABASE HandsOn
go
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = 'HandsOn'


/*********************************************
 LIVE #003 - Canal SQL Server Expert

 Hands On - Backup
**********************************************/
USE master
go
create database TestDB
go


/**************************
 BACKUP Device
***************************/

-- Cria DEVICE
EXEC master.dbo.sp_addumpdevice  
@devtype = N'disk', 
@logicalname = N'BackupMaster', 
@physicalname = N'C:\_LIVE\Backup\BackupMaster.bak'
go

-- Backup Device
BACKUP DATABASE master TO BackupMaster

-- Backup File
BACKUP DATABASE master TO DISK = 'C:\_LIVE\Backup\BackupMaster.bak'
go

/***********************************
 Habilitar Compressão na Instância
************************************/
EXEC sp_configure 'show advanced options', 1
RECONFIGURE

EXEC sp_configure 'backup compression default', 1
RECONFIGURE

/************************* 
 Hands On Backup
**************************/
use TestDB
go

CREATE TABLE dbo.Clientes 
(ClienteID int not null primary key,
Nome varchar(50),
Telefone varchar(20))
go

SELECT * FROM TestDB.dbo.Clientes

-- truncate table dbo.Clientes
-- Backup FULL
INSERT dbo.Clientes VALUES (1,'Jose','1111-1111')
go

BACKUP DATABASE TestDB TO DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FORMAT,COMPRESSION

-- Backup LOG
INSERT dbo.Clientes VALUES (2,'Maria','2222-2222')
go

BACKUP LOG TestDB TO DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH NOINIT,COMPRESSION
RESTORE HEADERONLY FROM DISK = 'C:\_LIVE\Backup\TestDB.bak'
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-headeronly-transact-sql?view=sql-server-ver16
/* BackupType
1 = FULL
2 = Transaction log
4 = File
5 = Differential database
6 = Differential file
7 = Partial
8 = Differential partial
*/

-- Backup Log Reflexo Medular (RM)
INSERT dbo.Clientes VALUES (3,'Maria','3333-3333')
go

BACKUP LOG TestDB TO DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH NOINIT,COMPRESSION,NO_TRUNCATE
--WITH CONTINUE_AFTER_ERROR or WITH NO_TRUNCATE


/****************************
 Restore
*****************************/
use master
go

RESTORE DATABASE TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=1, NORECOVERY, REPLACE
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=2, NORECOVERY
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=3, RECOVERY

SELECT * FROM TestDB.dbo.Clientes

/****************************
 Restore
*****************************/
RESTORE DATABASE TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=1, NORECOVERY, REPLACE
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=2, NORECOVERY
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=3, NORECOVERY

RESTORE LOG TestDB WITH RECOVERY

/****************************
 Restore STANDBY
*****************************/
RESTORE DATABASE TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=1, NORECOVERY, REPLACE
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=2, STANDBY = 'C:\_LIVE\Backup\TestDB.std'
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak' WITH FILE=3, RECOVERY

SELECT * FROM TestDB.dbo.Clientes

/********************** 
 Restore LOG 
*****************************/
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak'
WITH STOPAT = 'Feb 18, 2007 12:00 AM', STANDBY = 'C:\_LIVE\Backup\TestDB.std'
-- ou
RESTORE LOG TestDB FROM DISK = 'C:\_LIVE\Backup\TestDB.bak'
WITH STOPAT = 'Feb 18, 2007 12:00 AM', RECOVERY


/***********************************
 Histórico Backup
************************************/
SELECT * FROM msdb..backupset
-- https://learn.microsoft.com/en-us/sql/relational-databases/system-tables/backupset-transact-sql?view=sql-server-ver16

-- Bancos sem Backup nos últimos 7 dias
SELECT name as Banco, recovery_model_desc as RecoveryModel, create_date as DataCriacao 
FROM sys.databases
WHERE database_id > 4 and NAME not in (
SELECT DISTINCT database_name FROM msdb..backupset
WHERE backup_start_date > DATEADD(DAY,-8,GETDATE()) AND  TYPE <> 'L')
/*
D = Database
I = Differential database
L = Log
F = File or filegroup
G = Differential file
P = Partial
Q = Differential partial
*/

-- Backups de um determinado Banco
SELECT a.backup_start_date as Datainicio,a.backup_finish_date as DataTermino,a.database_name as Banco, 
case a.type 
when 'D' then 'FULL'
when 'I' then 'DIF'
when 'L' then 'LOG' end as TipoBackup,
b.physical_device_name as ArquivoBackup,
a.user_name as usuario, a.is_copy_only, a.is_snapshot
FROM  msdb..backupset a
JOIN msdb..backupmediafamily b on b.media_set_id = a.media_set_id
WHERE 1=1
and database_name = 'TestDB'
and a.type <> 'L'
and backup_finish_date >= '20220601'
ORDER BY Banco,backup_finish_date desc



-- Exclui banco
DROP DATABASE IF exists TestDB


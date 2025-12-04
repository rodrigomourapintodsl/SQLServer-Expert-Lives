/*******************************************************************
 Hands On
 Autor: Landry
 
 - Extend Events
********************************************************************/
/***************************************
 Cria Extended Events
 - Alterar Caminho do Arquivo
******************************************/
-- DROP EVENT SESSION DBA_Monitora_Consultas ON SERVER 
CREATE EVENT SESSION DBA_Monitora_Consultas ON SERVER 
ADD EVENT sqlserver.rpc_completed (
    ACTION(package0.collect_cpu_cycle_time,package0.collect_system_time,package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
	WHERE sqlserver.database_name = 'AdventureWorks'), -- AND duration > 30000000
ADD EVENT sqlserver.sql_statement_completed (
    ACTION(package0.collect_cpu_cycle_time,package0.collect_system_time,package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
	WHERE sqlserver.database_name = 'AdventureWorks') -- AND duration > 30000000
ADD TARGET package0.event_file(SET filename=N'C:\_LIVE\MonitoraConsultas.xel',max_file_size=(100),max_rollover_files=(20))
WITH (STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = START
ALTER EVENT SESSION DBA_Monitora_Consultas ON SERVER STATE = STOP
DROP EVENT SESSION DBA_Monitora_Consultas ON SERVER
/********************************************************************************************************/


/**************************************
 Importa dados
***************************************/
use Aula
go

DROP TABLE IF exists Aula.dbo.DBA_Audit_Query
go
CREATE TABLE Aula.dbo.DBA_Audit_Query (
Evento_ID int not null identity primary key,
DataHora datetime NULL,
Evento varchar(200) NULL,
TempoExec bigint NULL,
TempoExec_Seg bigint NULL,
TempoCPU bigint NULL,
TempoCPU_Seg bigint NULL,
QtdLinhas int NULL,
LeiturasLogicas_Kb bigint NULL,
LeiturasFisicas_Kb bigint NULL,
Escritas_Kb int NULL,
Usuario varchar(200) NULL,
Host varchar(200) NULL,
Aplicacao varchar(200) NULL,
SPID int NULL,
EventoID int NULL,
Instancia varchar(200) NULL,
Banco varchar(200) NULL,
Comando varchar(max) NULL,
Comando_XML xml NULL)
go

-- TRUNCATE TABLE Aula.dbo.DBA_Audit_Query

INSERT Aula.dbo.DBA_Audit_Query
(DataHora, Evento, TempoExec, TempoExec_Seg, TempoCPU, TempoCPU_Seg, QtdLinhas, LeiturasLogicas_Kb, LeiturasFisicas_Kb, Escritas_Kb, Usuario, Host, Aplicacao, SPID, EventoID, Instancia, Banco, Comando, Comando_XML)

SELECT DataHora =  d.value(N'(/event/action[@name="collect_system_time"]/value)[1]', N'DATETIME')
,Evento = d.value(N'(/event/@name)[1]', N'varchar(200)')
,TempoExec = d.value(N'(/event/data[@name="duration"]/value)[1]', N'bigint') -- Microsegundos
,TempoExec_Seg = d.value(N'(/event/data[@name="duration"]/value)[1]', N'bigint') / 1000000 -- Microsegundos
,TempoCPU = d.value(N'(/event/data[@name="cpu_time"]/value)[1]', N'bigint') -- Microsegundos
,TempoCPU_Seg = d.value(N'(/event/data[@name="cpu_time"]/value)[1]', N'bigint') / 1000000 -- Microsegundos
,QtdLinhas = d.value(N'(/event/data[@name="row_count"]/value)[1]', N'int') 
,LeiturasLogicas_Kb = d.value(N'(/event/data[@name="logical_reads"]/value)[1]', N'bigint') * 8 -- Qtd de paginas 8k
,LeiturasFisicas_Kb = d.value(N'(/event/data[@name="physical_reads"]/value)[1]', N'bigint') * 8 -- Qtd de paginas 8k
,Escritas_Kb = d.value(N'(/event/data[@name="writes"]/value)[1]', N'int') * 8
,Usuario = d.value(N'(/event/action[@name="username"]/value)[1]', N'varchar(200)')
,Host = d.value(N'(/event/action[@name="client_hostname"]/value)[1]', N'varchar(200)')
,Aplicacao = d.value(N'(/event/action[@name="client_app_name"]/value)[1]', N'varchar(200)')
,SPID = d.value(N'(/event/action[@name="session_id"]/value)[1]', N'int')
,EventoID = d.value(N'(/event/action[@name="event_sequence"]/value)[1]', N'int')
,Instancia = d.value(N'(/event/action[@name="server_instance_name"]/value)[1]', N'varchar(200)')
,Banco = d.value(N'(/event/action[@name="database_name"]/value)[1]', N'varchar(200)')
,Comando = d.value(N'(/event/data[@name="statement"]/value)[1]', N'varchar(max)')
,Comando_XML = d.query(N'(/event/data[@name="statement"]/value)[1]')
FROM (
SELECT CONVERT(XML, event_data) 
FROM sys.fn_xe_file_target_read_file('C:\_LIVE\\MonitoraConsultas*.xel', NULL, NULL, NULL)
WHERE object_name IN (N'sql_statement_completed','rpc_completed')) AS x(d)
--order by 1 desc

SELECT f.*,CAST(f.event_data AS XML)  AS [Event-Data-Cast-To-XML]  -- Optional
FROM sys.fn_xe_file_target_read_file('C:\_LIVE\\MonitoraConsultas*.xel',
null, null, null)  AS f


SELECT Comando,COUNT(*)   
FROM Aula.dbo.DBA_Audit_Query
GROUP BY Comando
ORDER BY 2 desc




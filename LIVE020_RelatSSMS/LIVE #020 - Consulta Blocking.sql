/********************************************************************************
 Autor: Landry Dualibe

 Hands On:  Relatório customizado de Blocking para SSMS

 - Utilizar na cor de fundo na linha de detalhes:
   =IIF(ROWNUMBER(NOTHING) MOD 2,"White","Beige")

 - Cor de fundo: #003399
*********************************************************************************/
use master
go

/***********************************************************************
 Função formata ID JOB para identificar JOB envolvido no Blocking
************************************************************************/
go
CREATE function [dbo].[udf_sysjobs_getprocessid](@job_id uniqueidentifier)
returns varchar(8)
as
begin
return (substring(left(@job_id,8),7,2) +
substring(left(@job_id,8),5,2) +
substring(left(@job_id,8),3,2) +
substring(left(@job_id,8),1,2))
end
go

/*****************************
 KPIs
 - Qtd Conexões
 - Qtd Transações
 - Qtd Blocking
******************************/
SELECT * FROM (
SELECT counter_name,cntr_value
FROM sys.dm_os_performance_counters
WHERE cntr_type = 65792 
and counter_name in ('User Connections','Active Transactions','Processes blocked')) a
PIVOT (max(cntr_value) FOR counter_name in 
([User Connections],[Active Transactions],[Processes blocked]) ) b

/*****************************
 Consulta Blocking para SSRS
******************************/
SELECT getdate() as DataHora, spid as SPID, 'RAIZ' as Status, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,cast(rtrim(isnull(hostname,'N/A')) as varchar(50)) Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, 
cast(rtrim(loginame) as varchar(50)) as LoginSQL, 

case 
when s.program_name like 'SQLAgent - TSQL JobStep (Job%' 
then (select 'JOB: ' + MAX(name) + ' (' + replace( substring(s.program_name,CHARINDEX(': Step',s.program_name)+2,100) ,')','') + ')' FROM msdb.dbo.sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = substring(s.program_name,32,8) )
else s.program_name
end as Aplicacao, 

s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL

FROM master.dbo.sysprocesses sp LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE spid IN (SELECT distinct blocked FROM master.sys.sysprocesses where blocked > 0) AND blocked = 0

UNION 

SELECT getdate(), spid as SPID, 'BLOCK' as Status, waittime/1000 as TempoEspera_Seg, blocked as SPID_Blocking,
db_name(sp.dbid) Banco,cast(rtrim(isnull(hostname,'N/A')) as varchar(50)) Computador,
case when sp.nt_domain is null or sp.nt_domain = '' then 'N/A' else rtrim(sp.nt_domain) + '/' + nt_username end as UsuarioWindows, 
cast(rtrim(loginame) as varchar(50)) as LoginSQL, 

case 
when s.program_name like 'SQLAgent - TSQL JobStep (Job%' 
then (select 'JOB: ' + MAX(name) + ' (' + replace( substring(s.program_name,CHARINDEX(': Step',s.program_name)+2,100) ,')','') + ')' FROM msdb.dbo.sysjobs WHERE dbo.udf_sysjobs_getprocessid(job_id) = substring(s.program_name,32,8) )
else s.program_name
end as Aplicacao, 
 
s.client_interface_name as AppInterface,
open_tran as QtdTransacoes, cmd as TipoComando, last_batch as UltimoTSQL,qt.text as InstrucaoTSQL

FROM master.dbo.sysprocesses sp LEFT JOIN sys.dm_exec_sessions s ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE  spid > 50 and blocked > 0


/******************************************
 Provoca Blocking
*******************************************/

use aula
go
DROP TABLE IF exists TB_Snapshot
go
CREATE TABLE Funcionario (PK int, Nome varchar(50), Descricao varchar(100), Status char(1),Salario decimal(10,2))
INSERT Funcionario VALUES (9,'Erick','Operacional','C',2600.00)
INSERT Funcionario VALUES (10,'Joana','Operacional','C',2600.00)
go

BEGIN TRAN
  UPDATE Funcionario SET Salario = 3000.00 WHERE PK = 10
  SELECT * FROM Aula.dbo.Funcionario WHERE PK = 10 -- Salario = 2600.00

ROLLBACK


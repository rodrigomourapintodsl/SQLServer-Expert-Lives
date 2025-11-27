/*********************************************
 LIVE #003 - Canal SQL Server Expert

 Hands On - Backup todos os Bancos LOG
**********************************************/
declare @Caminho varchar(4000), @Banco varchar(500), @Compacta char(1), @DataHora varchar(20)
declare @state_desc varchar(200)
set @Caminho = 'C:\_LIVE\Backup\LOG\'
set @Compacta = 'S'

if object_id('dbo.tmpBancosBackupLOG') is not null
   drop table dbo.tmpBancosBackupLOG

select name,state_desc 
into dbo.tmpBancosBackupLOG 
from sys.databases 
where source_database_id is null
and state_desc = 'ONLINE' 
and name not in ('tempdb','model') 
and recovery_model_desc <> 'SIMPLE'
ORDER BY name

declare vCursor cursor for
select name,state_desc from dbo.tmpBancosBackupLOG order by name

open vCursor
fetch next from vCursor into @Banco,@state_desc
WHILE @@FETCH_STATUS = 0
begin
   if db_id(@Banco) is null begin
      print '*** ERRO: DB_ID retornou NULL para o banco ' + @Banco 
      fetch next from vCursor into @Banco,@state_desc
      continue
   end

   if @state_desc <> 'ONLINE' begin
     print '*** Banco: ' +  @Banco + ' está: ' + @state_desc
     FETCH NEXT FROM vCursor INTO @Banco,@state_desc 
     continue
  end

   Print 'Backup do Banco de Dados: ' + @Banco
   set @DataHora = CONVERT(varchar(1000),getdate(),112) + '_H' + replace(CONVERT(varchar(8),getdate(),114),':','') 
   if @Compacta = 'S'
      exec('BACKUP LOG [' + @Banco + ']  TO DISK = ''' + @Caminho + @Banco + '_' + @DataHora + '.trn'' WITH COMPRESSION')
   else
      exec('BACKUP LOG [' + @Banco + ']  TO DISK = ''' + @Caminho + @Banco + '_' + @DataHora + '.trn''')

   if @@ERROR <> 0 begin
      print '*** ERRO: backup do banco ' + @Banco + ' - Código de erro: ' + ltrim(str(@@error))
      fetch next from vCursor into @Banco,@state_desc
      continue
   end   
   
   fetch next from vCursor into @Banco,@state_desc
end
CLOSE vCursor
DEALLOCATE vCursor

if object_id('dbo.tmpBancosBackupLOG') is not null
   drop table dbo.tmpBancosBackupLOG
go

/********************************************
 Exclui Histórico dos Backups
*********************************************/
declare @DelDate datetime
set @DelDate = DATEADD(wk,-4,getdate())

EXECUTE master.dbo.xp_delete_file 0,N'C:\_LIVE\Backup\LOG',N'trn',@DelDate,0
go
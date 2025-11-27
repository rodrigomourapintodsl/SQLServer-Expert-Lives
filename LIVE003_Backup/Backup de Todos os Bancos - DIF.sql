/*********************************************
 LIVE #003 - Canal SQL Server Expert

 Hands On - Backup todos os Bancos DIF
**********************************************/
use master
go

declare @Caminho varchar(4000), @Banco varchar(500), @Compacta char(1),@Arquivo varchar(4000)
declare @state_desc varchar(200)
set @Caminho = 'C:\_LIVE\Backup\DIF\' 
set @Compacta = 'S'

if object_id('dbo.tmpBancosBackupDIF') is not null
   drop table dbo.tmpBancosBackupDIF

select name,state_desc 
into dbo.tmpBancosBackupDIF 
from sys.databases 
where source_database_id is null
and state_desc = 'ONLINE' 
and name not in ('tempdb','master','model') 
ORDER BY name

declare vCursor cursor for
select name,state_desc from dbo.tmpBancosBackupDIF order by name

open vCursor
fetch next from vCursor into @Banco,@state_desc
WHILE @@FETCH_STATUS = 0
begin
   waitfor delay '00:00:05' 

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
   set @Arquivo = @Banco + '_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.dif'

   if @Compacta = 'S'
      exec('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + ''' WITH FORMAT, COMPRESSION, DIFFERENTIAL')
   else
      exec('BACKUP DATABASE [' + @Banco + ']  TO DISK = ''' + @Caminho + @Arquivo + ''' WITH FORMAT, DIFFERENTIAL')

   if @@ERROR <> 0 begin
      print '*** ERRO: backup do banco ' + @Banco + ' - Código de erro: ' + ltrim(str(@@error))
      fetch next from vCursor into @Banco,@state_desc
      continue
   end   
  
   fetch next from vCursor into @Banco,@state_desc
end
CLOSE vCursor
DEALLOCATE vCursor

if object_id('dbo.tmpBancosBackupDIF') is not null
   drop table dbo.tmpBancosBackupDIF
go

/********************************************
 Exclui Histórico dos Backups
*********************************************/
declare @DelDate datetime
set @DelDate = DATEADD(wk,-4,getdate())

EXECUTE master.dbo.xp_delete_file 0,N'C:\_LIVE\Backup\DIF',N'dif',@DelDate,0
go

/***************************************************
 Backup Master
****************************************************/
DECLARE @Arquivo varchar(4000),@Caminho varchar(4000)
set @Caminho = 'C:\_LIVE\Backup\FULL\'

set @Arquivo = @Caminho + 'master_' + convert(char(8),getdate(),112)+ '_H' + replace(convert(char(8),getdate(),108),':','') + '.bak'
BACKUP DATABASE master TO DISK = @Arquivo WITH FORMAT, COMPRESSION
go

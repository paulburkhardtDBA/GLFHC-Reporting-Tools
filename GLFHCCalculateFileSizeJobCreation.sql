USE [msdb]
GO

/****** Object:  Job [GLFHC CalculateFileSize]    Script Date: 12/12/2025 1:35:22 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 12/12/2025 1:35:22 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'GLFHC CalculateFileSize', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This script is a variation of http://www.mssqltips.com/sqlservertip/3192/collect-database-and-table-index-grow-statistics-for-all-sql-servers-using-powershell/ and is used to gather data (mdf and ldf files) on all CMS registered servers', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [load data]    Script Date: 12/12/2025 1:35:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'load data', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'$today = Get-Date
ForEach ($instance in Get-Content "C:\Code\JustServerNameList.txt")
{

    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
    $s = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $instance
    $dbs=$s.Databases           
    foreach ($db in $dbs) 
        {
          if ( $db.IsAccessible ) 
		   {
			$dbname =$db.name
			$dbrecovery = $db.recoverymodel
			$fileGroups = $db.FileGroups
			ForEach ($fg in $fileGroups)
            {
			  if ($fg)
			  {
				$mdfInfo = $fg.Files | Select Name, FileName, size, UsedSpace
				$dbname =$db.name
				$mdfname =$mdfInfo.Name
				$mdfFileName = $mdfInfo.FileName
				$mdfFileSize = $mdfInfo.size 
				$mdfUsedSpace = $mdfInfo.UsedSpace

				$logInfo = $db.LogFiles | Select Name, FileName, Size, UsedSpace
				$ldfname =$logInfo.Name
				$ldfFileName = $logInfo.FileName
				$ldfFileSize = $logInfo.size 
				$ldfUsedSpace = $logInfo.UsedSpace 
				####Write-host "$instance,$dbname,$dbrecovery,$today,$mdfname,$mdfFileSize,$mdfUsedSpace,$ldfname,$ldfFileSize,$ldfUsedSpace"
				switch ($dbname ) 
					{
					''master'' {}
					''model''  {}
					''Northwind'' {}
					''tempdb'' {}
					Default {	
							Invoke-SQLcmd -ServerInstance "GB4-50246\MSSQL2019DEV" -Database "Tools" -Query "INSERT INTO is_sql_databases VALUES (''$instance'',''$dbname'',''$dbrecovery'',''$today'',''$mdfname'',''$mdfFileSize'',''$mdfUsedSpace'',''$ldfname'',''$ldfFileSize'',''$ldfUsedSpace'')"
							}
					}
				}	
			}
		  }
		}
	}', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Query Log Databases]    Script Date: 12/12/2025 1:35:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Query Log Databases', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use Tools
go
------Query to get DB growth for today, yesterday, and a week ago
select  LEFT(is_sqlserver,25) as ''SERVERNAME''
  ,LEFT(is_ldfname,25) AS ''Log DATABASE''
  ,MAX( CASE DateDiff(Day,is_date_stamp, getdate() )
      WHEN 0 THEN is_date_stamp
      Else ''02/02/1947''
      END ) as ''TODAY''
 ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0
      END ) ,12)  as ''SIZE TODAY''
 ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 1 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0
      END ) ,12) as ''SIZE YESTERDAY''
      
  ,LEFT(MAX( CASE DateDiff(Day,is_date_stamp, getdate() )
      WHEN 0 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0 END ) -
  MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 1 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0
      END ) ,12) as ''DAILY INCREASE mb''
      
 ,LEFT( MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 7 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0
      END ) ,12 ) as ''SIZE WEEK-AGO''  
      
     ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0 END ) -
      MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 7 THEN cast(is_ldfFileSize as decimal(12,1) )
      Else 0
      END ) ,12) as ''WEEKLY INCREASE mb''  
      
from is_sql_databases
where  DateDiff(Day, is_date_stamp, getdate() ) < 8    
group by is_sqlserver, is_ldfname
having 
MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN is_ldfFileSize
      Else 0
      END )  -   
 MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 1 THEN is_ldfFileSize
      Else 0
      END ) > 5
      
ORDER BY is_sqlserver, is_ldfname      

', 
		@database_name=N'master', 
		@output_file_name=N'C:\Output\Database_Growth.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [email LDF results]    Script Date: 12/12/2025 1:35:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'email LDF results', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'powershell –ExecutionPolicy Bypass -file "C:\Code\Email_LDFResults.ps1"', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Query MDF databases]    Script Date: 12/12/2025 1:35:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Query MDF databases', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use Tools
go
------Query to get DB growth for today, yesterday, and a week ago
select  LEFT(is_sqlserver,25) as ''SERVERNAME''
  ,LEFT(is_name,25) AS ''DATABASE''
  ,MAX( CASE DateDiff(Day,is_date_stamp, getdate() )
      WHEN 0 THEN is_date_stamp
      Else ''02/02/1947''
      END ) as ''TODAY''
 ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0
      END ) ,12)  as ''SIZE TODAY''
 ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 1 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0
      END ) ,12) as ''SIZE YESTERDAY''
      
  ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0 END ) -
  MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 1 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0
      END ) ,12) as ''DAILY INCREASE mb''
      
 ,LEFT( MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 7 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0
      END ) ,12 ) as ''SIZE WEEK-AGO''  
      
     ,LEFT(MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0 END ) -
      MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 7 THEN cast(is_mdfFileSize as decimal(12,1) )
      Else 0
      END ) ,12) as ''WEEKLY INCREASE mb''  
      
from is_sql_databases
where  DateDiff(Day, is_date_stamp, getdate() ) < 8    
group by is_sqlserver, is_name
having 
MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 0 THEN is_mdfFileSize
      Else 0
      END )  -   
 MAX( CASE DateDiff(Day, is_date_stamp, getdate() )
      WHEN 1 THEN is_mdfFileSize
      Else 0
      END ) > 5
      
ORDER BY is_sqlserver, is_name      

', 
		@database_name=N'master', 
		@output_file_name=N'C:\Output\Database_Growth.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [email MDF results]    Script Date: 12/12/2025 1:35:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'email MDF results', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'powershell –ExecutionPolicy Bypass -file "C:\Code\Email_MDFResults.ps1"', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily_07:00AM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200723, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959, 
		@schedule_uid=N'cca94d2f-eb40-4249-a767-00bf15bd840b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



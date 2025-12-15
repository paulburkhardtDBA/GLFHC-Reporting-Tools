USE [msdb]
GO

/****** Object:  Job [Change Request Report]    Script Date: 12/12/2025 1:44:22 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/12/2025 1:44:22 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Change Request Report', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run new script]    Script Date: 12/12/2025 1:44:23 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run new script', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/*
FileName:	ChangeReportByTechnician.sql


*/
-- Define variables
DECLARE @mailsubject  NVARCHAR(MAX)
-- Set Variables

SET @mailsubject = ''Change Requests Distribution Report on '' + @@servername

-- Email Query with Results

	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = ''MSSQL'', 
	@recipients = ''wyang@glfhc.org'',
	@query = ''
SELECT	a.FIRST_NAME AS "Change Owner", 
		COUNT(a.FIRST_NAME) AS "Total Changes"
FROM ChangeDetails chdt 
LEFT JOIN SDUser ownsd 
	ON chdt.TECHNICIANID=ownsd.USERID 
LEFT JOIN AaaUser a 
	ON ownsd.USERID=a.USER_ID 
WHERE  ( ( chdt.DELETEDTIME IS NULL ) AND ( chdt.DELETEDTIME IS NULL )  and (a.FIRST_NAME IS NOT NULL) and (a.FIRST_NAME <> ''''Administrator'''')) 
GROUP BY a.FIRST_NAME
ORDER BY COUNT(a.FIRST_NAME) 

SELECT 
CASE
	WHEN A.FIRST_NAME = ''''Hanson, Corey'''' OR A.FIRST_NAME = ''''MacNeil, Daniel'''' OR A.FIRST_NAME = ''''Pena (Santiago), Abigail'''' OR A.FIRST_NAME = ''''Wagner, Brendilee'''' OR A.FIRST_NAME = ''''Kantargis, Susan'''' OR A.FIRST_NAME = ''''Caloggero, Lynne'''' OR A.FIRST_NAME = ''''Phillips, Helen'''' THEN  ''''Applications''''
	WHEN  A.FIRST_NAME = ''''Horwath, Jacob'''' OR A.FIRST_NAME = ''''Goodwin, Cory'''' OR A.FIRST_NAME = ''''Lemay, Marc'''' OR A.FIRST_NAME = ''''Malerbi, Jim'''' OR A.FIRST_NAME = ''''Cora, Mike'''' OR A.FIRST_NAME = ''''Howard, Dana'''' OR A.FIRST_NAME = ''''Burkhardt, Paul'''' OR A.FIRST_NAME = ''''Bicknell, Brian'''' OR A.FIRST_NAME = ''''Ruggiero, Joseph'''' OR A.FIRST_NAME = ''''Avery, Timothy'''' OR A.FIRST_NAME = ''''Beaulieu, Malcolm'''' THEN ''''Senior Infratructure''''
	WHEN  A.FIRST_NAME = ''''Kendall, Shane'''' OR A.FIRST_NAME = ''''Utley, John'''' OR A.FIRST_NAME = ''''Buck, Kenneth'''' OR A.FIRST_NAME = ''''Monge, E. Yvonne'''' THEN ''''Infrastructure''''
	WHEN  A.FIRST_NAME = ''''Mathews, Gina'''' OR A.FIRST_NAME = ''''Sirois, Normand'''' THEN ''''Business Intelligence''''
	END,
	COUNT(A.FIRST_NAME) As [Total Changes]
FROM ChangeDetails chdt 
LEFT JOIN SDUser ownsd 
	ON chdt.TECHNICIANID=ownsd.USERID 
LEFT JOIN AaaUser a 
	ON ownsd.USERID=a.USER_ID 
WHERE  ( ( chdt.DELETEDTIME IS NULL ) AND ( chdt.DELETEDTIME IS NULL )  and (a.FIRST_NAME IS NOT NULL) and (a.FIRST_NAME <> ''''Administrator'''')) 
GROUP BY CASE 
	WHEN A.FIRST_NAME = ''''Hanson, Corey'''' OR A.FIRST_NAME = ''''MacNeil, Daniel'''' OR A.FIRST_NAME = ''''Pena (Santiago), Abigail'''' OR A.FIRST_NAME = ''''Wagner, Brendilee'''' OR A.FIRST_NAME = ''''Kantargis, Susan'''' OR A.FIRST_NAME = ''''Caloggero, Lynne'''' OR A.FIRST_NAME = ''''Phillips, Helen'''' THEN  ''''Applications''''
	WHEN  A.FIRST_NAME = ''''Horwath, Jacob'''' OR A.FIRST_NAME = ''''Goodwin, Cory'''' OR A.FIRST_NAME = ''''Lemay, Marc'''' OR A.FIRST_NAME = ''''Malerbi, Jim'''' OR A.FIRST_NAME = ''''Cora, Mike'''' OR A.FIRST_NAME = ''''Howard, Dana'''' OR A.FIRST_NAME = ''''Burkhardt, Paul'''' OR A.FIRST_NAME = ''''Bicknell, Brian'''' OR A.FIRST_NAME = ''''Ruggiero, Joseph'''' OR A.FIRST_NAME = ''''Avery, Timothy'''' OR A.FIRST_NAME = ''''Beaulieu, Malcolm'''' THEN ''''Senior Infratructure''''
	WHEN  A.FIRST_NAME = ''''Kendall, Shane'''' OR A.FIRST_NAME = ''''Utley, John'''' OR A.FIRST_NAME = ''''Buck, Kenneth'''' OR A.FIRST_NAME = ''''Monge, E. Yvonne'''' THEN ''''Infrastructure''''
	WHEN  A.FIRST_NAME = ''''Mathews, Gina'''' OR A.FIRST_NAME = ''''Sirois, Normand'''' THEN ''''Business Intelligence''''
	END
ORDER BY [Total Changes]
'',
	@execute_query_database = ''servicedesk'',
	@subject = @mailsubject,
	@body = ''Attached is the cumluative frequency of Change Requests by individal and Groups'',
	@attach_query_result_as_file = 1;
', 
		@database_name=N'master', 
		@database_user_name=N'glfhc\pburkhardt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monday_9:00AM', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20220510, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'bdb67af1-e241-4fa0-911d-299a74b329a2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



<# 
FileName:	GLFHCFindFailedSQLJobs.ps1
Purpose:	This script will look at each of the SQL Server instances in the server list file
			(JustServerNameList.txt), create a listing of SQL jobs that failed, and email that
			list.
			
	Date			Author						DESCRIPTION
==============		======		==========================================================
09/07/2023			peb					Original Version
			
#>
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCFindFailedSQLJobs_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
$Subj = "GLFHC SQL Failed Jobs Report for $NewReportDate on $ThisServer."

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query to list suspect pages
$sql = "
USE msdb
GO

DECLARE @DaysBack INT = 3; -- Review data for the last 3 days.

SELECT 
@@servername
,  sj.[name] JobName
, sjh.step_name
, message
, dbo.agent_datetime(sjh.run_date, sjh.run_time) JobRunTime
, CASE WHEN sjh.run_duration > 235959
           THEN CAST((CAST(LEFT(CAST(sjh.run_duration AS VARCHAR), LEN(CAST(sjh.run_duration AS VARCHAR)) - 4) AS INT) / 24) AS VARCHAR) + '.' + RIGHT('00' + CAST(CAST(LEFT(CAST(sjh.run_duration AS VARCHAR), LEN(CAST(sjh.run_duration AS VARCHAR)) - 4) AS INT) % 24 AS VARCHAR), 2) + ':' + STUFF(CAST(RIGHT(CAST(sjh.run_duration AS VARCHAR), 4) AS VARCHAR(6)), 3, 0, ':')
       ELSE STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(sjh.run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
  END AS Duration
FROM dbo.sysjobs sj
  INNER JOIN dbo.sysjobhistory sjh ON sj.job_id = sjh.job_id
WHERE sjh.run_status <> 1 --1 = success
  AND dbo.agent_datetime(sjh.run_date, sjh.run_time) > DATEADD(dd, ABS(@DaysBack) * -1, SYSDATETIME())
ORDER BY
  sj.[name]
, sjh.step_id
, dbo.agent_datetime(sjh.run_date, sjh.run_time)
"
# gather info from each server in file and export to .csv
Foreach ($ss in $sqlservers) 
{
   Invoke-Sqlcmd -ServerInstance $ss -Query $sql | Export-Csv $outfile -NoTypeInformation -Append
}
start-sleep -s 15  

#if the file in not empty, then data exists so send it
IF ((Get-Content -Path $OutFile).length -ne 0)
{

	# Send Email
	$Attachment= $OutFile
	$emailFrom = "wyang@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$Subject = $subj 
	$Body = "Please review this list and determine what action should be taken to correct the problems..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
	$SMTPMessage.Attachments.Add($Attachment)
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)

}
ELSE
{
		# Send Email
	$Subj = "GLFHC SQL DB Suspect Page Report for $NewReportDate on $ThisServer."
	$Attachment= $OutFile
	$emailFrom = "pburkhardt@glfhc.org"
	$emailTo = "pburkhardt@glfhc.org"
	$Subject = $subj 
	$Body = "No databases had suspect page issues..."
	$smtpServer = "mail.glfhc.org"
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
<#
	$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
	$SMTPMessage.Attachments.Add($Attachment)
#>
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
	$SMTPClient.EnableSsl = $true
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)
}
	
			
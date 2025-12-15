<# 
FileName:	GLFHCSQLJobsRunning
Purpose:	This scrit writes the server, job name, requestes run (start) date/time, and total elapse time
			to an output file for a list of SQL Servers specified in a file to a .csv file.
			In turn, this list can be reviewed to see which SQL Server instances need the latest Service Pack.
			
			Remember to change $threshold and @threshold values
#>
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$date = get-date -format "yyyyMMddHHmm"
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCSQLJobsRunning_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
$threshold = 1
$Subj = "GLFHC SQL Jobs Currently Running longer than $threshold hours for $NewReportDate on $ThisServer."

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring 

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query
$sql = "
declare @status varchar(10)
declare @threshold int
declare @sub nvarchar(100)

set @status = 'EXECUTING'
set @threshold = 1

SELECT
    job.originating_server,
    job.name, 
	@status as [Status],
    activity.run_requested_date, 
   replace(convert(varchar(5),CONVERT(varchar,DATEDIFF(SECOND, activity.run_requested_date, GETDATE()),114)/3600)
   +':'+str(convert(varchar(5),CONVERT(varchar,DATEDIFF(SECOND, activity.run_requested_date, GETDATE()),114)%3600/60),2)
   +':'+str(convert(varchar(5),(CONVERT(varchar,DATEDIFF(SECOND, activity.run_requested_date, GETDATE()),114)%60)),2),' ','0')
   as [Hours Elapsed]
FROM 
    msdb.dbo.sysjobs_view job
JOIN
    msdb.dbo.sysjobactivity activity
ON 
    job.job_id = activity.job_id
JOIN
    msdb.dbo.syssessions sess
ON
    sess.session_id = activity.session_id
JOIN
(
    SELECT
        MAX( agent_start_date ) AS max_agent_start_date
    FROM
        msdb.dbo.syssessions
) sess_max
ON
    sess.agent_start_date = sess_max.max_agent_start_date
WHERE 
    run_requested_date IS NOT NULL AND stop_execution_date IS NULL
	and  convert(varchar(5),CONVERT(varchar,DATEDIFF(SECOND, activity.run_requested_date, GETDATE()),114)/3600) > @threshold
"
# gather info from each server in file and export to .csv
Foreach ($ss in $sqlservers) 
{
   Invoke-Sqlcmd -ServerInstance $ss -Query $sql | Export-Csv $outfile -NoTypeInformation -Append
}
start-sleep -s 15  

#if the file in not empty, then data exists so send it
IF ((Get-Content -Path $outFile).length -ne 0)
{
	# Send Email
	$Attachment= $OutFile
	$emailFrom = "wyang@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$Subject = $subj 
	$Body = "Please review this list and take corrective action if needed ..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
	$SMTPMessage.Attachments.Add($Attachment)
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)
Write-Host "File found..."
}

			
<# 
FileName:	CheckSuspectPages.ps1
Purpose:	If any of the databases have suspect pages, they are written to the msdb database. So, this script
			searches all of the SQL instances for any records that would indicate a problem. Since we have a wide
			variety of SQL versions (2008 - 2022) here, it might not work for all instances.  In that case, they
			should be looked at individually.
			
#>
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCDBSuspectPages_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
$Subj = "GLFHC Review f SUspect pages in any databases for $NewReportDate on $ThisServer."

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring 


$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query to list suspect pages
$sql = "
SELECT	d.name as DatabaseName,
		mf.name as LogicalFileName,
		mf.physical_name as PhysicalFileName,
		sp.page_id,
		case sp.event_type
			when 1 then N'823 or 824 error'
			when 2 then N'Bad Checksum'
			when 3 then N'Torn Page'
			when 4 then N'Restored'
			when 5 then N'Repaired'
			when 7 then N'Deallocated'
		end as EventType,
		sp.error_count,
		sp.last_update_date
FROM msdb.dbo.suspect_pages as sp
JOIN sys.databases as d on 
	sp.database_id = d.database_id
JOIN sys.master_files as mf on
	sp.[file_id] = mf.[file_id]
AND d.database_id = mf.database_id

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

			
<# 
FileName:	InactiveSQLAccountList.ps1
Purpose:	This script searches thought the various SQL Servers here at GLFHC
			and compiles a list of user (domain or SQL) that are inactive.
			This report is mailed to the DBA so that it can be reviewed and
			remove those accounts from the user list.
			
	Date			Author						DESCRIPTION
==============		======		==========================================================
2/2/2023			peb					Original Version
			
#>
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCSQLInactiveUsers_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
$Subj = "GLFHC SQL Inactive User Report for $NewReportDate on $ThisServer."

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query to list suspect pages
$sql = "
SELECT @@ServerName as Server,
	name as Account, 
	type_desc as [Account Type], 
	CASE is_disabled
		WHEN 0 THEN 'Enabled'
		WHEN 1 THEN 'Disabled'
	END AS [Account Status]
FROM sys.server_principals
WHERE type IN ('U','S')
AND  is_disabled = 1 -- disabled user accounts
AND name NOT LIKE '##MS%' --Remove MS accounts
"
# gather info from each server in file and export to .csv
Foreach ($ss in $sqlservers) 
{
   Invoke-Sqlcmd -ServerInstance $ss -Query $sql | Export-Csv $outfile -NoTypeInformation -Append
}
start-sleep -s 15  

#if the file in not empty, then data exists so send it

	# Send Email
	$Attachment= $OutFile
	$emailFrom = "wyang@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$Subject = $subj 
	$Body = "Please review this list and remove user accounts..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
	$SMTPMessage.Attachments.Add($Attachment)
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)


			
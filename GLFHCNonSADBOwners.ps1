<# 
FileName:	GLFHCNonSADBOwners.ps1
Purpose:	This script will look at each of the SQL Server instances in the server list file
			(JustServerNameList.txt), create a listing of SQL jobs that are not owned by SA.
			
	Date			Author						DESCRIPTION
==============		======		==========================================================
04/25/2024			peb					Original Version
			
#>
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCNonSADBOwners_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
$Subj = "GLFHC SQL Server Non SA Database Owners on $NewReportDate from $ThisServer."

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query to list configuration changes
$sql = "
SELECT @@SERVERNAME Server, d.[name] DBName, d.create_date, p.[name] PrincipalName
FROM sys.databases d
  LEFT OUTER JOIN sys.server_principals p ON d.owner_sid = p.[sid]
WHERE p.[name] NOT IN (N'sa'); 
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
	$Body = "Please review and correct database ownershipownership..."
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

	
			
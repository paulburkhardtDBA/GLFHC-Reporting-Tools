<# 
FileName:	GLFHCPageVerificationCheck.ps1
Purpose:	This script examines each database on all the SQL Servers and looks for page verifications
			that are not "CHECKSUM.  If any cases are found, the database needs to be corrected/altered.
			The change will not immediately write a checksum for every page.  It will take time to 
			build this library.

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
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCDBPageVerify_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
$Subj = "GLFHC SQL DB Page verification Report for $NewReportDate on $ThisServer."

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring 

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query to list suspect pages
$sql = "
SELECT @@SERVERNAME, NAME, PAGE_VERIFY_OPTION_DESC 
FROM sys.databases
WHERE PAGE_VERIFY_OPTION_DESC <> 'CHECKSUM'
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
	$Body = "Please review this list and correct the problem..."
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
	$Subj = "GLFHC SQL DB Page verifications Report for $NewReportDate on $ThisServer."
	$Attachment= $OutFile
	$emailFrom = "wyang@glfhc.org"
	$emailTo = "wyang@glfhc.org"
	$Subject = $subj 
	$Body = "No databases had page verification issues..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
<#
	$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
	$SMTPMessage.Attachments.Add($Attachment)
#>
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)
}
			
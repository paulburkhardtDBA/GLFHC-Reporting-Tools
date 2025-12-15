<#
FileName:	VeeamSQLTrxLogBackupMonitor.ps1
Purpose:	Currently, there are 9 SQL transaction log backup jobs running throughout 
			the day.  This script will confirm that they are running...

NOTE:


Date		Author				Description
-------		------		------------------------------------

#>

# Suppress Error Messages
#$erroractionpreference = "SilentlyContinue"

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring 

# Connect to Veeam Server using credentials
connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xpburkhardt' -password '!$VeE@m2021!'

# Intialize counter

$iCount = 0

# List jobs
$jobs = Get-VBRJob

# Select only the SQL jobs
$SQLJob = $jobs.FindChildSqlLogBackupJob() 

# Get the SQL jobs that are running
$JobsRunning = $SQLJob |WHERE {$_.IsRunning -eq 'True'}
foreach ($jobs in $JobsRunning)
{

	# Increment Counter
	$icount++

}

# Create a loop to count the number of jobs that fit the criteria

write-output $iCount
# The number of jobs should be 8
# If that's not the case, then send an email notification

IF ($iCount -ne 8)
{
	# Send Email
<#
	$emailFrom = "pburkhardt@glfhc.org"  
	$emailTo = "pburkhardt@glfhc.org"
	$Subject = "!!! Alert - Missing Transaction Log Backups !!!" 
	$Body = "8 jobs should be running but only $iCount were found."
	$smtpServer = "mail.glfhc.org"
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject) 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
	$SMTPClient.EnableSsl = $true
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)	
#>
$msgSubject = "!!! Alert - Missing Transaction Log Backups !!!"
$msgBody = "9 jobs should be running but only " + $iCount + " were found."
$EmailTo = "pburkhardt@glfhc.org" 
$EmailFrom   = "pburkhardt@glfhc.org"  
$subject = $msgSubject
$Body = $msgBody
$smtpServer = "mail.glfhc.org"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)
}

# Finally Disconnect from server
Disconnect-VBRServer | Out-Null

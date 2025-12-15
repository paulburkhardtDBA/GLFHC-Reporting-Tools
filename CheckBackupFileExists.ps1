<#
FileName:	CheckBackupFileExists.ps1
Purpose:	This scrip will run daily and check if a backup file (Copy-Only) was created
			for the Centricity and Visdocv databases.  If one wasn't created in the past 24 hours,
			it will send out an email alert
Date		Author					Description
-----------	-------	--------------------------------------------
5/10/2022	peb				Original Version
#>

$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring
 
# Define Source locations to search
$f = '\\bi-prd-db01\MSSQL$Backup\LIVE-EMR-DB\centricityps\FULL_COPY_ONLY\*.bak'     
$e = '\\bi-prd-db01\MSSQL$Backup\LIVE-EMR-DB\centricityps_visdoc\FULL_COPY_ONLY\*.bak'

# Define counter
$iCount = 0
$jCount = 0

# Load directory contents into variables
$files = ls $f
$files2 = ls $e

# Loop through each file.  Increment a counter if a file was created
Foreach ($file in $files) {
    $createtime = $file.CreationTime
    $nowtime = get-date
   if (($nowtime - $createtime).totalhours -lt 24)
    { 
		# Increment Counter
		$iCount++
	}

}
Write-Host = "iCount = $iCount"
<#
If no files were found, then no backup was created
Send an alert
#>

IF ($iCount = 0)
{
	$emailFrom = "wyang@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$subject = "No Centricity Backup has been created in the past 24 hours!!!"  
	$Body = "Please investigate..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)
}

Foreach ($file2 in $files2) {
    $createtime = $file2.CreationTime
    $nowtime = get-date
   if (($nowtime - $createtime).totalhours -lt 24)
    { 
		# Increment Counter
		$jCount++
	}

}
Write-Host = "jCount = $jCount"
<#
If no files were found, then no backup was created
Send an alert
#>

IF ($jCount = 0)
{
	$emailFrom = "wyang@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$subject = "No Visdoc Backup has been created in the past 24 hours!!!"  
	$Body = "Please investigate..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)	
}



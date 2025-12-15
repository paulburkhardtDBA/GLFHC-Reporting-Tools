<#
File:		GLFHCSQLServerOSReport.ps1
Purpose:	To list all of the OSs for the servers that have SQL Server instances
			installed.
			
Date				Description
----------	-----------------------------------
#>
#Begin Script
#$erroractionpreference = “SilentlyContinue” 


# Main script  
$Servers = Get-Content "C:\Code\JustServerNameList.txt" 
$ThisServer = get-content env:computername

#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()
$Counter = 0
# Define Output FileName

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring


$date = get-date -format "yyyyMMddHHmm"
$ErrorLog = "C:\Output\Error_$date.log"

#let's set up the email stuff
$msg = new-object Net.Mail.MailMessage
$msg.Body = "Here is a list of the GLFHC SQL Servers and their respective Operating Systems..."

foreach ($Computer in $Servers)
{
TRY
{
$os = (Get-WMIObject Win32_OperatingSystem -ComputerName $computer).Caption

$msg.body   = $msg.body + "`n `n $Computer $os"
$Counter++

   
}
catch
{
	$msg.body   = $msg.body + "`n `n  $computer was not reachable"
	
#	Out-File -FilePath $ErrorLog -Append -InputObject $exception

	# Handle the error
	$Line = "Error found on Server " + $Computer.ToUpper()
	$Line | Out-File -append -FilePath $ErrorLog
	
	$err = $_.Exception
	#write-output  $err.Message
	#$err.Message = $_.Exception
	$err.Message | Out-File -append -FilePath $ErrorLog

	$intRow = $intRow + 1 
	continue
}
}

$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$Subject = "GLFHC SQL Server Operating System Report for $today from $ThisServer"
$Body = $msg.Body
$smtpServer = "smtpmail.glfhc.local"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

# Send Email 
<#
$emailFrom = "pburkhardt@glfhc.org"  
$emailTo = "pburkhardt@glfhc.org"
$Subject = "$mail_Message" 
$Body = $msg.Body
$smtpServer = "mail.glfhc.org"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)
#>
# End script 




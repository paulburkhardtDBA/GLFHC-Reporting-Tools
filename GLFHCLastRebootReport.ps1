<#
# File:		GLFHCServerUptimeReport.ps1
# Purpose:	To find and report on the CMS registered servers that have been
#		rebooted in the past 24 hours.
# Date		Description
# 7/19/13	Modified to send resulting in the body of email.

    Date	Author			Description
---------	------	---------------------------------------
6/15/2023	peb			Added Tim to email distribution
#>

#Begin Script
$erroractionpreference = "SilentlyContinue" 
function WMIDateStringToDate($Bootup) {  
    [System.Management.ManagementDateTimeconverter]::ToDateTime($Bootup)  
}  

#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring


# Main script  
$Servers = Get-Content "C:\Code\JustServerNameList.txt" 
$ThisServer = get-content env:computername

#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()
# Define Output FileName

$date = get-date -format "yyyyMMddHHmm"
$ErrorLog = "C:\Output\Error_$date.log"

#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

#let's set up the email stuff
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient("smtpmail.glfhc.local")
$msg.Body = "Here's when the GLFHC SQL Servers were last rebooted..."

foreach ($Computer in $Servers)
{
TRY
{
$computers = Get-WMIObject -class Win32_OperatingSystem -computer $computer  

	#"Connecting to $computer" | Write-Host -ForegroundColor Blue

    $Bootup = $computers.LastBootUpTime  

    $LastBootUpTime = WMIDateStringToDate($Bootup)  

    $now = Get-Date  

    $Uptime = $now - $lastBootUpTime  



	# now print the server and uptime 
	$msg.body   = $msg.body + "`n `n  $computer was last rebooted on $lastBootUpTime.."
   
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
# Send Email 

$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$Subject = "GLFHC SQL Server Reboot Report for $date from $ThisServer" 
$Body = $msg.Body
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


#who is this coming from
<#
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$msg.From = "pburkhardt@glfhc.org"
#and going to
$msg.To.Add("pburkhardt@glfhc.org")
#and a nice pretty title
$msg.Subject = "SQL Server Reboot Report for $today from $ThisServer"
#and BOOM! send that bastard!
$SMTPServer = "mail.glfhc.org" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password); 
$SMTPClient.Send($msg.From, $msg.To, $msg.Subject, $msg.Body)
#>
# End script 
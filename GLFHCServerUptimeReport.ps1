# File:		GLFHCServerUptimeReport.ps1
# Purpose:	To find and report on the CMS registered servers that have been
#		rebooted in the past 24 hours.
# Date		Description
# 7/19/13	Modified to send resulting in the body of email.

#Begin Script
#$erroractionpreference = “SilentlyContinue” 
function WMIDateStringToDate($Bootup) {  
    [System.Management.ManagementDateTimeconverter]::ToDateTime($Bootup)  
}  

# Main script  
$Servers = Get-Content "C:\Code\JustServerNameList.txt" 
$ThisServer = get-content env:computername
$Counter = 0
#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()


# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

#let's set up the email stuff
$msg = new-object Net.Mail.MailMessage
$msg.Body = "Here are the CMS registered server that were rebooted in the past 24 hours..."

foreach ($Computer in $Servers)
{
$computers = Get-WMIObject -class Win32_OperatingSystem -computer $computer  
 
foreach ($system in $computers) 
{  

    $Bootup = $system.LastBootUpTime  

    $LastBootUpTime = WMIDateStringToDate($Bootup)  

    $now = Get-Date  

    $Uptime = $now - $lastBootUpTime  

    $d = $Uptime.Days  

    $h = $Uptime.Hours  

    $m = $uptime.Minutes  

    $ms= $uptime.Milliseconds  

	If ($d -lt 1)
	{
		$msg.body = $msg.body + "`n `n  $computer has been up for {0} days, {1} hours, {2}.{3} minutes" -f $d,$h,$m,$ms
		$Counter++ 
	}

}   

}
IF ($Counter -gt 0)
{
	$emailFrom = "pburkhardt@glfhc.org"  
	$emailTo = "pburkhardt@glfhc.org"
	$Subject = "GLFHC SQL Server Uptime Report for $today from $ThisServer"
	$Body = $msg.Body
	$smtpServer = "mail.glfhc.org"
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
	$SMTPClient.EnableSsl = $true
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)
}
# End script 




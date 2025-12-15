#############################################################################################################
# NAME: Ping-Host.ps1
# PURPOSE: To run through the list of server and ping them.  If there's not reachable
#		   then we have a problem.
# COMMENT: If using a CSV file, you must have a column name fqdn in order for script to complete.
# EXAMPLE: c:\code\ping-host.ps1 -sourcefile c:\Code\JustServerNameList.txt -outfile c:\Output\PingHosts.csv
# REFERENCE: http://powershell.com/cs/media/p/19691.aspx
# Date			Description
# 12/7/12		original version
# 1/11/2013		Replace ping method with a newer one
# 5/19/2021		Changed email to only list when one or more servers is unreachable
# 7/7/2021      Removed that previous change so that all servers are reported
###############################################################################################################

$start = get-date
write-host "Start: "  $start
#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

# Location of the Source File for script (server names only)
$serverlist = Get-Content "C:\Code\JustServerNameList.txt"

$ThisServer = get-content env:computername

#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()

#let's set up the email stuff
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient("smtpmail.glfhc.local")
$msg.Body = "Here are thr GLFHC SQL Servers that a currently reacheable: `n `n "
$offline = 0

#Write Headers
#Write-Output "ServerName,IP,RespondsToPING" | Out-File $OutFile -force 

foreach ($server in $serverlist)
{

	$status=get-wmiobject win32_pingstatus -Filter "Address='$Server'" -Credential $credential  | Select-Object statuscode

	if($status.statuscode -eq 0) 
	{
		#write-host "$server is online"
		$msg.body = $msg.body + "`n $server is on-line."
	} 
	else 
	{
		#write-host "*****$server is offline*****"
		$msg.body = $msg.body + "`n ******$server is off-line.******."
		$offline = $offline + 1
	}
}

#once all that loops through and builds our $msg.body, we are read to send
#if any serves are offline, list all of them

#who is this coming from
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$msg.From = "wyang@glfhc.org"
#and going to
$msg.To.Add("wyang@glfhc.org")
#and a nice pretty title
$msg.Subject = "SQL Servers Off-line is $offline for $today from $ThisServer"
#and BOOM! send that bastard!
$SMTPServer = "smtpmail.glfhc.local" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25) 
#$SMTPClient.EnableSsl = $true 
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password); 
$SMTPClient.Send($msg.From, $msg.To, $msg.Subject, $msg.Body)

Remove-Variable  * -Scope Global -ErrorAction SilentlyContinue
	
$end = get-date
write-host "End: "  $end
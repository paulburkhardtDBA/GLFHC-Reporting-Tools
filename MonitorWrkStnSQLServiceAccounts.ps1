<#
FileName:	
Purpose:	This scipt monitors the (Windows) SQL Services that are running on my workstation (GB4-50246).
			If any of these services are not running, it writes the service status, name, and displayname
			to an output file. Then, that file is sent to the DBA as an alert for corrective action.
			
			Of course, if the machine goes down, so does this monitoring tool.  :-(


date		author					description
========	======	===================================================
11/29/2022	peb			original version
#>
#$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$date = get-date -format "yyyyMMddHHmm"
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("MonitorLocalSQLServices_" + $isodate + ".txt")

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# define target computer to be monitored
$server = "GB4-50246"

# load all SQL services characteristics into a variable
$SQLServices = Get-service *SQL* -computername $server

# now, loop through each element (service)
Foreach ($SQLService in $SQLServices)
{
	if ($SQLService.Status -ne "Running")
	{
		# Something is wrong
		# First, increment the counter
		$icount++
	if ($icount -eq 1)
	{

		# Create a new mail message
		$msg = new-object Net.Mail.MailMessage
		$smtp = new-object Net.Mail.SmtpClient("mail.glfhc.org")
		$msg.Body = "Alert!!! SQL Service(s) not running on Server " + $server.ToUpper()
	}	
		# define variables
		$SrvStatus = $SQLService.Status
		$SrvName = $SQLService.Name
		$SrvDisplay = $SQLService.DisplayName
				
		# Now, output the results to a file
		$msg.Body = $msg.Body + " `r
			STATUS = $SrvStatus 
			Name = $SrvName
			DisplayName = $SrvDisplay"

	}	
}
# if there's a problem, send out an email notifiction
if ($icount -ge 1)
{
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$msg.From = "pburkhardt@glfhc.org"
	#and going to
	$msg.To.Add("pburkhardt@glfhc.org")
	#and a nice pretty title
	$msg.Subject = "Alert!!! SQL (Windows) Services not Running on $ThisServer at $today!!!~"
	#and BOOM! send that bastard!
	$SMTPServer = "mail.glfhc.org" 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
	$SMTPClient.EnableSsl = $true 
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password); 
	$SMTPClient.Send($msg.From, $msg.To, $msg.Subject, $msg.Body)
}
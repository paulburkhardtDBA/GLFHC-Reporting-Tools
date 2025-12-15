#$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$date = get-date -format "yyyyMMddHHmm"

# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# define servers in AlwaysOn Cluster
$Servers = "IS-SQL-AAG-01",,"IS-SQL-AAG-02","IS-SQL-AAG-03"

# loop through each server
Foreach ($Server in $Servers)
{
$SQLServices = Get-service *SQL* -computername $Server

# loop through each service
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
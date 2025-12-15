<#
FileName:	SchedTaskErrorRpt.ps1
Purpose:	This job runs to determine if the last GitHub Push ran successfully.  
		If it didn't, then an email notification is sent.
ref - 		https://stackoverflow.com/questions/40386280/how-to-send-email-when-specific-scheduled-task-fails-to-run

#>

# Local variables
$ThisServer = get-content env:computername 

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring 

#  Search for last Task Results
$ScheduledTaskName = "Git Push to Powershell Repo"
$Result = (schtasks /query /FO LIST /V /TN $ScheduledTaskName  | findstr "Result")
$Result = $Result.substring(12)
$Code = $Result.trim()

# if not 0, then email report
If ($Code -gt 0) 
{
    	$User = "admin@company.com"
    	$Pass = ConvertTo-SecureString -String "myPassword" -AsPlainText -Force
    	$Cred = New-Object System.Management.Automation.PSCredential $User, $Pass

	$emailFrom = "wyangt@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$Subject = "Scheduled task 'Git Push to Powershell Repo' failed on $ThisServer"
	$Body = "Error code: $Code"
	$SMTPServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)
}
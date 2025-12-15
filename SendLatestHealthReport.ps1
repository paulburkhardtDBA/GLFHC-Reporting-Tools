<#
FileName:	SendLatestHealthReport.ps1
Purpose:	This script takes the latest report "Health Report" that was been generated
		and emails it to the DBA to review.

#>
# Get Computer Name
$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()

# Define Directory and File to search 
$FileName = "C:\Output\GLFHCSQLHealthCheck*.*"

# locate the most current file
$LastestFile = (Get-ChildItem $FileName -File | Sort-Object LastWriteTime -Descending| Select-Object -First 1)

# Now capture the file name and date
$latest_filename = $LastestFile.Name 
$lastest_time = $LastestFile.LastWriteTime

# Construct the full file name and directory for mailing
$Outfile = "C:\Output\"+$latest_filename

# Now, if the file was created today, then mail the most recent one
# This feature allows for running the script multiple times per day
IF ($lastest_time -gt (Get-Date).AddDays(-1))
{
	write-host " File found - time to mail it..."	
	$Attachment= $OutFile
	$emailFrom = "wyang@glfhc.org"  
	$emailTo = "wyang@glfhc.org"
	$Subject = "GLFHC SQL Health Report Created on $today from $ThisServer Server"
	$Body = "Please review this list and take corrective action if needed ..."
	$smtpServer = "smtpmail.glfhc.local"
	#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
	$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
	$SMTPMessage.Attachments.Add($Attachment)
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
	#$SMTPClient.EnableSsl = $true
	#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$SMTPClient.Send($SMTPMessage)}
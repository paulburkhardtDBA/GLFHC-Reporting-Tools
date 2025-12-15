<#
FileName:	VeeamScheduledFullBAckups.ps1
Purpose:	This script will list when the Full (Active) backups
		are scheduled.

Date		Author				Description
-------		------		------------------------------------
11/14/2023	PEB			Orginal Version
11/16/2023	PEB			Add SysAdmins to email
#>
# turn off error messaging
#$erroractionpreference = "SilentlyContinue"

# Configuration data.
# define local variables
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$ThisServer = get-content env:computername
# Connect to the Veeam Server by asking for Credentials ( username & password)
#### For testing, use your account creds
#connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xpburkhardt' -password '!$VeE@m2021!'
connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xwyang' -password 'EXpcW8ue*g$tkmS@Ro9P'
#Connect-VBRServer -server "hav-veeam"  -Credential (Get-Credential)

#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

# define output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("VeeamScheduleFullBackup_" + $isodate + ".txt")

# Generate list and output to file
Get-VBRJob | where {$_.Name -like "*SQL*" -and $_.JobType -eq "Backup"} | select -Property @{N="Name";E={$_.Name}}, @{N="Full Backup Days";E={$_.BackupTargetOptions.FullBackupDays}} | ft -AutoSize >$OutFile

# Disconnect from server
Disconnect-VBRServer | Out-Null

## Send Mail 

$Attachment= $OutFile
$emailFrom = "wyang@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailTo = "BackupAdministrators@glfhc.org"
#$emailTo = "wyang@glfhc.org"
$subject = "Veeam Scheduled Full Backups for $date from $ThisServer"  
$Body = "Please review the attached report..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)
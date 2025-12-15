<#
FileName:	VeeamLastFullBackup.ps1
Purpose:	Ths script reports on the time that the last full (Active) backup
			was performed on the servers.
			
Date		Author				Description
-------		------		------------------------------------
11/14/2023	PEB			Orginal Version
11/16/2023	PEB			Add SysAdmins to email
12/7/2023	PEB			Add StartTime to report
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
#Connect-VBRServer -server "hav-veeam"  -Credential (Get-Credential)
connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xwyang' -password 'EXpcW8ue*g$tkmS@Ro9P'

#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

# define output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("VeeamLastFullBackup_" + $isodate + ".txt")


# Defining output format for each column.
$fmtName   =@{label="Job Name" ;alignment="left"  ;width=20 ;Expression={$_.JobName};};
$fmtStartTime   =@{label="Start Time"   ;alignment="left"  ;width=25 ;Expression={$_.CreationTime};};
$fmtEndTime   =@{label="End Time"   ;alignment="left"  ;width=25 ;Expression={$_.EndTime};};

foreach($job in (Get-VBRJob | ? {$_.JobType -eq "Backup"}))
{
$job = Get-VBRBackupSession | ?{$_.Jobname -eq $Job.name -and $_.JobType -eq "Backup" -AND $_.IsFullMode -eq "True" -eq "True" -AND $_.IsCompleted -eq "True" -AND $_.Result -ne "Failed"} | Sort-Object EndTime -Descending | Select-Object -First 1 | select JobName, CreationTime, EndTime
$job | Format-Table $fmtName, $fmtStartTime, $fmtEndTime | Out-File -append -filePath $OutFile 
} 
# Disconnect from server
Disconnect-VBRServer | Out-Null


## Send Mail 

$Attachment= $OutFile
$emailFrom = "wyang@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailTo = "BackupAdministrators@glfhc.org"
#$emailTo = "wyang@glfhc.org"
$subject = "GLFHC Last Full Backup Report for $date from $ThisServer"  
$Body = "Please review the attached report..."
#$smtpServer = "mail.glfhc.org"
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

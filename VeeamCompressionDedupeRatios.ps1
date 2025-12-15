<#
FileName:	VeeamCompressionDedupeRatios.ps1
Purpose:	Ths script reports on the time that the last full (Active) backup
			was performed on the servers.
ref:  https://benyoung.blog/extracting-veeam-compression-and-dedupe-ratios-from-backup-using-powershell/

			
Date		Author				Description
-------		------		------------------------------------
12/13/2023	PEB			Orginal Version
12/14/2023	PEB 		Added BackupAdmins to distributin list after checking with Joe
12/18/2023  PEB			Change output file Width to 132

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
$OutFile = Join-Path -path $FilePath -childPath ("VeeamCompressionDedupeRatios_" + $isodate + ".txt")

# collect all backup information
$backup = Get-VBRBackup

# Now, create a selected list of fields
$Report = $backup.GetAllStorages() | 
Sort-Object CreationTime -Descending | 
Format-Table @{Name="VM"; Expression={$_.PartialPath.ToString().Split('.')[0]}},
# @{Name="Filename"; Expression={$_.PartialPath}}, #uncomment if you want the filename on disk.
@{Name="Data Size GB"; Expression={[math]::Round($_.Stats.DataSize/1GB, 2)}},
@{Name="Backup On Disk GB"; Expression={[math]::Round($_.Stats.BackupSize/1GB, 2)}} ,
@{Name="Dedupe"; Expression={[math]::Round(100/($_.Stats.DedupRatio), 2)}},
@{Name="Compression Ratio"; Expression={[math]::Round(100/($_.Stats.CompressRatio), 2)}},
@{Name="Created"; Expression={$_.CreationTime}} 

# finally, put that data into a file
$Report | Out-File $OutFile -Width 132
 
# Disconnect from server
Disconnect-VBRServer | Out-Null

## Send Mail 

$Attachment= $OutFile
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
#$emailTo = "BackupAdministrators@glfhc.org"
$subject = "GLFHC Veeam Compression and Dedupe Report for $date from $ThisServer"  
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


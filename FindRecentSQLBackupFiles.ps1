<#
FileName:	FindRecentSQLBackupFiles.ps1
Purpose:	This script will search through all of the directories on the share location
		where backup files exist and create a listing of all files that were modified in the past "X" days.
		Then, the output file will be emailed to me so that I can make sure that no native SQL backups 
		are being created.
Notes:

Date		Author			Description
--------	------		--------------------------
5/14/2021	peb		Original Version

#>
# Turn off the noise
$erroractionpreference = "SilentlyContinue"

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# define local variables
$Daysback = "-1"
$Daysforward = -$Daysback
$FilePath = "C:\Output"
$Source = "\\hav-dr01\Backup\SQLDirectBackup"
$OutFile = Join-Path -path $FilePath -childPath ("NewSQLBackupsCreated_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")
$ThisServer = get-content env:computername
$timeStamp = (Get-Date).ToString('MM-dd-yyyy')

# Step 1: Count how many new files were created during that time period

$FileCount = (Get-ChildItem -Path $Source -Recurse| ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}).Count

# Step 1: Create a listing of all new *.sql files created in past week on my Workstation

Get-ChildItem -Path $Source -Recurse| ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| Out-file $OutFile 

# Step 2: Format and send email message

$Attachment= $OutFile
$EmailTo = "pburkhardt@glfhc.org" 
$EmailFrom   = "pburkhardt@glfhc.org"  
$Subject = "There were $FileCount files created in past $Daysforward days in the $Source directory..."
$Body =  "The backup files generated on this server today are found in the attached document..."
$SMTPServer  = "mail.glfhc.org"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)






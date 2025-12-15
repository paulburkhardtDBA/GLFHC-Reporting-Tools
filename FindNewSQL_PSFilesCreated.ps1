<#
FileName:	FindNewSQL_PSFilesCreated.ps1
Purpose:	This script will search through all of the directories on the C drive
		and create a listing of all files that were modified in the past week.
		Then, the output file will be emailed to me so that I can upload any
		new files to the appropriate GitHub Repository.
Notes:

Date		Author			Description
--------	------		--------------------------
5/14/2021	peb		Original Version

#>
# Turn off the noise
$erroractionpreference = "SilentlyContinue"


# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

# define local variables
$Daysback = "-7"
$Daysforward = -$Daysback
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("NewSQL_PSScriptsCreated_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")
$ThisServer = get-content env:computername
$timeStamp = (Get-Date).ToString('MM-dd-yyyy')

# Step 1: Create a listing of all new *.sql files created in past week on my Workstation

Get-ChildItem -Path "C:\" -Recurse| ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| where {$_.extension -in ".sql",".ps1"} | Out-file $OutFile 

# Step 2: Format and send email message

$Attachment= $OutFile
$EmailTo = "wyang@glfhc.org" 
$EmailFrom   = "wyang@glfhc.org"  
$Subject = "New SQL and PS files created in past $Daysforward on $ThisServer..." 
$Body = "The backup files generated on this server today are found in the attached document..."
#$SMTPServer  = "mail.glfhc.org"  
$SMTPServer  = "smtpmail.glfhc.local"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)






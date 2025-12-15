<#
FileName:	StageNewPSFilesCreated.ps1
Purpose:	This script will search through code directory, create a listing of all files that were modified in the past week,
			copies the newly-created files to the appropriate local repo, and finally sends and email with a listing of these files.

			These is a subsequent scheulded task that uploads these files from the local reop to the remote GitHub repository.
			
			It is currently set up to run weekly and searchs for PS files creaeted in the past 7 days.
Notes:

Date		Author			Description
--------	------		--------------------------
5/04/2021	peb		P:\Documents\ApplicationsOriginal Version
5/09/2022	peb		Change search days to only past day 
5/13/2022	peb		modified to search for only *.ps1 sctipts

#>
# Turn off the noise
#$erroractionpreference = "SilentlyContinue"


# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# define local variables
# Change to -1 for firsr run (then change to -7).
$Daysback = "-1"
$Daysforward = -$Daysback
$SourcePath = "C:\Code"
$FilePath = "C:\Output"
$iFile = 0
$GitPath = "D:\GitHub\DBA-Powershell"
$OutFile = Join-Path -path $FilePath -childPath ("NewPSScriptsCreated_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")
$ThisServer = get-content env:computername
$timeStamp = (Get-Date).ToString('MM-dd-yyyy')

# Step 1: Create a listing of all new *.sql files created in past week on my Workstation

$Files = (Get-ChildItem -Path $SourcePath | ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| where {$_.extension -in ".ps1"}) 

# Step 2: Copy the new files to the appropriate Local Repo

foreach ($File in $Files)
{
	Copy-Item $File.FullName -Destination $GitPath -Recurse
	$iFile = $iFile + 1
}

# Step 3: Creating another listing but output the results this time...

$Files = Get-ChildItem -Path $SourcePath | ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| where {$_.extension -in ".ps1"} | Out-file $OutFile 

# Step 4: Format and send email message

# 10/21/2022 peb Only send emails if a file exists

if ($iFile -ne 0)
{
$Attachment= $OutFile
$EmailTo = "pburkhardt@glfhc.org" 
$EmailFrom   = "pburkhardt@glfhc.org"  
$subject = "Staging New PS files. No New files for the past $Daysforward day(s) on $ThisServer..." 
$Body = "Staging New PS files - No action is needed ..."
$subject = "Staging New PS files. There were $iFile file(s) created in past $Daysforward days(s) on $ThisServer..." 
$Body = "The backup files generated on this server today are found in the attached document..."
$smtpServer = "mail.glfhc.org"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)
}
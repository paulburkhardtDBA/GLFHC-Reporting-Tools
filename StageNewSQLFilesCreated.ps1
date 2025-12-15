<#
FileName:	StageNewSQLFilesCreated.ps1
Purpose:	This script will search through code directory, create a listing of all files that were modified in the past time period,
			copies the newly-created files to the appropriate local repo, and finally sends and email with a listing of these files.

			These is a subsequent scheulded task that uploads these files from the local reop to the remote GitHub repository.
			
			It is currently set up to run weekly and searchs for PS files creaeted in the past 7 days.
Notes:

Date		Author			Description
--------	------		--------------------------
5/13/2021	peb		Original Version


#>
# Turn off the noise
#$erroractionpreference = "SilentlyContinue"


# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# define local variables
# Change to -1 for firsr run (then change to -1).
$Daysback = "-1"
$Daysforward = -$Daysback
$iCount = 0
$SourcePath = "C:\Code"
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("NewSQLScriptsCreated_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")
$ThisServer = get-content env:computername
$timeStamp = (Get-Date).ToString('MM-dd-yyyy')

# Step 1: Create a listing of all new *.sql files created during the time frame and count the total

$Files = (Get-ChildItem -Path $SourcePath -Recurse | ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| where {$_.extension -in ".sql"}) 
$iCount = (Get-ChildItem -Path $SourcePath -Recurse | ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| where {$_.extension -in ".sql"}).Count

<## Step 2: Copy the new files to the appropriate Local Repo
### Hold off on direct copying for now  ###
### Review email and then decide which files to copy

foreach ($File in $Files)
{
	Copy-Item $File.FullName -Destination $GitPath -Recurse
	$iCount = $iCount + 1
}
#>

# Step 3: Creating another listing but output the results this time...

$Files = Get-ChildItem -Path $SourcePath -Recurse| ? {$_.LastWriteTime -gt (Get-Date).AddDays($Daysback)}| where {$_.extension -in ".sql"} | Out-file $OutFile 

# Step 4: Format and send email message
# Only send email if any files exits

if ($iCount -ne 0)
{

	$Attachment= $OutFile
	$emailFrom = "pburkhardt@glfhc.org"  
	$emailTo = "pburkhardt@glfhc.org"
	$subject = "Staging New SQL Files. There were $iCount file(s) created in past $Daysforward days(s) on $ThisServer..." 
	$Body = "Review these files.  Decide on which ones should be stored and then copy them over to the local repo."
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
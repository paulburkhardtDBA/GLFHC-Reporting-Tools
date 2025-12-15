<#
FileName:	LIVEEMRMoveAuditFIles.ps1
Purpose:	This script will
				- Search the Source Directory for all flles
				- Refine the selection to only process .xel files
				- Remove everything right the last hyphen "-" (typically "- yyyyMMdd)
				- Copy the files over to a new directory sung the new name.
				- Rename the old files in the source directory with a ".done" extension.
				

    Date 	Author					Description
===========	======	============================================================
5/23/2024	peb				Original Version

#>

# Turn off the noise
#$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername
$timeStamp = (Get-Date).ToString('MM-dd-yyyy')

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

#----- get current date ----#
$date = get-date -format "yyyyMMddHHmm"
$Now = Get-Date
#----- define amount of days ----#
$Days = "7"
#----- define LastWriteTime parameter based on $Days ---#
$LastWrite = $Now.AddDays(-$Days)

#----- define extension ----#
$Extension = "*.xel"
$iCount = 0

#----- define folder where files are located ----#
$FilePath = "C:\Output"
$SourceFolder = "\\live-emr-db\s$\Audit"
$TargetFolder = "\\gb4-50246\d$\Audit\LIVE-EMR-DB"
$OutFile = Join-Path -path $FilePath  -childPath ("LIVEEMRAuditFiles_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")

#------get list of files to be deleted
Get-Childitem $SourceFolder -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"} > $outfile

# Search all files that reside in the source directory

$files = Get-ChildItem -Path $SourceFolder -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"} 
foreach ($f in $files)
{
	# Make sure that the files only contain one hyphen
	

	# Only process files that have a xel extention
 	$extn = [IO.Path]::GetExtension($f)
    	if ($extn -eq ".xel" )
	{	
		# Check filename and only process xel (Audit) files
		# For Debugging

			$BaseFileName = $f
			# Define Source file Name
			$SourceFile = $SourceFolder + "\" + $BaseFileName
			# Define Target File Name
			$Targetfile = $TargetFolder + "\" +$BaseFileName

			# Now, copy file from source to target drectory
			# Write-Host "Source file name is $SourceFile
			# Write-Host "Target file name is $Targetfile 
			Copy-Item -path $SourceFile $TargetFile
		
			# Finsally, delete source file
			#Remove-Item $SourceFile | out-null
			
			# Increment Counter
			$icount++
			
	}

}

# Only send email if files exist
if ($iCount -eq 0)
{
	$msgSubject = "!!! ALERT - NO LIVE EMR Audit files were found on $timeStamp from $ThisServer!!!" 
	$msgBody = "No action is required..."
}
else
{
	$msgSubject = "LIVE EMR Auidit files Moved $iCount files to Staging Area on $timeStamp from $ThisServer..." 
	$msgBody = "New Files were moved to an Archive Directory... No action is needed ..."
}
$Attachment= $OutFile
$EmailTo = "pburkhardt@glfhc.org" 
$EmailFrom   = "pburkhardt@glfhc.org"  
$subject = $msgSubject
$Body = $msgBody
$smtpServer = "mail.glfhc.org"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo,$msgSubject,$msgBody) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)



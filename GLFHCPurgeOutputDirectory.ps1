<#
FileName:	PurgeOutputDirectory.ps1
Purpose:	This script was written to periodically delete the old files
		created by various powershell jobs from the destination directory.

Date	Author			Description
3/6/15	peb		original version
8/25/20 peb		modify for glfhc
1/27/25 wy      change user/pw/dbmail to wyang
#>

#----- define parameters -----#
#----- get current date ----#
$Now = Get-Date

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

#----- define amount of days ----#
$Days = "7"

#----- define extension ----#
$Extension = "*.*"

#----- define folder where files are located ----#
$TargetFolder = "C:\Output"

#------define log file here
$date = get-date -format "yyyyMMddHHmm"
$outfile = "c:\output\PurgeOutPutDir_$date.txt" 

#----- define LastWriteTime parameter based on $Days ---#
$LastWrite = $Now.AddDays(-$Days)

#------get list of files to be deleted
Get-Childitem $TargetFolder -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"} > $outfile
 
#----- get files based on lastwrite filter and specified folder ---#
$Files = Get-Childitem $TargetFolder -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"} 
 
foreach ($File in $Files) 
{
    TRY
    {
    if ($File -ne $NULL)

        {

<#         write-host "Deleting File $File" -ForegroundColor "DarkRed" #>

        Remove-Item $File.FullName | out-null

        }

    else

        {

        <# Write-Host "No more files to delete!" -foregroundcolor "Green" #>

        }
    }
   CATCH
    {
    continue 
    }

}

# email results

start-sleep -s 5

# Format and send email message

$Attachment= $OutFile
$EmailTo = "wyang@glfhc.org" 
$EmailFrom   = "wyang@glfhc.org" 
#$EmailFrom   = "pburkhardt@glfhc.org"  
$Subject = "PurgeOutputDirectory Report for $date"  
$Body =  "A listing of the files to be deleted is attached..."  
$SMTPServer  = "smtpmail.glfhc.local"  
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)



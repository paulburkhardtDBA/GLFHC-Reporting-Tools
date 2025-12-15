<#
FileName: VeeamDailyBackupRpt.ps1
Purpose:  To generate a listing of the Veeam Backup jobs run in the past 24 hourts.
#>

# Define Output FileName

$date = get-date -format "yyyyMMddHHmm" 
$FilePath = "F:\Veeam"
$OutFile = Join-Path -path $FilePath -childPath ("VeeamSummaryReport_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".csv") 
#let's set up the email stuff
$emailFrom = "GLFHCSQLAlert@glfhc.org"  
$emailTo = "pburkhardt@glfhc.org"
# Uncomment when ready 
# $emailTo = "BackupAdministrators@glfhc.org"
# take case of subject and body later in code...
$smtpServer = "mail.glfhc.org"

# First Loop
TRY
{
	# Create New Report and output results to a file defined above
	$results = Get-VBRJob | ?{$_.JobType -eq "Backup"}| select name,IsScheduleEnabled,SqlEnabled | export-csv $OutFile

	# Now collect totals to post in body of report
	$AllJobs = (Get-VBRJob | ?{$_.JobType -eq "Backup"}).count
	$DisabledJobs = (Get-VBRJob | where {$_.info.IsScheduleEnabled -eq $False }).count 

	$delta = $AllJobs - $DisabledJobs

}
CATCH
{
	continue
}

# Compose subject line based on number of scheduled jobs
if ($DisabledJobs -eq 0)
{
	$subject = "GLFHC Veeam Backup Jobs  Summary for $date"
}
else

{
	$subject = "!!! Alert GLFHC Veeam Backup Jobs Summary for $date - Unscheulded jobs !!!"
}

	$body = " The total number of jobs is $Alljobs and the number Scheduled is $DisabledJobs Unscheduled jobs..."

Function sendEmail([string]$emailFrom, [string]$emailTo, [string]$subject,[string]$body,[string]$smtpServer,[string]$OutFile)
{
#initate message
$email = New-Object System.Net.Mail.MailMessage 
$email.From = $emailFrom
$email.To.Add($emailTo)
$email.Subject = $subject
$email.Body = $body
# initiate email attachment 
$emailAttach = New-Object System.Net.Mail.Attachment $OutFile
$email.Attachments.Add($emailAttach)
#initiate sending email 
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($email)
}

#Send out the results before existing
sendEmail $emailFrom $emailTo $subject $body $smtpServer $OutFile $OutFileNew

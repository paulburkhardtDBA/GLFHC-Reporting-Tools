<#
FileName: VeeamDailyBackupRpt.ps1
Purpose:  To generate a listing of the Veeam Backup jobs run in the past 24 hourts.
#>

# Define Output FileName

$date = get-date -format "yyyyMMddHHmm" 
$FilePath = "F:\Veeam"
$OutFile = Join-Path -path $FilePath -childPath ("JobsReports_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt") 
$OutFileNew = Join-Path -path $FilePath -childPath ("NewJobsReports_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt") 
#let's set up the email stuff
$emailFrom = "GLFHCSQLAlert@glfhc.org"  
$emailTo = "BackupAdministrators@glfhc.org"
$subject = "GLFHC Daily Veeam Backup Jobs for $date"
$body = "Please review the attached list to of Veeam Backup jobs..."
$smtpServer = "mail.glfhc.org"

$Daysback = "-7"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)


# First Loop
TRY
{
	# Create New Report
	Get-VBRBackupSession | ?{$_.CreationTime -ge (Get-Date).Addhours(-24)} | Select JobName, JobType, CreationTime, Result, @{Name="BackupSize";Expression={$_.BackupStats.BackupSize}} |  Sort EndTimeUTC -Descending | Select -First 1| Format-Table | Out-File -FilePath $OutFile 

}
CATCH
{
	continue
}

# Second Loop
<#
This new report is created by basically going through the backup sessions and brings the CreationTime and EndTime to the root level with the name of StartTime and StopTime respectively(default sort is StartTime -Descending), 
which allows us to sort the results by either property.
As a result, the report picks up the most recent result.
#>
TRY
{
	Get-vPCBackupSession -JobName "Job Name" -Limit 10
	Get-VBRJob | ?{$_.Name -eq "Job Name"} | Get-vPCBackupSession -Limit 10
	Get-VBRJob | %{Get-vPCBackupSession $_.Name -Limit 1} | Out-File -FilePath $OutFileNew

	#Before leaving Purge Old Reports
	Get-ChildItem $FilePath | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
}
CATCH
{
	continue
}
Function sendEmail([string]$emailFrom, [string]$emailTo, [string]$subject,[string]$body,[string]$smtpServer,[string]$OutFile,[string]$OutFileNew)
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
$emailAttach2 = New-Object System.Net.Mail.Attachment $OutFileNew
$email.Attachments.Add($emailAttach2)  
#initiate sending email 
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($email)
}

#Send out the results before existing
sendEmail $emailFrom $emailTo $subject $body $smtpServer $OutFile $OutFileNew

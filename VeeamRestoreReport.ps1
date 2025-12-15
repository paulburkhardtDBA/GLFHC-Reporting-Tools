$ThisServer = get-content env:computername 
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$Subj = "GLFHC Veeam Restore Report for past 7 days on $NewReportDate on $ThisServer."

# Connect to the Veeam Server by asking for Credentials ( username & password)
#### For testing, use your account creds
#connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xpburkhardt' -password '!$VeE@m2021!'
connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xwyang' -password 'EXpcW8ue*g$tkmS@Ro9P'

#disconnect-vbrserver -server "hav-veeam" -user 'hav-veeam\xwyang' -password 'EXpcW8ue*g$tkmS@Ro9P'
#Connect-VBRServer -server "hav-veeam"  -Credential (Get-Credential)

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$usernames = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring 

$date = (get-date -format MM/dd/yy)
$restoreJobs = Get-VBRRestoreSession | where {((Get-Date) - ($_.CreationTime)).totaldays -le "7"} |Sort-Object Creationtime | Select JobName, CreationTime, EndTime, JobType, JobTypeString, Options, Description, Result
$restoreJobData= @()
foreach ($restoreJob in $restoreJobs) {
    $separator = " ";
    $separator1 = '`"+" "';
    $option = [System.StringSplitOptions]::RemoveEmptyEntries;
    $jobOptions = $restoreJob.Options | out-string;
    $username = $jobOptions.Split($separator,$option)|Select-String "InitiatorName="|out-string;
    $username = $username.Substring($username.indexof('"')+1);
    $username = $username -replace '"';
    $reason = $jobOptions -Split '" '|Select-String "Reason="|out-string;
    $reason = $reason.Substring($reason.indexof('"')+1);
    $restoreJob.Options=$username;
    $restoreJob.Description=$reason; 
    $restoreJobDataObject = $restoreJob;
    $restoreJobData += $restoreJobDataObject;
}
if ($restoreJobData.count -eq 0) {
    exit
}

$head=@"
<style>
@charset "UTF-8";

#content {
width:75%;
border:0px solid #005a99;
padding-left:50px;
}
 
h2 {
color:#0888d8;
}

table {
    border-collapse: collapse;
    width: 100%;
}

th, td {
    text-align: left;
    padding: 8px;
}

tr:nth-child(odd){background-color: #f2f2f2}

th {
    background-color: #4997C7;
    color: white;
}

</style>
"@

$htmlbody = $restoreJobData|Sort-Object Creationtime | Select @{Name="Resource Name";Expression={$_.JobName}},@{Name="Start Time";Expression={$_.CreationTime}},@{Name="End Time";Expression={$_.EndTime}},@{Name="Job Type";Expression={$_.JobTypeString}},@{Name="Job Type Detail";Expression={$_.JobType}},@{Name="Restore Status";Expression={$_.Result}},@{Name="Restore Reason";Expression={$_.Description}},@{Name="Run By";Expression={$_.Options}} | ConvertTo-HTML -Head $head -PreContent "<div id=""content"" class=""transparent""><H2>Veeam Backup Report - Restore Jobs In Last 7 days - $($date)</H2>" -PostContent "</div>"| out-string

#use as sample output file
$htmlcurrent_time = (get-date -format yyyyMMdd\_HHmm)
$htmldate = (get-date -format yyyyMMdd)
$html_file = "C:\Output\veeam_report_restore_jobs_last_7_days_$($htmlcurrent_time).htm"
#Write-host "$html_file"
$htmlbody | Out-File -FilePath $html_file


# Disconnect from server
Disconnect-VBRServer | Out-Null

# Email Results

start-sleep -s 5

# Send Email
	
$Attachment=$html_file
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "GLFHC Veeam Restore Report for past 7 days on $NewReportDate on $ThisServer."
$Body = "Please review the attached report..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($usernames, $password) 
$SMTPClient.Send($SMTPMessage)


<#
	
$logcurrent_time = (get-date -format yyyyMMdd\_HHmm)
$logdate = (get-date -format yyyyMMdd)
$log_file = "C:\Output\veeam_report_restore_jobs_last_7_days_$($logdate).log"
Add-Content "--- Veeam Backup Report - Restore Jobs Run In Last 7 Days $($logcurrent_time) ----" -path $log_file -encoding unicode
$restoreJobData|Sort-Object Creationtime | Select JobName, CreationTime, EndTime, JobType, JobTypeString, Options, Description, Result| Out-File -FilePath $log_file -Append
#>

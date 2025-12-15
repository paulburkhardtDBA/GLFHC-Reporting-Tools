<# 
FileName:	GLFHCAuditSQLGrants.ps1
Purpose:	This scrit will write the SQL Server name, version, edition, Service Pack level, CU level, version number to 
			an output file for a list of SQL Servers specified in a file to a .csv file.
			In turn, this list can be reviewed to see which SQL Server instances need the latest Service Pack.

6/1/2022 	Restrcited search to events occurring today AND ignore share-DB1 (service account) changes
#>
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername 
$date = get-date -format "yyyyMMddHHmm"
$ReportDate = get-date
$NewReportDate = $ReportDate.GetDateTimeFormats()[12]
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCAuditSQLGrants" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query
$sql = "SELECT   @@SERVERNAME,
		TE.name AS [EventName] ,
        v.subclass_name ,
        T.DatabaseName ,
        t.StartTime ,
        t.RoleName ,
        t.TargetLoginName ,
        t.SessionLoginName
FROM    sys.fn_trace_gettable(CONVERT(VARCHAR(150), ( SELECT TOP 1
                                                              f.[value]
                                                      FROM    sys.fn_trace_getinfo(NULL) f
                                                      WHERE   f.property = 2
                                                    )), DEFAULT) T
        JOIN sys.trace_events TE ON T.EventClass = TE.trace_event_id
        JOIN sys.trace_subclass_values v ON v.trace_event_id = TE.trace_event_id
                                            AND v.subclass_value = t.EventSubClass
WHERE	te.name like 'Audit%' AND (te.name <> 'Audit Backup/Restore Event' AND te.name <> 'Audit Login Failed')
AND t.StartTime > getdate()-1
AND t.SessionLoginName <> 'GLFHC\sharepointsvc'"
# gather info from each server in file and export to .csv
Foreach ($ss in $sqlservers) 
{
   Invoke-Sqlcmd -ServerInstance $ss -Query $sql | Export-Csv $outfile -NoTypeInformation -Append
}
start-sleep -s 15  


# Send Email
$Attachment= $OutFile
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$Subject = "SQL Audit Report at GLFHC for $NewReportDate on $ThisServer."
$Body = "Review the accces that has been grtend various accounts and take corrective action.."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

			
<# 
FileName:	GLFHCSQLProductInventory.ps1
Purpose:	This scrit will write the basic SQL Server product informatin (e.g., name, instance, Product Version, Service Pack, edition, Product Uodate Number (KB) 
			to an output file for a list of SQL Servers specified in a file to a .csv file.
			In turn, this list can be reviewed to see which SQL Server instances need the latest Service Pack.
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
$OutFile = Join-Path -path $FilePath -childPath ("GLFHCSQLProductInventory_" + $isodate + ".csv")
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 

$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query
$sql = "SELECT	SERVERPROPERTY('MachineName') AS [MachineName],								
		SUBSTRING(@@VERSION, 1, CHARINDEX('(', @@VERSION) - 1) AS [SQL Version],
		SERVERPROPERTY('InstanceName') AS [Instance], 
		SERVERPROPERTY('ProductVersion') AS [ProductVersion],
		SERVERPROPERTY('Productlevel') as 'Service Pack',
		SERVERPROPERTY('Edition') AS [Edition],
		SERVERPROPERTY('ProductUpdateReference') AS [ProductUpdateReference]"
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
$Subject = "GLFHC SQL Product Report for $NewReportDate on $ThisServer."
$Body = "Please review this list, update the SQL Server Patching Sheet, and schedle updates, if needed ..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

			
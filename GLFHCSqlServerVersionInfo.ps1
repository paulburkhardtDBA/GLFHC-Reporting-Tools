<# 
FileName:	GLFHCSQLServerVersionInfo.ps1
Purpose:	This scrit will write the SQL Server name, version, edition, Service Pack level, CU level, version number to 
			an output file for a list of SQL Servers specified in a file to a .csv file.
			In turn, this list can be reviewed to see which SQL Server instances need the latest Service Pack.
#>

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

# Declare Local Variables 
$date = get-date -format "yyyyMMddHHmm"  
$outfile = 'c:\Output\SQLServerVersionInfo_$date.csv'           # output file name
$servers = 'c:\Code\JustServerNameList.txt'                       # list of your SQL Servers
 
$EmailOn = 'y'                                   # y to email logs (case insensitive)
 
 


$sqlservers = Get-Content $servers | Sort-Object # read in and sort to order output 
 
# sql query
$sql = "SELECT	
		SUBSTRING(@@VERSION, 1, CHARINDEX('(', @@VERSION) - 1) AS [SQL Version],
		SERVERPROPERTY('InstanceName') AS [Instance], 
		SERVERPROPERTY('ProductVersion') AS [ProductVersion],
		SERVERPROPERTY('Productlevel') as 'Service Pack',               
		SERVERPROPERTY('Edition') AS [Edition]"

 
# gather info from each server in file and export to .csv
Foreach ($ss in $sqlservers) 
{
   Invoke-Sqlcmd -ServerInstance $ss -Query $sql | Export-Csv $outfile -NoTypeInformation -Append
}
start-sleep -s 15  

# Email Results

$Attachment= $OutFile
$EmailTo = "wyang@glfhc.org" 
$EmailFrom   = "wyang@glfhc.org"  
$Subject = 'GLFHC SQL Server Version Inventory for $date' 
$Body = "The log file is attached..."  
$SMTPServer  = "smtpmail.glfhc.local"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)

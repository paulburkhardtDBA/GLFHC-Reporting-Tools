#FileName: 	GLFHCDBLastAccessedOFFLINE.ps1
# Purpose:	This script will run through a list of server and 
#			identify the databsses that are offline.
#
#
# ref: https://sqlserverpowershell.com/2014/04/04/find-database-last-access-date-via-powershell/
# Tested 5/4/2022 Took DB offline (CPS-ESM Server) and it reported it!

$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring


# Define Output FileName

$date = get-date -format "yyyyMMddHHmm"  
$save = "c:\output\DBAccessedOffline_$date.csv" 


[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum")
[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

$servers = Get-Content "C:\Code\JustServerNameList.txt"
$DBCount = 0
$outputs = @();

$lastAccessSQL = "
SELECT
'DB_NAME' = db.name,
'DB_STATUS' = DB.state_desc
FROM
sys.databases db
WHERE DB.state_desc = 'OFFLINE'
"
$servers | %{
	$srvName = $_
	$srvConn = New-Object "Microsoft.SqlServer.Management.Common.ServerConnection"
	$srvConn.ServerInstance = $srvName

	$dr = $srvConn.ExecuteReader($lastAccessSQL)

	while($dr.Read()){
		$output = New-Object -TypeName PSObject -Property @{
		    ServerName = $srvName
		    DatabaseName = $dr.GetString(0)
            DatabaseState = $dr.GetString(1)
		}
		$outputs += $output
		$DBCount++
		
	}
	
}
#$outputs | SELECT ServerName, DatabaseName, DatabaseState| Out-GridView
$outputs | SELECT ServerName, DatabaseName, DatabaseState | Export-csv $save

## Send Mail 
# Updated 5/4/2022
$Attachment= $save
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "There were $DBCount GLFHC Database Off-Line for $date from $ThisServer" 
$Body = "Inspect the attached log file..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer,25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

<## mail results
$mail = New-Object System.Net.Mail.MailMessage  
$att = new-object Net.Mail.Attachment($save)  
$mail.From = "MSSQL@glfhc.org"  
# comment out for testing 
$mail.To.Add("pburkhardt@glfhc.org")
$mail.Subject = "There were $DBCount GLFHC Database Off-Line for $date from $ThisServer"  
$mail.Body = "The log file is attached"  
$mail.Attachments.Add($att)  
$smtp = New-Object System.Net.Mail.SmtpClient("mail.glfhc.org")  
$smtp.Send($mail)  
$att.Dispose()  
#>


<#
File 		ReadErrorLogs.ps1
Purpose   	This script loops through the CMS registered servers and inspected the SQL Server error log entries.  
			Errors messages are extracted, posted to a file, and mailed to support.			
Example
   ./ReadErrorLogs.ps1

1/27/25 wy change user/pw/dbmail to wyang
#>

#$erroractionpreference = "SilentlyContinue"

# Get Credentials
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection

# define date parameters
$today    = (get-date).toString()
$all      = @()
$lookback = ((get-date).adddays(-1)).ToString()  #  look back n days from current time
$ThisServer = get-content env:computername

# load the file containing the CMS registered servers
$computers = get-content "C:\Code\JustServerNameList.txt"

# Define the output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("CMSSQLErrorLogReport_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")

#format Header of Report
$Line = "Production Databases Error Logs for $today"
$Line | out-file $OutFile

# loop through list
foreach ($computer in $computers) 
{
TRY
{
	$Line = "`r`n-------------------"
	$Line | out-file $OutFile -append
	$Line = "Working on " + $computer
	#write-host $Line 
	$Server = new-object ("Microsoft.SqlServer.Management.Smo.Server") "$computer" 
	$Line = "Server :" + $computer + " (Version: " + $Server.Information.VersionString + ")`r`n-------------------"
	$Line | out-file $OutFile -append
	$Line = "[Log Errors]"
	$Line | out-file $OutFile -append
	$Server.ReadErrorLog()|where {(($_.Text -like "*Error:*" -or $_.Text -like "*fail*") -and ($_.LogDate -ge $lookback))}| Format-Table -auto | Out-String -Width 4096| Out-File $OutFile -append 
}
CATCH
{
CONTINUE
}
}

# Send Email
$Attachment = $OutFile
#$emailFrom = "pburkhardt@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "GLFHC SQL Server Error Log Report for $today from $ThisServer"
$body = "Review the attached file for errors on misson critical servers. Please research any problems found..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


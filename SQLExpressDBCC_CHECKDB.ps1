<# DBCC_CHECKDB.ps1
# Purpose:	There are instances of SQLExpress out there.  It's not possible to run data integrity 
#			checks in this case using native SQL.  So, the next best thing is to write a 
#			PS script that can be automated through a Windows Scheduled Task.
# ref: http://sqlmag.com/powershell/run-sql-server-dbccs-check-errorlog-with-powershell
# Date 			Author					Description
#---------		-------		----------------------------
# 10/21/2021 	peb			Modified for GLFHC

# define date parameters
#>
$today    = (get-date).toString()
$all      = @()
$startdt = ((get-date).adddays(-1)).ToString()  #  look back n days from current time
$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# Define the output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("SQLDBCCCheckDBReport_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")
$Daysback = "-7"
$Logfile = Join-Path -path $FilePath -childPath ("DeleteLogs_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".txt")
$header = "The Files to be deleted are listed here:"
$header | Out-file $Logfile 
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)

#let's set up the email stuff
$emailFrom = "SQLCMSAlert@glfhc.org"
$emailTo = "pburkhardt@glfhc.org"
$subject = "DBCC SQL CheckDB Report for $startdt on $ThisServer server..."
$body = "Review the attached file for any inconsistency errors  and please research any problems found..."
$smtpServer = "mail.glfhc.org"


#format Header of Report
$Line = "DBCC Data Consistency Databases Checks for $today"
$Line | out-file $OutFile


# Connect to the specified instance
$inst = "HAV-MITEL-CALLC\SQLEXPRESS"

# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $inst 
                               
# Get the databases for the instance, and iterate through them
# In Server Management Objects (SMO), the Database object has a method called CheckTables(). 
# Use this with an argument of 'None,' and this has the equivalent of running DBCC CHECKDB WITH NO_INFOMSGS for each database.

$dbs = $s.Databases
foreach ($db in $dbs) 
{
	# Check to make sure the database is accessible
    if ($db.IsAccessible -eq $True) 
	{
		# Store the database name for reporting
		$dbname = $db.Name
                                  
		# Peform the database check
		$db.CheckTables('None')
                                  
    }
}
	#$Line = "'r' n———————————–"
	#$Line | out-file $OutFile -append

# Now, if there were problems with the DBCC results, they will appear in the error log
# So, let's read the current error log

$err = $s.ReadErrorLog()

# search the error log for the past 24 hours and look for the DBCC results

$err | where {$_.LogDate -ge $startdt} | Select-String -inputobject {[string] $_.LogDate + ' ' + $_.ProcessInfo + ' ' + $_.Text} -pattern 'DBCC' -context 0,0 | Out-File $OutFile -append 

# Now, list all files in the Output directory to a text file that are older than X days 

Get-ChildItem $FilePath | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Out-file $Logfile -append

# Next, delete these files

Get-ChildItem $FilePath | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item

# Finally format and send email 

$Attachment = $OutFile
$Attachment2 = $LogFile
$emailFrom = "pburkhardt@glfhc.org"  
$emailTo = "pburkhardt@glfhc.org"
$subject = $subject
$Body = $body
$smtpServer = "mail.glfhc.org"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment2)
$SMTPMessage.Attachments.Add($Attachment2)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

Function sendEmail([string]$emailFrom, [string]$emailTo, [string]$subject,[string]$body,[string]$smtpServer,[string]$OutFile,[string]$Logfile)
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
$emailAttach2 = New-Object System.Net.Mail.Attachment $Logfile
$email.Attachments.Add($emailAttach2) 
#initiate sending email 
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($email)
}

#Send out the results before existing
sendEmail $emailFrom $emailTo $subject $body $smtpServer $OutFile $Logfile


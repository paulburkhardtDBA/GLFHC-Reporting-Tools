# FileName: CheckLastBackup.ps1
# Purpose:  To run through the GLFHC list of registered servers
#	    	and list when the last backup was run.  
#       	It should be reviewed to see if any "mission critical" databases
#	    	need to be backed up.
# Date:	8/7/20
# Ref:   http://www.mssqltips.com/sqlservertip/1784/check-the-last-sql-server-backup-date-using-windows-powershell/


$start = get-date

$today = $start.ToShortDateString()
$24HoursAgo = [DateTime]::Now.AddHours(-24)

$FilePath = "C:\Output"
$strPath = Join-Path -path $FilePath -childPath ("GLFHCLastBackupReport_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".xlsx")


#let's set up the email stuff
$emailFrom = "GLFHCSQLAlert@glfhc.org"
$emailTo = "pburkhardt@glfhc.org"
$subject = "GLFHC SQL Server Last Backup Report for $today"
$body = "Examine this list and make sure that all the databases that SHOULD be backed up are being done. If not, correct the problem.."
$smtpServer = "mail.glfhc.org"


#Create a new Excel object using COM 
$Excel = New-Object -ComObject Excel.Application
# Excel.visible = $True 
#$excel.DisplayAlerts = $false 
#$excel.ScreenUpdating = $false 
$excel.Visible = $false 
#$excel.UserControl = $false 
#$excel.Interactive = $false


$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.worksheets
$Sheet = $Excel.Worksheets.Item(1)

#Counter variable for rows
$intRow = 1

#Create Report header
     
$Sheet.Cells.Item($intRow,1) = "SQL LAST BACKUP REPORT FOR "
$Sheet.Cells.Item($intRow,1).Font.Bold = $True
$Sheet.Cells.Item($intRow,2) = $start
$Sheet.Cells.Item($intRow,2).Font.Bold = $True

$intRow = $intRow + 2

$Sheet.Cells.Item($intRow,1) = "Databases in Red require your attention..."
$Sheet.Cells.Item($intRow,1).Font.Bold = $True
$Sheet.Cells.Item($intRow,1).Font.ColorIndex = 3
$Sheet.Cells.Item($intRow,1).Interior.ColorIndex = 1

$intRow = $intRow + 1

$Sheet.Cells.Item($intRow,1) = "Databases in Yellow are Off-Line..."
$Sheet.Cells.Item($intRow,1).Font.Bold = $True
$Sheet.Cells.Item($intRow,1).Font.ColorIndex = 6
$Sheet.Cells.Item($intRow,1).Interior.ColorIndex = 1

# increment counter

$intRow = $intRow + 2

#Read thru the contents of the SQL_Servers.txt file
foreach ($instance in get-content "C:\Code\JustServerNameList.txt")
{
# Add logic to exclude servers with the name TEST or DEV in them.
	if (($instance.ToLower().Contains("TEST".ToLower()) -eq $False) -and ($instance.ToLower().Contains("DEV".ToLower()) -eq $False) -and ($instance.ToLower().Contains("QA".ToLower()) -eq $False) -and ($instance.ToLower().Contains("TRAIN".ToLower()) -eq $False))
	{
     #Create column headers
     $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
     $Sheet.Cells.Item($intRow,2) = $instance
     $Sheet.Cells.Item($intRow,1).Font.Bold = $True
     $Sheet.Cells.Item($intRow,2).Font.Bold = $True

     $intRow++

      $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
      $Sheet.Cells.Item($intRow,2) = "LAST FULL BACKUP"
      $Sheet.Cells.Item($intRow,3) = "FULL BACKUP AGE(DAYS)"
 
     #Format the column headers
     for ($col = 1; $col –le 5; $col++)
     {
          $Sheet.Cells.Item($intRow,$col).Font.Bold = $True
          $Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
          $Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
     }


     $intRow++
      #######################################################
     #This script gets SQL Server database information using PowerShell


     [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

     # Create an SMO connection to the instance
     $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance

     $dbs = $s.Databases

	# set counter
	
	$db_freq=0

     #Formatting using Excel 

		ForEach ($db in $dbs)  
		{ 
		   if ($db.Name -ne "tempdb") #We do not need the backup information for the tempdb database 
		   { 
			   $NumDaysSinceLastFullBackup = ((Get-Date) - $db.LastBackupDate).Days #We use Date Math to extract the number of days since the last full backup 
				
			   if($db.LastBackupDate -eq "1/1/0001 12:00 AM") #This is the default dateTime value for databases that have not had any backups 
			   { 
				   $fullBackupDate="Never been backed up" 
			   } 
			   else 
			   { 
				   $fullBackupDate="{0:g}" -f  $db.LastBackupDate 
			   } 
			   
			   #Define your service-level agreement in terms of days here 
			   if ($NumDaysSinceLastFullBackup -gt 2) 
			   { 
			   
			   	#make sure that the database is accessible
				if ( $db.IsAccessible ) 
				{
					$fgColor = 3 
				}
				ELSE
				{
					$fgColor = 6
					$NumDaysSinceLastFullBackup = "Database Off-Line"
				}	
					$Sheet.Cells.Item($intRow, 1) = $db.Name 
					$Sheet.Cells.item($intRow, 1).Interior.ColorIndex = $fgColor 
					$Sheet.Cells.Item($intRow, 2) = $fullBackupDate   
					$Sheet.Cells.item($intRow, 2).Interior.ColorIndex = $fgColor 
					$Sheet.Cells.item($intRow, 2).HorizontalAlignment = -4131
					$Sheet.Cells.Item($intRow, 3) = $NumDaysSinceLastFullBackup 
					$Sheet.Cells.item($intRow, 3).Interior.ColorIndex = $fgColor 
				

					# increment counter
					
					$db_freq ++
					$intRow ++ 

				} 

			} 
				
		 } 

	# If no issues found, note that
		
	if ($db_freq -eq 0)
	{
		$Sheet.Cells.Item($intRow, 1) = "No problems found..."
		$intRow ++ 
	}


	}
}

$Sheet.UsedRange.EntireColumn.AutoFit()


$Excel.SaveAs($strPath) 

$Sheet = $null
$Excel.Close()
$Excel.Qui()
$Excel = $null
[GC]::Collect() 
cls

Function sendEmail([string]$emailFrom, [string]$emailTo, [string]$subject,[string]$body,[string]$smtpServer,[string]$strPath)
{
#initate message
$email = New-Object System.Net.Mail.MailMessage 
$email.From = $emailFrom
$email.To.Add($emailTo)
$email.Subject = $subject
$email.Body = $body
# initiate email attachment 
$emailAttach = New-Object System.Net.Mail.Attachment $strPath
$email.Attachments.Add($emailAttach) 
#initiate sending email 
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($email)
}

#Send out the results before existing
sendEmail $emailFrom $emailTo $subject $body $smtpServer $strPath

$end = get-date
write-host "End: "  $end
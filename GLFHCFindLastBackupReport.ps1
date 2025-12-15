<#
FileName: 	GLFHCFindLastBackupReport.ps1
Purpose:	This job will list the backups for all databases on the instances being inventoried 
			on the JustServerNameList.txt file.  It will highlight backups that are later than one day in red\
			(production backups issues) and ones that are greater than a week (test backup issues) in pink.
			Databasees that are offline are highighted in yellow.
7/16/2021 - Added Legend to Report
1/27/25 WY Change user/pw/dbmail to wyang
#>
$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

# Define Output FileName
$date = get-date -format "yyyyMMddHHmm"  
$save = "c:\output\SQLBackupReport_$date.xlsx" 
#Create a new Excel object using COM
$a = New-Object -ComObject Excel.Application
$a.visible = $True
$b = $a.Workbooks.Add()
$Sheet = $b.Worksheets.Item(1)

#Counter variable for rows
$intRow = 1

# Define Legend
$Sheet.Cells.Item($intRow, 1) = "LEGEND:"  
$Sheet.Cells.Item($intRow, 1).Font.Bold = $True
$intRow = $intRow + 1 
$Sheet.Cells.Item($intRow, 1) = "Databases Off-Line (No Backup Needed)..."  
$Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 6
$intRow = $intRow + 1 
$Sheet.Cells.Item($intRow, 1) = "Databases no backed up in 1-7 days..."  
$Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 7 
$intRow = $intRow + 1 
$Sheet.Cells.Item($intRow, 1) = "Databases were NEVER backed up!!!  Check it out."  
$Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 3 
$intRow = $intRow + 1 
#Read thru the contents of the SQL_Servers.txt file
foreach ($instance in get-content "C:\Code\JustServerNameList.txt")
{

     #Create column headers
     $Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
     $Sheet.Cells.Item($intRow,2) = $instance
     $Sheet.Cells.Item($intRow,1).Font.Bold = $True
     $Sheet.Cells.Item($intRow,2).Font.Bold = $True

     $intRow++

      $Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
      $Sheet.Cells.Item($intRow,2) = "LAST FULL BACKUP"
      $Sheet.Cells.Item($intRow,3) = "LAST LOG BACKUP"
      $Sheet.Cells.Item($intRow,4) = "FULL BACKUP AGE(DAYS)"
      $Sheet.Cells.Item($intRow,5) = "LOG BACKUP AGE(HOURS)"

     #Format the column headers
     for ($col = 1; $col -le 5; $col++)
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

     #Formatting using Excel


ForEach ($db in $dbs) 
{
   if ($db.Name -ne "tempdb") #We do not need the backup information for the tempdb database
   {
       $NumDaysSinceLastFullBackup = ((Get-Date) - $db.LastBackupDate).Days #We use Date Math to extract the number of days since the last full backup
       $NumDaysSinceLastLogBackup = ((Get-Date) - $db.LastLogBackupDate).TotalHours #Here we use TotalHours to extract the total number of hours
       
       if($db.LastBackupDate -eq "1/1/0001 12:00 AM") #This is the default dateTime value for databases that have not had any backups
       {
           $fullBackupDate="Never been backed up"
           $fgColor3="red"
       }
       else
       {
           $fullBackupDate="{0:g}" -f  $db.LastBackupDate
       }
		#make sure that the database is accessible
		if ( $db.IsAccessible ) 
		{
			$fgColor = 2
		}
		ELSE
		{
			$fgColor = 6
			$NumDaysSinceLastFullBackup = "Database Off-Line"
		}	
   
       #We use the .ToString() Method to convert the value of the Recovery model to string and ignore Log backups for databases with Simple recovery model
       if ($db.RecoveryModel.Tostring() -eq "SIMPLE")
       {
           $logBackupDate="N/A"
           $NumDaysSinceLastLogBackup="N/A"
       }
       else
       {
           if($db.LastLogBackupDate -eq "1/1/0001 12:00 AM") 
           {
               $logBackupDate="Never been backed up"
           }
           else
           {
               $logBackupDate= "{0:g2}" -f $db.LastLogBackupDate
           }
           
       }
   
       #Define your service-level agreement in terms of days here
       if (($NumDaysSinceLastFullBackup -gt 1) -and ($NumDaysSinceLastFullBackup -lt 7))
       {
			$fgColor = 7
       }
       Elseif (($NumDaysSinceLastFullBackup -gt 7) -and ($NumDaysSinceLastFullBackup -ne "Database Off-Line"))
	   {
			$fgColor = 3
	   }
	   Elseif ($NumDaysSinceLastFullBackup -eq "Database Off-Line")
	   {
			$fgColor = 6
	   }
	   ELSE
       {
			$fgColor = 2
       }
	   
       $Sheet.Cells.Item($intRow, 1) = $db.Name
	   $Sheet.Cells.item($intRow, 1).Interior.ColorIndex = $fgColor 
       $Sheet.Cells.Item($intRow, 2) = $fullBackupDate 
	   $Sheet.Cells.item($intRow, 2).Interior.ColorIndex = $fgColor      
       $Sheet.Cells.Item($intRow, 3) = $logBackupDate
	   $Sheet.Cells.item($intRow, 3).Interior.ColorIndex = $fgColor 
       $Sheet.Cells.Item($intRow, 4) = $NumDaysSinceLastFullBackup
       $Sheet.Cells.item($intRow, 4).Interior.ColorIndex = $fgColor
       $Sheet.Cells.Item($intRow, 5) =  $NumDaysSinceLastLogBackup
       $Sheet.Cells.item($intRow, 5).Interior.ColorIndex = $fgColor
           
       $intRow ++
   
       }
   }
   $intRow ++


}

$Sheet.UsedRange.EntireColumn.AutoFit()
$b.SaveAs($save)
$a.quit()

  
start-sleep -s 15  

## Send Mail - Send only CSV File for now
# Updated 4/7/2022
$Attachment= $save
#$emailFrom = "pburkhardt@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject =  "GLFHC Last Backup Report for $date from $ThisServer" 
$Body = "Inspect the attached log file..."
$smtpServer = "smtpmail.glfhc.local"
#$smtpServer = "mail.glfhc.org"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)



<#
# Send Email
$Attachment= $save
$EmailTo = "pburkhardt@glfhc.org" 
$EmailFrom   = "pburkhardt@glfhc.org"  
$Subject = "GLFHC Last Backup Report for $date from $ThisServer"  
$Body = "Inspect the attached log file..."
$SMTPServer  = "mail.glfhc.org"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)
#>

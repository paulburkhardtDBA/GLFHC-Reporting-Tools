# FileName:	DiskSpace.ps1
# Purpose:	Ths script will create an excel spreadsheet that displays each drive, available space, and free space
#		on each drive within a server.  If the disk Capacity falls below a certain threshold, a warning (yellow highlight)
#		is made.  If it falls too low, a Red hight is given).  Check out those dirves with the red highlights.

# ref: http://community.spiceworks.com/scripts/show/1074-powershell-script-to-check-free-disk-spaces-for-servers
# 12/19/13 include percentages with actual amount to calculate warning/alert
#Note: password was initially saved in an encrypted file by typing:
#	>read-host -assecurestring | convertfrom-securestring | out-file C:\Code\passcred.txt
#Once we have our password safely stored away, we can draw it back into our scripts..
#   >$password = get-content C:\Code\passcred.txt | convertto-securestring
#Then we can use the password as part of the credentials and don't have to retype it every time.

# Date                      Description
# --------   ------------------------------------------------------------------------------------
# 06/05/20	 Initial Version
# 1/28/25    Change user/pw/mail to wyang
$erroractionpreference = “SilentlyContinue” 
$a = New-Object -comobject Excel.Application 


$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

# Make output invisible 
$a.visible = $False

$b = $a.Workbooks.Add() 
$c = $b.Worksheets.Item(1)

# Set Threshold values
 
$Warning = 5
$Alert = 1
$PercentWarning = 20
$PercentAlert = 10


# Define Output FileName

$date = get-date -format "yyyyMMddHHmm"  
$save = "c:\output\diskspace_$date.xlsx"  
$ErrorLog = "C:\Output\Error_DiskReport$date.log"
# Create Header

$c.Cells.Item(1,1) = “Machine Name” 
$c.Cells.Item(1,2) = “Drive” 
$c.cells.item(1,3) = "Name "
$c.Cells.Item(1,4) = “Total Capacity (GB)” 
$c.Cells.Item(1,5) = “Free Space (GB)” 
$c.Cells.Item(1,6) = “Free Space (%)” 

# Freeze Top Row

$c.application.activewindow.splitcolumn = 0
$c.application.activewindow.splitrow = 1
$c.application.activewindow.freezepanes = $true

$d = $c.UsedRange 
$d.Interior.ColorIndex = 19 
$d.Font.ColorIndex = 11 
$d.Font.Bold = $True 
$d.EntireColumn.AutoFit()

$intRow = 2

#write-Output "Warning = $Warning "
#write-Output "Alert = $Alert"  

$colComputers = get-content "C:\Code\JustServerNameList.txt"
foreach ($strComputer in $colComputers) 
{ 
 	$c.Cells.Item($intRow, 1) = $strComputer.ToUpper() 
TRY
 {
	#"Connecting to $strComputer" | Write-Host -ForegroundColor Blue

		$colDisks = get-wmiobject Win32_Volume -Credential $credential -computername $strComputer -Filter "DriveType = 3"
	
	foreach ($objdisk in $colDisks) 
	{ 
	If (($objDisk.Name.length -ne $NULL) -and ($objDisk.Name -notcontains "A") -and ($objDisk.Label -notlike "*System*" ))
	{
		$c.Cells.Item($intRow, 2) = $objDisk.Name 
		$c.cells.item($introw, 3) = $objdisk.Label
		$c.Cells.Item($intRow, 4) = [math]::round(($objDisk.Capacity)/1GB, 2)
		$c.Cells.Item($intRow, 5) = [math]::round(($objDisk.FreeSpace)/1GB,2) 
		$c.Cells.Item($intRow, 6) = [math]::round((($objDisk.FreeSpace/$objDisk.Capacity)*100),2) 

		$freespace = ($objDisk.FreeSpace/1GB)
		$percentFree =  (($objDisk.FreeSpace/[double]$objDisk.Capacity)*100)

		# for debugging 
		# write-output  "Amount of free space = $freespace"

		#If (($freespace -le $Warning) -and ($freespace -gt $Alert))
		#If ((($freespace -le $Warning) -and ($freespace -gt $Alert)) -and (($percentFree -le $PercentWarning) -and ($percentFree -gt $PersentAlert)))
		If (($percentFree -le $PercentWarning) -and ($percentFree -gt $PersentAlert))
		{
			$c.Cells.Item($intRow, 2).Interior.ColorIndex = 27 
			$c.Cells.Item($intRow, 3).Interior.ColorIndex = 27 
			$c.Cells.Item($intRow, 4).Interior.ColorIndex = 27  
			$c.Cells.Item($intRow, 5).Interior.ColorIndex = 27 
			$c.Cells.Item($intRow, 6).Interior.ColorIndex = 27 
		} 
		#elseif (($freespace -le $Alert) -and ($freespace -ge 0))
		#elseif ((($freespace -le $Alert) -and ($freespace -ge 0)) -and (($percentFree -le $PersentAlert) -and ($percentFree -ge 0)))
		elseif (($percentFree -le $PersentAlert) -and ($percentFree -ge 0))
		{
			$c.Cells.Item($intRow, 2).Interior.ColorIndex = 3 
			$c.Cells.Item($intRow, 3).Interior.ColorIndex = 3 
			$c.Cells.Item($intRow, 4).Interior.ColorIndex = 3  
			$c.Cells.Item($intRow, 5).Interior.ColorIndex = 3 
			$c.Cells.Item($intRow, 6).Interior.ColorIndex = 3 
		} 
	
		#4/23/2015 add HCSQL logic
		#5/5/2015 Refined logic to measure Data Disk for Size (not percentFree) threshold.
		#1/11/2021 remove HCSQL logic - Server resided in a different environent
	}
	$intRow = $intRow + 1 
	} 
  }
catch
 {
	 #"Instance Unavailable - Could Not connect to $strComputer." | Write-Host -ForegroundColor Red
	$c.Cells.Item($intRow, 1) = $strComputer.ToUpper() 
	$c.Cells.Item($intRow, 2) = "Unreachable"
	$c.Cells.Item($intRow, 3) = "" 
	$c.Cells.Item($intRow, 4) = "" 
	$c.Cells.Item($intRow, 5) = "" 
	$c.cells.item($introw, 6) = ""
	
	$c.Cells.Item($intRow, 1).Interior.ColorIndex = 28
	$c.Cells.Item($intRow, 1).Font.ColorIndex = 5
	$c.Cells.Item($intRow, 2).Interior.ColorIndex = 28
	$c.Cells.Item($intRow, 2).Font.ColorIndex = 5
	$c.Cells.Item($intRow, 3).Interior.ColorIndex = 28
	$c.Cells.Item($intRow, 3).Font.ColorIndex = 5	
	$c.Cells.Item($intRow, 4).Interior.ColorIndex = 28
	$c.Cells.Item($intRow, 4).Font.ColorIndex = 5	
	$c.Cells.Item($intRow, 5).Interior.ColorIndex = 28
	$c.Cells.Item($intRow, 5).Font.ColorIndex = 5	

	# Added 7/5/16
	# Capture Errors and write to a file
	# $ErrorLog defined in beginning

#	Out-File -FilePath $ErrorLog -Append -InputObject $exception

	# Handle the error
	$Line = "Error found on Server " + $strComputer.ToUpper()
	$Line | Out-File -append -FilePath $ErrorLog
	
	$err = $_.Exception
	#write-output  $err.Message
	$err.Message | Out-File -append -FilePath $ErrorLog

	$intRow = $intRow + 1 
	continue
  }
}
$c.cells.item($intRow+1, 1) = "LEGEND:"  
$c.cells.item($intRow+1, 1).Font.Bold = $True
$c.cells.item($intRow+2, 1) = "Warning (Less than $PercentWarning % Free) "   
$c.cells.Item($intRow+2, 2).Interior.ColorIndex = 27  
$c.cells.item($introw+3,1) = "Alert! (Less than $PercentAlert  % Free)"   
$c.cells.Item($intRow+3,2).Interior.ColorIndex = 3 
$c.cells.item($introw+4,1) = "Server Unreachable"   
$c.cells.Item($intRow+4,2).Interior.ColorIndex = 28   

$d.EntireColumn.AutoFit()

$b.SaveAs($save)  
$a.quit()  

start-sleep -s 15  

# Email Results
 
## Send Mail - Send only CSV File for now
# Updated 4/7/2022
$Attachment= $save
#$emailFrom = "pburkhardt@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "GLFHC Disk Space Report for $date from $ThisServer"  
$Body = "Please review the attached report to insure enough space is available..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


<#
$Attachment = $save
$EmailFrom = "pburkhardt@glfhc.org"
$EmailTo = "pburkhardt@glfhc.org" 
$Subject = "GLFHC Disk Space Report for $date from $ThisServer" 
$Body = "The log file is attached..."  
$SMTPServer = "mail.glfhc.org" 
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password)
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
#>
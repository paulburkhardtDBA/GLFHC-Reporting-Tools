#File:		GLFHCSQLHealthCheck.ps1
#Purpose:	This script create an Excel report of all CMS registered SQL Servers and emails the results.
#reference: 	http://itknowledgeexchange.techtarget.com/dba/powershell-sql-server-health-check-script/
#
#  Date				Change
#  11/19/12			original
#  12/6/20			Fixed Instance referece
# 1/27/25           change user/pw/dbmail to wyang

# suppress error messages
$erroractionpreference = "SilentlyContinue"

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring 
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring 

$FilePath = "C:\Output"
$strPath  = Join-Path -path $FilePath -childPath ("GLFHCSQLHealthCheck_" + (get-date).toString('yyyyMMdd_hhmmtt') + ".xlsx")

#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()

$ThisServer = get-content env:computername

$excel = New-Object -ComObject Excel.Application
$excel.visible = $False

# Create It 
$worksheet = $excel.Workbooks.Add() 
$Sheet = $excel.Worksheets.Item(1)


#Counter variable for rows
$intRow = 2

#Read thru the contents of the SQL_Servers.txt file
$servers = Import-Csv "C:\Code\ServerListing.csv"

#########################################################
foreach ($entry in $servers)
{
	$torp = $entry.TorP
	$mon = $entry.monitor
	$machine = $entry.server
	$errorlog = $entry.errorlog
	$ip = $entry.IPAddress
	$iname = $entry.Instance
	
	# Define Instance
	if ($iname.length -eq 0)
	{
	$instance = "$machine"
	}
	else
	{
	$instance = "$machine\$iname"
	}
	# Define Instance Category (Dev, Test, or Prod)
	
	if ($torp -eq "Dev")
	{
	$ServerType = "Development"
	}
	elseif ($torp -eq "Prod")
	{
	$ServerType = "Production"
	}
	elseif ($torp -eq "Test")
	{
	$ServerType = "Test"
	}

	$instance = $instance.toupper()

	#Create column headers
	$Sheet.Cells.Item($intRow,1) = "INSTANCE NAME:"
	$Sheet.Cells.Item($intRow,2) = $instance

	#This script gets SQL Server database information using PowerShell

	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

	# Create an SMO connection to the instance
	$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instance

	$dbs = $s.Databases

	#$dbs | SELECT Name, Collation, CompatibilityLevel, AutoShrink, RecoveryModel, Size, SpaceAvailable

	#Formatting using Excel

	$version = $s.VersionString
	
	# SQL Server 7
	if ($version -like "*7.00.1094*")
	{        
		$sqlversion = "SQL Server 7 SP4 with Q815495, Q821279"
	}
	# SQL Server 2000 Checks
	elseif ($version -like "*8.00.194*")
	{        
		$sqlversion = "SQL Server 2000 No SP"
	}
	elseif ($version -like "*8.00.2065*")
	{        
		$sqlversion = "SQL Server 2000 with HoxFix MS12-060"
	}
	elseif ($version -like "*8.00.2066*")
	{        
		$sqlversion = "SQL Server 2000 with HoxFix 983808"
	}
	elseif ($version -like "*8.00.384*")
	{        
		$sqlversion = "SQL Server 2000 SP1"
	}
	elseif ($version -like "*8.00.532*")
	{        
		$sqlversion = "SQL Server 2000 SP2"
	}
	elseif ($version -like "*8.00.760*")
	{        
		$sqlversion = "SQL Server 2000 SP3"
	}
	elseif ($version -like "*8.00.818*")
	{        
		$sqlversion = "SQL Server 2000 SP3 with MS03-031"
	}
	elseif ($version -like "*8.00.2039*")
	{        
		$sqlversion = "SQL Server 2000 SP4"
	}
	elseif ($version -like "*8.00.2040*")
	{        
		$sqlversion = "SQL Server 2000 NoSP with Q274329"
	}
	elseif ($version -like "*8.00.2050*")
	{        
		$sqlversion = "SQL Server 2000 SP4 with MS08-040"
	}
	elseif ($version -like "*8.00.2055*")
	{        
		$sqlversion = "SQL Server 2000 SP4 Hotfix 959420"
	}
	elseif ($version -like "*8.00.2187*")
	{        
		$sqlversion = "SQL Server 2000 SP1 with Q923849"
	}
	elseif ($version -like "*8.00.2282*")
	{        
		$sqlversion = "SQL Server 2000 QFE"
	}
	elseif ($version -like "*8.00.3073*")
	{        
		$sqlversion = "SQL Server 2000 SP2 with Q954606"
	}
	# SQL Server 2005 Checks
	elseif ($version -like "*9.00.1399*")
	{        
		$sqlversion = "SQL Server 2005 RTM"
	}
	elseif ($version -like "*9.00.2047*")
	{        
		$sqlversion = "SQL Server 2005 SP1"
	}
	elseif ($version -like "*9.00.3042*")
	{        
		$sqlversion = "SQL Server 2005 SP2"
	}
	elseif ($version -like "*9.00.3068*")
	{        
		$sqlversion = "SQL 2005 (GDR) SP2 with Q941203 / 948109"
	}
	elseif ($version -like "*9.00.3054*")
	{        
		$sqlversion = "SQL 2005 SP2 with Q934458"
	}
	elseif ($version -like "*9.00.3073*")
	{        
		$sqlversion = "SQL 2005 SP2+Q954606 (GDR)"
	}
	elseif ($version -like "*9.00.3080*")
	{        
		$sqlversion = "SQL 2005 SP2+Q970895"
	}
	elseif ($version -like "*9.00.3186*")	
	{        
		$sqlversion = "SQL Server 2005 SP2 with Q939562"
	}
	elseif ($version -like "*9.00.4060*")
	{        
		$sqlversion = "SQL Server 2005 SP2 with HotFix 2494113"
	}
	elseif ($version -like "*9.00.4035*")
	{        
		$sqlversion = "SQL Server 2005 SP3"
	}
	elseif ($version -like "*9.00.50*")
	{        
		$sqlversion = "SQL Server 2005 SP4"
	}
	# SQL Server 2008
	elseif ($version -like "*10.00.1442.32*")
	{        
		$sqlversion = "SQL Server 2008 X64 MSDN Beta"
	}
	elseif ($version -like "*10.0.1600.22*")
	{        
		$sqlversion = "SQL Server 2008 RTM"
	}
	elseif ($version -like "*10.00.1600.22*")
	{        
		$sqlversion = "SQL Server 2008 RTM"
	}
	elseif ($version -like "*10.00.25*")
	{        
		$sqlversion = "SQL Server 2008 SP1"
	}
		elseif ($version -like "*10.0.25*")
	{        
		$sqlversion = "SQL Server 2008 SP1"
	}
	elseif ($version -like "*10.0.4000.*")
	{        
		$sqlversion = "SQL Server 2008 SP2"
	}
	elseif ($version -like "*10.00.4000.*")
	{        
		$sqlversion = "SQL Server 2008 SP2"
	}
	elseif ($version -like "*10.00.55*")
	{        
		$sqlversion = "SQL Server 2008 SP3"
	}
	# SQL Server 2008R2
	elseif ($version -like "*10.50.1600.1*")
	{        
		$sqlversion = "SQL Server 2008 R2 RTM"
	}
	elseif ($version -like "*10.50.1790.*")
	{        
		$sqlversion = "SQL Server 2008 R2 HoxFix 2520808"
	}
	elseif ($version -like "*10.50.2500*")
	{        
		$sqlversion = "SQL Server 2008 R2 SP1"
	}
	elseif ($version -like "*10.50.4000*")
	{        
		$sqlversion = "SQL Server 2008 R2 SP2"
	}		
	# SQL Server 2012
	elseif ($version -like "*11.00.2100.60*")
	{        
		$sqlversion = "SQL Server 2012 RTM"
	}
	elseif ($version -like "*11.00.3000*")
	{        
		$sqlversion = "SQL Server 2012 SP1"
	}
	elseif ($version -like "*11.0.5*")
	{        
		$sqlversion = "SQL Server 2012 SP2"
	}
	elseif ($version -like "*11.0.6*")
	{        
		$sqlversion = "SQL Server 2012 SP3"
	}
		elseif ($version -like "*11.0.7*")
	{        
		$sqlversion = "SQL Server 2012 SP4"
	}
	# SQL Server 2014
	elseif ($version -like "*12.0.2000.8*")
	{        
		$sqlversion = "SQL Server 2014 RTM"
	}
	elseif ($version -like "*12.0.4*")
	{        
		$sqlversion = "SQL Server 2014 SP1"
	}	
	elseif ($version -like "*12.0.5*")
	{        
		$sqlversion = "SQL Server 2014 SP2"
	}
	elseif ($version -like "*12.0.6*")
	{        
		$sqlversion = "SQL Server 2014 SP3"
	}	
	# SQL Server 2016
	elseif ($version -like "*13.0.1601.5")
	{        
		$sqlversion = "SQL Server 2016 RTM"
	}
	elseif ($version -like "*13.0.4*")
	{        
		$sqlversion = "SQL Server 2016 SP1"
	}
	elseif ($version -like "*13.0.5*")
	{        
		$sqlversion = "SQL Server 2016 SP2"
	}
	elseif ($version -like "*13.0.6*")
	{        
		$sqlversion = "SQL Server 2016 SP3"
	}
		elseif ($version -like "*13.0.7*")
	{        
		$sqlversion = "SQL Server 2016 Azure Connect Pack"
	}
	# SQL Server 2017
	elseif ($version -like "*14.0.*")
	{        
		$CumUpdate = $s.ProductUpdateLevel
		$sqlversion = "SQL Server 2017 $CumUpdate"
	}
	# SQL Server 2019
	elseif ($version -like "*15.0.*")
	{        
		$CumUpdate = $s.ProductUpdateLevel
		$sqlversion = "SQL Server 2019 $CumUpdate"
	}
	# SQL Server 2022
	elseif ($version -like "*16.0.*")
	{        
		$CumUpdate = $s.ProductUpdateLevel
		$sqlversion = "SQL Server 2022 $CumUpdate"
	}
	else
	{        

		$sqlversion = "$version"
	}
<#
	# Debugging
	write-host "Server = $machine"
	write-host "Version = $version"
	write-host "SQLversion = $sqlversion"
#>
	$Sheet.Cells.Item($intRow,3) = "Version:"
	$Sheet.Cells.Item($intRow,4) = $sqlversion
	$Sheet.Cells.Item($intRow,5) = $ServerType
	
	if ($Servertype -eq "Development")
	{
		$fgColor = 48
	}
	elseif ($Servertype -eq "Test")
	{
		$fgColor = 46
	}
	elseif ($Servertype -eq "Production")
	{
		$fgColor = 35
	}
	
	
	$Sheet.Cells.item($intRow, 5).Interior.ColorIndex = $fgColor

	###########################################################

	$Sheet.Cells.Item($intRow,1).Font.Bold = $True
	$Sheet.Cells.Item($intRow,2).Font.Bold = $True
	$Sheet.Cells.Item($intRow,3).Font.Bold = $True
	$Sheet.Cells.Item($intRow,4).Font.Bold = $True
	$Sheet.Cells.Item($intRow,5).Font.Bold = $True

	###########################################################
	## Are full and tranlog backups running?
	## DB Reindexing running?
	###########################################################

	$intRow ++

	$jobsserver = $s.JobServer
	$jobs = $jobsserver.Jobs
	$ijob = 0
	$backjob = 0
	$tranjob = 0
	foreach ($job in $jobs)

	{
		if (($job.name -like "*backup*") -and ($job.name -notlike "*Tranlog*"))
		{
			$backjob = 1
			$fullbackup = $job.name
			$fullbackupstatus = $job.LastRunOutcome
			$fullbackupdate = $job.LastRunDate
		}
		if ($job.Name -like "*tranlog*")
		{
			$tranjob = 1
			$tranlogbackup = $job.name
			$tranlogbackupstatus = $job.LastRunOutcome
			$tranlogbackupdate = $job.LastRunDate
		}
		if ($job.Name -like "*index*")
		{
			$ijob = 1
			$rebuildindex = $job.Name
			$rebuildindexstatus = $job.LastRunOutcome
			$rebuildindexdate = $job.LastRunDate
		}
	}

	## Check to verify full backups are running ##
	$dayago = [datetime]::Now.AddDays(-1)
	if (($fullbackupstatus -eq "Succeeded") -and ($fullbackupdate -gt $dayago))
	{
		$fullbackupjob = "Full Backups Running"
	}
	elseif(($fullbackupstatus -ne "succeeded") -or ($fullbackupdate -lt $dayago))
	{
		$fullbackupjob = "Full Backups Failing"
	}
	if ($backjob -eq 0)
	{
		$fullbackupjob = "No Full Backup Job"
	}

	## Check to verify that Tranlogs backups are running fine ##
	$hourago = [datetime]::Now.AddHours(-1)
	if (($tranlogbackupstatus -eq "Succeeded") -and ($tranlogbackupdate -gt $hourago))
	{
		$tranbackupjob = "Tran Backup Running"
	}
	if(($tranlogbackupstatus -ne "succeeded") -or ($tranlogbackupdate -lt $hourago))
	{
		$tranbackupjob = "Tran BackupFailing"
	}
	if ($tranjob -eq 0)
	{
		$tranbackupjob = "No Tran Backup Job"
	}
	$weekago = [datetime]::Now.AddDays(-7)
	if (($rebuildindexstatus -eq "Succeeded") -and ($rebuildindexdate -gt $weekago))
	{
		$indexjob = "Indexing Running"
	}
	elseif(($rebuildindexstatus -ne "succeeded") -or ($rebuildindexdate -lt $weekago))
	{
		$indexjob = "Indexing Failing"
	}
	if ($ijob -eq 0)
	{
		$indexjob = "No Indexing Job"
	}

	$Sheet.Cells.Item($intRow,1) = $fullbackupjob
	$Sheet.Cells.Item($intRow,2) = $tranbackupjob
	$Sheet.Cells.Item($intRow,3) = $indexjob
	$Sheet.Cells.Item($intRow,1).Font.Bold = $True
	$Sheet.Cells.Item($intRow,2).Font.Bold = $True
	$Sheet.Cells.Item($intRow,3).Font.Bold = $True

	##############################################

	$intRow++

	$Sheet.Cells.Item($intRow,1) = "DATABASE NAME"
	$Sheet.Cells.Item($intRow,2) = "RECOVERY MODEL"
	$Sheet.Cells.Item($intRow,3) = "CREATION DATE"
	$Sheet.Cells.Item($intRow,4) = "SIZE (MB)"
	$Sheet.Cells.Item($intRow,5) = "SPACE AVAILABLE (MB)"
	$Sheet.Cells.Item($intRow,6) = "DATA DRIVE"
	$Sheet.Cells.Item($intRow,7) = "SPACE AVAILABLE ON DISK (GB)"
	$Sheet.Cells.Item($intRow,8) = "MIRROR STATUS"
	$Sheet.Cells.Item($intRow,9) = "LOG SIZE (MB)"

	#Format the column headers
	for ($col = 1; $col –le 8; $col++)
	{
	$Sheet.Cells.Item($intRow,$col).Font.Bold = $True
	$Sheet.Cells.Item($intRow,$col).Interior.ColorIndex = 48
	$Sheet.Cells.Item($intRow,$col).Font.ColorIndex = 34
	}

	$intRow++
	
	foreach ($db in $dbs)
	{
		$name = $db.name
		$model = $db.recoverymodel
		if ($model -eq 1)
		{
			$modelname = "Full"
		}
		elseif ($model -eq 2)
		{
			$modelname = "Bulk Logged"
		}
		elseif ($model -eq 3)
		{
			$modelname = "Simple"
		}
		
		$create_date = $db.CreateDate
		$logfiles = $db.LogFiles
		foreach ($log in $logfiles)
		{
			$logsize = $log.size/1KB
			$logsize = [math]::Round($logsize, 2)
		}

		#if(($name -ne "master") -and ($name -ne "model")) # -and ($name -ne "msdb"))
		#{
		#Divide the value of SpaceAvailable by 1KB
		$dbSpaceAvailable = $db.SpaceAvailable/1KB

		#Format the results to a number with three decimal places
		$dbSpaceAvailable = "{0:N3}" -f $dbSpaceAvailable

		$Sheet.Cells.Item($intRow, 1) = $db.Name

		$Sheet.Cells.Item($intRow, 2) = $modelname
		$Sheet.Cells.Item($intRow, 3) = $create_date
		$Sheet.Cells.Item($intRow, 4) = "{0:N3}" -f $db.Size

		#Change the background color of the Cell depending on the SpaceAvailable property value
		if ($dbSpaceAvailable -eq 0.00)
		{
			$fgColor = 38
		}
		else
		{
			$fgColor = 0
		}

		$Sheet.Cells.Item($intRow, 5) = $dbSpaceAvailable
		$Sheet.Cells.item($intRow, 5).Interior.ColorIndex = $fgColor

		$dblocation = $db.primaryfilepath
		$dblocation = $dblocation.split(":")

		$dbdrive = $dblocation[0]
		$drives = Get-WmiObject -ComputerName $machine Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
		foreach($drive in $drives)
		{
			$size1 = $drive.size / 1GB
			$size = "{0:N2}" -f $size1
			$free1 = $drive.freespace / 1GB
			$free = "{0:N2}" -f $free1
			$ID = $drive.DeviceID
			$a = $free1 / $size1 * 100
			$b = "{0:N2}" -f $a

			if ($dbdrive -eq "C")
			{
				$fgColor = 38
			}
			else
			{
				$fgColor = 0
			}

			$Sheet.Cells.Item($intRow,6) = $dbdrive
			$Sheet.Cells.item($intRow,6).Interior.ColorIndex = $fgColor

			if ($id -like "$dbdrive*")
			{
				if ($free1 -lt 5)
				{
				$fgColor = 38
				}
				else
				{
				$fgColor = 0
				}
				if (($ID -eq "C:") -and ($free1 -lt 1))
				{
				$fgColor = 38
				}
				$Sheet.Cells.Item($intRow,7) = $free1
				$Sheet.Cells.item($intRow,7).Interior.ColorIndex = $fgColor
			}
		}
		if($version -like "*2000*")
		{
			$mirrorstate = 0
		}
		else
		{
			$mirrorstate = $db.MirroringStatus
		}
		if ($mirrorstate -eq 0)
		{
			$mirror = "No Mirror"
		}
		if ($mirrorstate -eq 1)
		{
			$mirror = "Suspended"
		}
		if($mirrorstate -eq 5)
		{
			$mirror = "Synchronized"
		}
		if ($mirrorstate -eq 1)
		{
			$fgcolor = 38
		}
		else
		{
			$fgcolor = 0
		}
		$Sheet.Cells.Item($intRow,8) = $mirror
		$Sheet.Cells.item($intRow,8).Interior.ColorIndex = $fgColor

		if (($logsize -gt 500) -and ($model -ne 3))
		{
			$fgColor = 38
		}
		elseif (($logsize -gt 500) -and ($model -eq 3))
		{
			$fgColor = 27
		}
		else
		{
			$fgColor = 0
		}

		$Sheet.Cells.Item($intRow,9) = $logsize
		$Sheet.Cells.item($intRow,9).Interior.ColorIndex = $fgColor

		$intRow ++

		#}
		}

		$intRow ++

	}



$Sheet.UsedRange.EntireColumn.AutoFit()
$excel.ActiveWorkBook.SaveAs($strPath)
$Sheet = $null
$worksheet.Close()  
$worksheet = $null 
$excel.Quit()  
$excel = $null 
[GC]::Collect()

#let's set up the email stuff
$Attachment = $strPath
#$emailFrom = "pburkhardt@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$Subject = "SQL Audit Report at GLFHC for $today on $ThisServer."
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



Remove-Variable  * -Scope Global -ErrorAction SilentlyContinue

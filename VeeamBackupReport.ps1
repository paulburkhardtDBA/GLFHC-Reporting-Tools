<#
FileName:	VeeamBackupReport.ps1
Purpose:	This script collects the backup information for the defined days
		and emails the report.

Date		Author				Description
-------		------		------------------------------------
11/14/2023	PEB			Orginal Version
11/16/2023	PEB			Add SysAdmins to email
					
#>


# Suppress Error Messages
#$erroractionpreference = "SilentlyContinue"

# Get Credential for email
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

# Connect to the Veeam Server by asking for Credentials ( username & password)
#### For testing, use your account creds
#connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xpburkhardt' -password '!$VeE@m2021!'
connect-vbrserver -server "hav-veeam" -user 'hav-veeam\xwyang' -password 'EXpcW8ue*g$tkmS@Ro9P'
#Connect-VBRServer -server "hav-veeam"  -Credential (Get-Credential)

# Local Variables
$days = 7 #Report x number of days
$ThisServer = get-content env:computername
$timeStamp = (Get-Date).ToString('MM-dd-yyyy')

#load Veeam Powershell Snapin
#Add-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue
#Style
$style = @"
<style>
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:orange}
TD{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:lightblue}
tr.special {background: #000080;} <tr class="special"></tr>
</style>
"@

$Report = @()

$Jobs = Get-VBRJob | where Name -notlike "Archive*"

foreach ($job in $Jobs) {
    $jobName = $job.Name
    # for debugging
    # write-host "Processing $jobName"
    $table = New-Object system.Data.DataTable "$table01"

    #region Setup table columns
    $col1 = New-Object system.Data.DataColumn Index,([int])
    $col2 = New-Object system.Data.DataColumn JobName,([string])
    $col3 = New-Object system.Data.DataColumn VMList,([String])
    $col4 = New-Object system.Data.DataColumn StartTime,([DateTime])
    $col5 = New-Object system.Data.DataColumn StopTime,([DateTime])
    $col6 = New-Object system.Data.DataColumn FileName,([string])
    $col6a = New-Object system.Data.DataColumn FileSize,([String])
    $col6b = New-Object system.Data.DataColumn BackupSize,([String])
    $col6c = New-Object system.Data.DataColumn DataSize,([String])
    $col6d = New-Object system.Data.DataColumn DedupRatio,([String])
    $col6e = New-Object system.Data.DataColumn CompressRatio,([String])
    $col7 = New-Object system.Data.DataColumn CreationTime,([DateTime])
    $col8 = New-Object system.Data.DataColumn AvgSpeedMB,([int])
    $col9 = New-Object system.Data.DataColumn Duration,([TimeSpan])
    $col10 = New-Object system.Data.DataColumn Result,([String])


    $table.columns.add($col1)
    $table.columns.add($col2)
    $table.columns.add($col3)
    $table.columns.add($col4)
    $table.columns.add($col5)
    $table.columns.add($col6)
    $table.columns.add($col6a)
    $table.columns.add($col6b)
    $table.columns.add($col6c)
    $table.columns.add($col6d)
    $table.columns.add($col6e)
    $table.columns.add($col7)
    $table.columns.add($col8)
    $table.columns.add($col9)
    $table.columns.add($col10)
    #endregion

    #Grab all Backup Sessions on the server where their .JobId property is the same as the Get-VBRJob objects .Id property
    $session = Get-VBRBackupSession | ?{$_.JobId -eq $job.Id} | %{
        $row = $table.NewRow()
        $row.JobName = $_.JobName
        $row.StartTime = $_.CreationTime
        $row.StopTime = $_.EndTime
        #Work out average speed in MB and round this to 0 decimal places, just like the Veeam GUI does.
        $row.AvgSpeedMB = [Math]::Round($_.Progress.AvgSpeed/1024/1024,0)
        #Duration is a Timespan value, so I am formatting in here using 3 properties - HH,MM,SS
        $row.Duration = '{0:00}:{1:00}:{2:00}' -f $_.Progress.Duration.Hours, $_.Progress.Duration.Minutes, $_.Progress.Duration.Seconds

        if ($_.Result -eq "Failed") {
        #This is highlight is going to later be searched and replaced with HTML code to highlight failed jobs in RED  
        $row.Result = "#HIGHLIGHTRED"+$_.Result+"HIGHLIGHTRED#"
        } else {
        #Don't highlight if the backup session didn't fail.
        $row.Result = $_.Result
        }
        #Add this calculated row to the $table.Rows
        $table.Rows.Add($row)
                
    }

    
    #Now we are grabbing all the backup objects (same as viewing Backups in the Veeam B&R GUI Console
    $backup = Get-VBRBackup | ?{$_.JobId -eq $job.Id}

    $points = $backup.GetAllStorages() | sort CreationTime -descending | Select -First $days #Find and assign the Veeam Backup files for each job we are going through and sort them in descending order. Select the specified amount.
    #if ($days -gt $points.Count) { $days = $points.Count} #if days is more than backup files found, limit to number of backups, otherwise, empty data lines ==> commented out, because it's not working as it should for now...
        
    
    $interestingsess = $table | Sort StartTime -descending | select -first $days
    
    $pkc = 1
    $interestingsess | foreach {
        
        #for every object in $interestingsess (which has now been sorted by StartTime) assign the current value of $pkc to the .Index property. 1,2,3,4,5,6 etc...
        $_.Index = $pkc
        #Increment $pkc, so the next foreach loop assigns a higher value to the next .Index property on the next row.
        $pkc+=1
    }
    

    #Increment variable is set to 1 to start off
    $ic = 1
    ForEach ($point in $points) {
        #Match the $ic (Increment variable) up with the Index number we kept earlier, and assign $table to $rows where they are the same. This happens for each object in $points
        $rows = $table | ?{$_.Index -eq $ic}

        #inner ForEach loop to assign the value of the backup point's filename and VMs to the row's .FileName property as well as the creation time.
        ForEach ($row in $rows) {
            $Backups = Get-VBRBackup | ?{$_.JobId -eq $job.Id}
            $vms =
            foreach ($Backup in $Backups) {
            $Backup.GetObjects() | Select Name 
            }
            $vms1 = $vms | out-string
            $vms1 = $vms1.replace(" " , "")
            $vms1 = $vms1.replace("Name" , "")
            $vms1 = $vms1.replace("----" , "")
            $vms1 = $vms1.replace("`r" , "")
            $vms1 = $vms1.replace("`n" , ";")
            $vms1 = $vms1.replace(";;;" , "")
            $vms1 = $vms1.replace("; ; ;" , "")
            $vms1 = $vms1.replace(" ;" , "; ")
            if ($point.PartialPath -ne "") 
            {
                ($row.FileName = $point.PartialPath) -and ($row.CreationTime = $point.CreationTime) -and ($row.VMList = $vms1) | out-null
                ($row.BackupSize = ($point.Stats.BackupSize/1GB).ToString(".00")) -and ($row.CreationTime = $point.CreationTime) -and ($row.VMList = $vms1) | out-null
                ($row.DataSize = ($point.Stats.DataSize/1GB).ToString(".00")) -and ($row.CreationTime = $point.CreationTime) -and ($row.VMList = $vms1) | out-null
                ($row.DedupRatio = (100/($point.Stats.DedupRatio)).ToString(".0")) -and ($row.CreationTime = $point.CreationTime) -and ($row.VMList = $vms1) | out-null
                ($row.CompressRatio = (100/($point.Stats.CompressRatio)).ToString(".0")) -and ($row.CreationTime = $point.CreationTime) -and ($row.VMList = $vms1) | out-null
            
                #Increment the $ic variable ( +1 )
                $ic+=1
                
            }
        }
    }
    #Tally up the current results into our $Report Array (add them)
    $Report += $interestingsess
}
# Disconnect from server
Disconnect-VBRServer | Out-Null

#Now we select those values of interest to us and convert the lot into HTML, assigning the styling we defined at the beginning of this script too.
$Report = $Report | Select Index, JobName, VMList, StartTime, StopTime, FileName, BackupSize, DataSize, DedupRatio, CompressRatio, CreationTime, AvgSpeedMB, Duration, Result| ConvertTo-HTML -head $style

#Interesting bit - replace the highlighted parts with HTML code to flag up Failed jobs.
$Report = $Report -replace "#HIGHLIGHTRED","<font color='red'><B>"
$Report = $Report -replace "HIGHLIGHTRED#","</font></B>"
#Finally, save the report to a file on your drive.
$Report | Set-Content C:\temp\Veeam-Backup-Report.htm -Force

# Send Email
$save = "C:\temp\Veeam-Backup-Report.htm"  
$Attachment= $save
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
#$emailTo = "BackupAdministrators@glfhc.org"
$subject = "Veeam Backup Report for last $days days from $ThisServer"    
$Body = "Please review the attached..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


# FileName: CreateALLSQLJobsList.ps1

# ref: https://rahmanagoro.wordpress.com/2010/08/26/script-out-sql-agent-jobs-from-powershell
$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername
$date = get-date -format "yyyyMMddHHmm"  

# Load SMO extension 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;

# Get Credentials

# Get List of sql servers to check
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
 
$sqlservers = Get-Content "C:\Code\JustServerNameList.txt";
 
# Loop through each sql server from sqlservers.txt
foreach($sqlserver in $sqlservers)
{
 
 TRY
 { 
      # Create an SMO Server object
      $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
 
      # Jobs counts
      $totalJobCount = $srv.JobServer.Jobs.Count;
      $failedCount = 0;
      $successCount = 0;
 
      # For each jobs on the server
      foreach($job in $srv.JobServer.Jobs)
 
      {
            # Default write colour
            $colour = "Green";
            $jobName = $job.Name;
            $jobEnabled = $job.IsEnabled;
            $jobLastRunOutcome = $job.LastRunOutcome;
            $jobNameFile = "D:\SQLInventory\SQLAgentJobs\" + $sqlserver + "_"+ $jobName + ".sql"
 
            #Write-Host $job.Name
            #Write-Host "The location of the file is called " $jobNameFile
 
#           [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
#           $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
#           #$srv.JobServer.Jobs | foreach {$_.Script()} | out-file -path $path
            $job | foreach {$_.Script()} | out-file $jobNameFile
 
            # Set write text to red for Failed jobs
            if($jobLastRunOutcome -eq "Failed")
 
            {
 
                  $colour = "Red";
                  $failedCount += 1;
            }
 
            elseif ($jobLastRunOutcome -eq "Succeeded")
            {
                  $successCount += 1;
            }
 
            
			#Write-Host -ForegroundColor $colour "SERVER = $sqlserver JOB = $jobName ENABLED = $jobEnabled LASTRUN = $jobLastRunOutcome";
      }
 
      # Writes a summary for each SQL server
      #Write-Host -ForegroundColor red "=========================================================================================";
      #Write-Host -ForegroundColor red "$sqlserver total jobs = $totalJobCOunt, success count $successCount, failed jobs = $failedCount.";
      #Write-Host -ForegroundColor red "=========================================================================================";
	}
catch
	{
	 	continue
	}
}
start-sleep -s 15  
  
# Send Email
#$Attachment= $save
$EmailTo = "wyang@glfhc.org" 
$EmailFrom   = "wyang@glfhc.org"  
$Subject = "GLFHC SQL Agent Jobs Created on $date from $ThisServer"  
$Body = "There's now a backup of the SQL jobs created in this area - D:\SQLInventory\SQLAgentJobs."  
$SMTPServer  = "smtpmail.glfhc.local"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
#$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
#$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)

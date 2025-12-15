# File:     CMSFineSQLJobFailures.ps1
# Author:   Paul Burkhardt
# Date:     9/27/2012
# Purpose:  Runs through the list of servers, finds Failed SQL Jobs with Powershell, writes the results
#           to a file and emails it out.
# Input:    C:\Code\ServerNameList.txt (list of registered servers)
# Output:   email message    
# Changes:
#           	Date		Author			Description
#	-------------		-------	 	------------------------------------------
#	9/27/12	 	PB		Original
#	10/10/12	PB		After testing for a week, added all DBAs to the notification list
#	8/12/13		PB		Eliminated reporting on any servers that contain the word "test"
#	10/3/13		PB		Reduced the selection criteria so that job failuers aren't reported more than once.
#	11/20/13	PB		Remove search of the HBI server for now per Kamini
#   1/27/14		PB		Add HBI back in
#   7/16/15 	PB 		Remove HBI 

#www.sqlsandwiches.com
#Reference: http://www.sqlservercentral.com/blogs/sqlsandwiches/2012/01/29/find-failed-sql-jobs-with-powershell/

#let's get our list of servers. For this, create a .txt files with all the server names you want to check.
$sqlservers = Get-Content "C:\Code\JustServerList.txt";

#we'll get the long date and toss that in a variable
$datefull = Get-Date
#and shorten it
$today = $datefull.ToShortDateString()

#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient("mail.glfhc.org")
$msg.Body = "Here is a list of failed SQL Jobs for $today (the last 24 hours)..."

#here, we will begin with a foreach loop. We'll be checking all servers in the .txt referenced above.
foreach($sqlserver in $sqlservers)
{	
	Write-Output ("Server: {0}" -f $sqlserver.ToLower());    
	
	#here we need to set which server we are going to check in this loop
    $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;
    
        #now let's loop through all the jobs
        foreach ($job in $srv.Jobserver.Jobs)
        {
            #now we are going to set up some variables. 
            #These values come from the information in $srv.Jobserver.Jobs
            $jobName = $job.Name;
        	$jobEnabled = $job.IsEnabled;
        	$jobLastRunOutcome = $job.LastRunOutcome;
            $jobLastRun = $job.LastRunDate;
            
                        
            #we are only concerned about jobs that are enabled and have run before. 
            #POSH is weird with nulls so you check by just calling the var
            #if we wanted to check isnull() we would use !$jobLastRun  
            if($jobEnabled = "true" -and $jobLastRun)
                {  
                   # we need to find out how many days ago that job ran
                   $datediff = New-TimeSpan $jobLastRun $today 
                   #now we need to take the value of days in $datediff
                   $days = $datediff.days
                   
                   
                       #gotta check to make sure the job ran in the last 24 hours     
                       if($days -lt 1 )                    
                         {       
                            #and make sure the job failed
                            IF($jobLastRunOutcome -eq "Failed")
                            {
                                #now we add the job info to our email body. use `n for a new line
                			    $msg.body = $msg.body + "`n `n FAILED JOB INFO: 
                                 SERVER = $sqlserver 
                                 JOB = $jobName 
                                 LASTRUN = $jobLastRunOutcome
                                 LASTRUNDATE = $jobLastRun"
                                 
                            }    
                          } 
                }
             

        
		
		}	
}

#once all that loops through and builds our $msg.body, we are read to send

#who is this coming from
# 3/31/22 modified for 0365
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$msg.From = "wyang@glfhc.org"
#and going to
$msg.To.Add("wyang@glfhc.org")
#and a nice pretty title
$msg.Subject = "FAILED SQL Jobs for $today"
#and BOOM! send that bastard!
$SMTPServer = "smtpmail.glfhc.local" 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25) 
#$SMTPClient.EnableSsl = $true 
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password); 
$SMTPClient.Send($msg.From, $msg.To, $msg.Subject, $msg.Body)
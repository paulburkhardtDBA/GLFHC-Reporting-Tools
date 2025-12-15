<#
Filename:	GLFHC_dbi_dbccLastKnownGood.ps1
Purpose:	This script examined all productin SQL Server (except SQL Express) instances. 
			It collects and reports the:
			- Server Name
			- Database Name
			- Last Good DBCC CheckDB
		Note: It excluses instances with the name "dev", "test", or "train".
#>
# suppress error messages
$erroractionpreference = "SilentlyContinue"

# Computer/User Credentals
$ThisServer = get-content env:computername

# Define Output FileName
$date = get-date -format "yyyyMMddHHmm"  
$save = "c:\output\DBCCCheckReport_$date.txt" 

# Location of the Source File for script (server names only)
$InstanceList = Get-Content "C:\Code\JustServerNameList.txt"

# Load SMO assembly
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null;

#Initialize Array to hold new database objects
$iDatabases = @()

#Loop over each instance provided
foreach ($instance in $InstanceList)
{
     try
    {
        #"Connecting to $instance" | Write-Host -ForegroundColor Blue
        
        $srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" $instance;
        #How many seconds to wait for instance to respond
        $srv.ConnectionContext.ConnectTimeout = 5
        $srv.get_BuildNumber() | out-Null
    }
    catch
    {
        #"Instance Unavailable - Could Not connect to $instance." | Write-Host -ForegroundColor Red
        continue
    }
    
    $srv.ConnectionContext.StatementTimeout = $QueryTimeout
    
	# Exclude SQL instances that have "dev", "test", or "train" in the name
	if (($instance.ToLower().Contains("DEV".ToLower()) -eq $False) -and ($instance.ToLower().Contains("TEST".ToLower()) -eq $False) -and ($instance.ToLower().Contains("TRAIN".ToLower()) -eq $False) -and ($instance.ToLower().Contains("QA".ToLower()) -eq $False))
	{
		foreach($Database in $srv.Databases)
		{
			#create object with all string properties
			$iDatabase = "" | SELECT InstanceName, DatabaseName, LastSuccessfulCheckDB
			#populate object with known values
			$iDatabase.InstanceName = $srv.Name
			$iDatabase.DatabaseName = $database.Name
			
			try
			{
				#Get date of last successful checkdb
				#executes dbcc dbinfo on database and narrows by dbi_dbcclastknowngood
				$database.ExecuteWithResults('dbcc dbinfo() with tableresults').Tables[0] | `
				?{$_.Field -eq "dbi_dbccLastKnownGood"}| `
				%{$iDatabase.LastSuccessfulCheckDB = [System.DateTime]$_.Value} -ErrorAction Stop
			}
			catch
			{
				#"CheckDB could not be determined for $instance.$database" | Write-Host -ForegroundColor Red
			}
			
			#add the iDatabase object to the array of iDatabase objects
			$iDatabases += $iDatabase
		}
	}
}

#output all the databases as a table for viewing pleasure
$iDatabases | Out-File -FilePath $save -Append

# email results
$mail = New-Object System.Net.Mail.MailMessage  
$att = new-object Net.Mail.Attachment($save)  
$mail.From = "GLFHCSQLAlert@glfhc.org"  
# comment out for testing 
$mail.To.Add("pburkhardt@glfhc.org")
$mail.Subject = "GLFHC DBCC CheckDB Report for $date from $ThisServer"  
$mail.Body = "The log file is attached"  
$mail.Attachments.Add($att)  
$smtp = New-Object System.Net.Mail.SmtpClient("mail.glfhc.org")     
$smtp.Send($mail)  
$att.Dispose()  
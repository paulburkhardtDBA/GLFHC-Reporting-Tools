<# File:		Check_ServicesAllServers.ps1
   Description:	Check SQL Server related services for several machines.
 .DESCRIPTION
    Are all SQL Server related and required services actually runing and in a well state? Checking this manually takes a lot of time.
    With this PowerShell script you can easily check all SQL Server related services for all servers of a given list.
    Gives a warning message if a service with "StartMode = Auto" is not running.
    Works with MS SQL Server 2000 and higher version services.
    Requires permission to connect to and fetch WMI data from the machine(s).
 .NOTES
    Author  : Olaf Helper
    Requires: PowerShell Version 1.0
 .LINK
    TechNet Get-WmiObject
       http://gallery.technet.microsoft.com/scriptcenter/Check-SQL-Server-related-b6390307
Revisions:

Date		Author						Description
-------		------		-----------------------------------------------------
2/5/2014		pb			original - clone of Check_Services.ps1 

#>

# turn off error messaging
$erroractionpreference = "SilentlyContinue"

# Configuration data.
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")

# define output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("AllDomianSQLServiceAgentReport_" + $isodate + ".txt")

#let's set up the email stuff
$emailFrom = "GLFHCSQLAlert@glfhc.org"  
$emailTo = "pburkhardt@glfhc.org"
$subject = "All Servers in GLFHC Domain Status Report for $isodate"
$body = "See what servers have SQL installed. Please review the attached list..."
$smtpServer = "mail.glfhc.org"

# Defining output format for each column.
$fmtName   =@{label="Service Name" ;alignment="left"  ;width=20 ;Expression={$_.Name};};
$fmtMode   =@{label="Start Mode"   ;alignment="left"  ;width=10 ;Expression={$_.StartMode};};
$fmtState  =@{label="State"        ;alignment="left"  ;width=10 ;Expression={$_.State};};
$fmtStatus =@{label="Status"       ;alignment="left"  ;width=10 ;Expression={$_.Status};};
$fmtMsg    =@{label="Message"      ;alignment="left"  ;width=20 ; `
              Expression={ if (($_.StartMode -eq "Auto") -and ($_.State -ne "Running")) {"Alarm: Stopped"} ELseif (($_.StartMode -eq "Manual") -and ($Clustered -eq "No")) {"Alarm: Warning"}  };};

$servers= get-content "C:\Code\JustServerNameList.txt"

foreach($server in $servers)
{

$s = Get-WmiObject -Class Win32_SystemServices -ComputerName $server
if ($s | select PartComponent | where {$_ -like "*ClusSvc*"}) 
	{
		 $Clustered = "Yes" 
	}
	else 
	{ 
		$Clustered = "No" 
	}
$srvc = "Server: {0}" -f $server
$srvc | Out-File -append -filePath $OutFile
$srvc = "Clustered: {0}" -f $Clustered
$srvc | Out-File -append -filePath $OutFile

    $srvc = Get-WmiObject `
            -query "SELECT * 
                    FROM win32_service 
                    WHERE    name LIKE 'MSSQL$%' 
                          OR name LIKE 'SQLAgent$%'
                          OR name LIKE 'SQLSERVERAGENT'
                          OR name LIKE 'MSSQLSERVER'" `
             -computername $server `
            | Sort-Object -property name;

   Write-Output ("Server: {0}" -f $server);
   Write-Output $srvc | Format-Table $fmtName, $fmtMode, $fmtState, $fmtStatus, $fmtMsg; 

	$srvc | Format-Table $fmtName, $fmtMode, $fmtState, $fmtStatus, $fmtMsg | Out-File -append -filePath $OutFile 

}

Function sendEmail([string]$emailFrom, [string]$emailTo, [string]$subject,[string]$body,[string]$smtpServer,[string]$OutFile)
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
#initiate sending email 
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($email)
}

#Send out the results before existing
sendEmail $emailFrom $emailTo $subject $body $smtpServer $OutFile

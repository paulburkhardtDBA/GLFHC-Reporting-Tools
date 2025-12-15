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
#$erroractionpreference = "SilentlyContinue"

# Configuration data.
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")

#let's set up the email stuff
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring


# define output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("AllDomianSQLServiceAgentReport_" + $isodate + ".txt")

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

   #Write-Output ("Server: {0}" -f $server);
   #Write-Output $srvc | Format-Table $fmtName, $fmtMode, $fmtState, $fmtStatus, $fmtMsg; 

	$srvc | Format-Table $fmtName, $fmtMode, $fmtState, $fmtStatus, $fmtMsg | Out-File -append -filePath $OutFile 

}
# 3/31/22 modified for 0365
#let's set up the email stuff
$Attachment= $OutFile
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "All Servers in GLFHC Domain Status Report for $isodate"
$body = "See what servers have SQL installed. Please review the attached list..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


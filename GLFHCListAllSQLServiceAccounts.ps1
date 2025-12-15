<# File:		ListAllSQLServiceAccounts.ps1
   Description:	This code will read through an external file that contains all of the target servers.
				It lists each server along with the Service Name for each MS SQL service that resides
				on that server.  
				
				A report is then mailed out.

Revisions:

Date		Author						Description
-------		------		-----------------------------------------------------
2/5/2014		pb			original - clone of Check_Services.ps1 

#>

# turn off error messaging
$erroractionpreference = “SilentlyContinue” 

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

# Configuration data.
# define output file
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")

# define output file
$FilePath = "C:\Output"
$OutFile = Join-Path -path $FilePath -childPath ("SQLServicesReport_" + $isodate + ".txt")

# Defining output format for each column.
$fmtName   =@{label="Service Name" ;alignment="left"  ;width=20 ;Expression={$_.Name};};
$fmtState  =@{label="State"        ;alignment="left"  ;width=15 ;Expression={$_.State};};
$fmtSrvName =@{label="Service Account" ;alignment="left"  ;width=45 ;Expression={$_.Startname};};


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
# Tested 9/14/21
# Write-Output ("Server: {0}" -f $server);

# Tested 9/14/21
#Write-Output $srvc | Format-Table $fmtName,$fmtState, $fmtSrvName 

$srvc | Format-Table $fmtName,$fmtState, $fmtSrvName | Out-File -append -filePath $OutFile 

}
# Send Email
$Attachment = $OutFile
$EmailTo = "wyang@glfhc.org" 
$EmailFrom   = "wyang@glfhc.org"  
$Subject = "SQL Server Accounts at GLFHC for $isodate"
$Body = "See what accounts are being used on installed SQL services. Please review the attached list..."
$SMTPServer  = "smtpmail.glfhc.local"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)

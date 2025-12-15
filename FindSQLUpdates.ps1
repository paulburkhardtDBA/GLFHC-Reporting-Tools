
# turn off error messaging
$erroractionpreference = "SilentlyContinue"


# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

# Local Variables
$Servers = Get-Content "C:\Code\JustServerNameList.txt" 
$ThisServer = get-content env:computername
$date = get-date -format "yyyyMMddHHmm"
$OutFile = "c:\output\LatestOSPatch2_$date.txt"

#and shorten date
$today = $datefull.ToShortDateString()
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")

# Never know when you'll need a counter
$Counter = 0


$results = foreach ($Server in $Servers)
{
	TRY
	{ 
	$server |  Out-file $OutFile -Append
	 # Format date output
	$output = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall 	`
				| Get-ItemProperty | Sort-Object -Property DisplayName | `
				Select-Object -Property DisplayName, DisplayVersion, InstallDate `
				| Where-Object {($_.DisplayName -like "Hotfix*SQL*") -or ($_.DisplayName -like "Service Pack*SQL*")}| Format-List)
	 
	 $output | Out-file $OutFile -Append
	}
	CATCH
	{
	$err = $_.Exception
	continue
	}
}

# Email Report
$Attachment= $OutFile
$EmailTo = "wyang@glfhc.org" 
$EmailFrom   = "wyang@glfhc.org"  
$Subject = "GLFHC SQL Server Updates for $isodate"
$Body = "Please review the attached list to determine when servers will need updating..."
$SMTPServer  = "smtpmail.glfhc.local"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)



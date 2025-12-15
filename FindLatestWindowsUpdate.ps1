##
# 1/27/25  WY change user/pw/dbmail to wyang
##
# turn off error messaging
$erroractionpreference = "SilentlyContinue"

# Local Variables
$Servers = Get-Content "C:\Code\JustServerNameList.txt" 

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
$username = "wyang"
$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

$ThisServer = get-content env:computername
$date = get-date -format "yyyyMMddHHmm"
$OutFile = "c:\output\LatestOSPatch2_$date.txt"

#and shorten date
$today = $datefull.ToShortDateString()
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")

# Never know when you'll need a counter
$Counter = 0

#let's set up the email stuff
#$emailFrom = "GLFHCSQLAlert@crhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "GLFHCSQLAlert@crhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "GLFHC SQL Server Most Recent Windows Updates for $isodate"
$body = "Please review the attached list to determine when servers will need updating..."
$smtpServer = "smtpmail.glfhc.local"

$results = foreach ($Server in $Servers)
{
	TRY
	{
	 #$save = (Get-HotFix -Computername $server | Sort-Object -Property InstalledOn)[-1] 
	 # Format date save
	$save =  ((Get-HotFix -Computername $server |
		   Select-Object -Property PSComputername, Description, HotFixID, `
				@{Name="Day"; Expression = {$_.InstalledOn.Day}}, `
				@{Name="Month"; Expression = {$_.InstalledOn.Month}}, `
				@{Name="Year"; Expression = {$_.InstalledOn.Year}} |
				Sort-Object -Property InstalledOn)[-1] |
				Format-Table -AutoSize)
	 
	 $save | Out-file $OutFile -Append
	}
	CATCH
	{
	$err = $_.Exception
	continue
	}
}

# Email Results
 
## Send Mail - Send only CSV File for now
# Updated 4/7/2022
$Attachment= $OutFile
#$emailFrom = "pburkhardt@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "GLFHC SQL Server Most Recent Windows Updates for $isodate"
$Body = "Please review the attached list to determine when servers will need updating..."
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


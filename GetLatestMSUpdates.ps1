# FileName:	GetLatestMSUpdates.ps1
# Purpose:	This script creates an excel spreadsheet that lists the server, Description, Patch No,
#			installed date and installer for the latest patch that was applied.
#
#			This report is then emails out so that it can be inspected and servers can be
#			identified that require attention.
# ref: 
#
# Date                      Description
# ----------   ------------------------------------------------------------------------------------
# 09/23/2022	Initial Version

# Define local variables

#$erroractionpreference = "SilentlyContinue"
$ThisServer = get-content env:computername
$date = get-date -format "yyyyMMddHHmm"  
$save = "C:\Output\Patch_Installed_$((Get-date).ToString('MM-dd-yyyy')).csv"

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# Intialize Array
$Results = @()
# Get Server list
$servers = Get-Content C:\Code\JustServerNameList.txt
foreach ($servers in $servers){
$Properties = @{
NetBIOS_Name = Get-WmiObject Win32_OperatingSystem -ComputerName $servers | select -ExpandProperty CSName
Description = gwmi win32_quickfixengineering -computer $servers | ?{ $_.installedon }| sort @{e={[datetime]$_.InstalledOn}} | select -last 1 | select -ExpandProperty Description
HotFixID = gwmi win32_quickfixengineering -computer $servers | ?{ $_.installedon }| sort @{e={[datetime]$_.InstalledOn}} | select -last 1 | select -ExpandProperty HotFixID
InstalledBy = gwmi win32_quickfixengineering -computer $servers | ?{ $_.installedon }| sort @{e={[datetime]$_.InstalledOn}} | select -last 1 | select -ExpandProperty InstalledBy
InstalledOn = gwmi win32_quickfixengineering -computer $servers | ?{ $_.installedon }| sort @{e={[datetime]$_.InstalledOn}} | select -last 1 | select -ExpandProperty InstalledOn
}
$Results += New-object psobject -Property $Properties
} 
$Results | Select-Object NetBIOS_Name,Description,HotFixID, InstalledBy, InstalledOn | Export-csv -Path $save -NoTypeInformation

# Send Mail - Email Report
# Updated 4/7/2022
$Attachment= $save
$emailFrom = "pburkhardt@glfhc.org"  
$emailTo = "pburkhardt@glfhc.org"
$subject = "GLFHC Latest MS Update Report on $date from $ThisServer"  
$Body = "Please review the attached report and take corrective action, if needed..."
$smtpServer = "mail.glfhc.org"
#333333333[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)


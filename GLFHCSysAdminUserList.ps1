<#
# FileName:	SysAdminList.ps1
# Purpose:	Ths script scans all of the SQL user account on the SQL Servers listed in a text file.
#		It reports the roles at the server level.
#		It will identify and report all those users, by server, that have sysadmin privs.
#		This list should be reviewed to make sure that the "right" people have access.
#		Note: password was initially saved in an encrypted file by typing:
#			>read-host -assecurestring | convertfrom-securestring | out-file C:\Code\cred.txt
#		Once we have our password safely stored away, we can draw it back into our scripts..
#   		>$password = get-content C:\Code\cred.txt | convertto-securestring
#	Date        Author				description
# ----------    -------  ----------------------------------------------------
# 07/24/2020	 pb       Original Version
#>

$erroractionpreference = “SilentlyContinue” 
$a = New-Object -comobject Excel.Application 
$ThisServer = get-content env:computername
# Define Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring

# Make output invisible 
$a.visible = $False

$b = $a.Workbooks.Add() 
$c = $b.Worksheets.Item(1)


# Define Output FileName

$date = get-date -format "yyyyMMddHHmm"  
$save = "c:\output\SysAdminList_$date.xlsx"  

# Create Header

$c.Cells.Item(1,1) = “Server Name” 
$c.Cells.Item(1,2) = “SysAdmin User” 

$d = $c.UsedRange 
$d.Interior.ColorIndex = 19 
$d.Font.ColorIndex = 11 
$d.Font.Bold = $True 
$d.EntireColumn.AutoFit()

$intRow = 2

Import-Module SQLPS -disablenamechecking
 


#Read thru the contents of the SQL_Servers.txt file
foreach ($SQLSvr in get-content "c:\Code\JustServerNameList.txt")
{
	$c.Cells.Item($intRow, 1) = $SQLSvr.ToUpper() 
	$found = 0
TRY
 {
	#"Connecting to $SQLSvr" | Write-Host -ForegroundColor Blue

	$MySQL = new-object Microsoft.SqlServer.Management.Smo.Server $SQLSvr

	$SQLLogins = $MySQL.Logins

	$SysAdmins = $null

	$SysAdmins = foreach($SQLUser in $SQLLogins)
	
{
   
		foreach($role in $SQLUser.ListMembers())
    

		{
        
			if($role -match 'sysadmin')
        
			{
            # Set color according to group
			If (($($SQLUser.Name) -eq "sa") -or ($($SQLUser.Name) -eq "NT AUTHORITY\SYSTEM") -or ($($SQLUser.Name) -like "NT SERVICE*") -or ($($SQLUser.Name) -eq "BUILTIN\Administrators") -or ($($SQLUser.Name) -like "*MSSQLSERVER") -or ($($SQLUser.Name) -like "*SQLSERVERAGENT"))
			# SQL System Users
			{
				$fgColor = 4
			}
			ELSEIF (($($SQLUser.Name) -eq "GLFHC\*pburkhardt"))
			# DBA Users
			{
				$fgColor = 10
			}
			ELSE
			#Flag UnAuthorized SysAdmin Users
			{
				$fgColor = 3 
			}

			
			
				#Write-Host "SysAdmins found: $($SQLUser.Name)" -ForegroundColor Yellow

       				$c.Cells.Item($intRow, 2) = $($SQLUser.Name)
					$c.Cells.Item($intRow, 2).Interior.ColorIndex = $fgColor
					
				$intRow = $intRow + 1 
				$found = 1

			}

    		}
	
}

 }
catch
{

$c.Cells.Item($intRow, 2) = "Node Unreachable"
$intRow = $intRow + 1 
$found = 1

} 


# If no records found, increment counter
if ($found -eq 0)
{
	$intRow = $intRow + 1 
}

}

$d.EntireColumn.AutoFit()

$b.SaveAs($save)  
$a.quit()  

  
start-sleep -s 15  
$Attachment= $save
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"  
$subject = "GLFHC SysAdmin Listing for Critical Servers on $date from $ThisServer"  
$body = "See the log file is attached..." 
$smtpServer = "smtpmail.glfhc.local"
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)

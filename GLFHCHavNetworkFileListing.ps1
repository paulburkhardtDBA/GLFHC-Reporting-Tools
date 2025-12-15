<#
FileName: 	NetworkFileListing.ps1
Purpose:	This script was written to create a listing of all files that reside in the
			source directory as well as all of the sub-directories underneath it.
			The resuting CSV file will be examined and any unnecessary files will be 
			removed.  It's an effective way of keeping the drives clean of only files used.
			
Date		Author						Descrition
---------	------	-----------------------------------------------------
02/18/2021	peb			Original version


#>

# define local computername
$ThisServer = get-content env:computername

# Get Credential
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null;
$username = "pburkhardt"
$password = get-content C:\Code\passcred.txt | convertto-securestring

# define dates
$isodate=Get-Date -format s 
$isodate=$isodate -replace(":","")

# define source file
$Path = "\\hav-dr01\backup\SQLDirectBackup\"

# define output file
$Outfile = "C:\Output\NetworkFileListing_" + $isodate + ".txt"

# create directory listing

#$Object = Get-ChildItem $path -Recurse -Directory -Force -ErrorAction SilentlyContinue |Out-file $OutFile
$Objects  = Get-ChildItem $Path -Recurse  -include *.bak, *.trn | Select-Object FullName, CreationTime, @{N='SizeInKb';E={[double]('{0:N2}' -f ($_.Length/1kb))}} 
$Objects  |Export-csv $OutFile

# Send Email
$Attachment= $OutFile
$EmailTo = "pburkhardt@glfhc.org" 
$EmailFrom   = "pburkhardt@glfhc.org"  
$Subject = "The Hav-DR01 Network File Listing for $isodate from $ThisServer" 
$Body =  "Review the attached list and remove unneeded (*.bak or *.trn) filea..."
$SMTPServer  = "mail.glfhc.org"  
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Username, $password) 
$SMTPClient.Send($SMTPMessage)

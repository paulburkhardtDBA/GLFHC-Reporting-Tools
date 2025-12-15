<#
FileName:	Get-Last-Update.ps1
Purpose:	To cycle through each SQL instance and Report
			the last time the server was updated and what was done.

Date 		 Author						Description
----------	----------	----------------------------------------------------
08/08/2023	PEB			- Change output file to C:\Output directory
						- Add logicals to point to files
						- Mail results

1/27/25   WY   Change user/pw/dbmail to wyang
#>

#param([Parameter(Mandatory=$true)][string[]] $ComputerName,
#      [switch] $PSRemoting
#    )

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$StartTime = Get-Date
$date = get-date -format "yyyyMMddHHmm"  
$ThisServer = get-content env:computername

# Get Credentials
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
#$username = "pburkhardt"
#$password = get-content C:\Code\passcred.txt | convertto-securestring
#$username = "wyang"
#$password = get-content C:\Code\passcred_wy.txt | convertto-securestring

# Define Logicals
$HtmlFile = "C:\Output\last-updates-$date.html"
$HtmlError = "C:\Output\last-updates-errors-$date.html"
$CsvFile = "C:\Output\last-updates-$date.csv"
$CsvError = "C:\Output\last-updates-errors-$date.csv"

$StartTime = Get-Date

function ql { $args }

$LastUpdates = @{}
$Errors      = @{}

$ComputerName = get-content "C:\Code\JustServerNameList.txt"
$PSRemoting = 1

foreach ($Computer in $ComputerName | Where { $_ -match '\S' }) {
    
    # Write-Host -NoNewline -Fore Green "`rProcessing ${Computer}...                          "
    
    $script:ContinueFlag = $false
    
    if ( -not (Test-Connection -Quiet -Count 1 -ComputerName $Computer) ) {
        
        $Errors.$Computer = 'Error: No ping reply'
        continue
        
    }
    
    # Use "local COM" (well, local, but remote via PS) and Invoke-Command if PSRemoting is specified.
    if ($PSRemoting) {
        
        try {
            
            $Result = Invoke-Command -ComputerName $Computer -ErrorAction Stop -ScriptBlock {
                
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Update.Session') | Out-Null
                $Session = New-Object -ComObject Microsoft.Update.Session
                
                try {
                    
                    $UpdateSearcher   = $Session.CreateUpdateSearcher()
                    $NumUpdates       = $UpdateSearcher.GetTotalHistoryCount()
                    $InstalledUpdates = $UpdateSearcher.QueryHistory(1, $NumUpdates)
                    
                    if ($?) {
                        
                        $LastInstalledUpdate = $InstalledUpdates | Select-Object Title, Date | Sort-Object -Property Date -Descending | Select-Object -first 1
                        # Return a collection/array. Later it is assumed that an array type indicates success.
                        # Errors are of the class [System.String]. -- Well, that didn't work so well in retrospect.
                        $LastInstalledUpdate.Title, $LastInstalledUpdate.Date
                        
                    }
                    
                    else {
                        
                        "Error. Win update search query failed: $($Error[0] -replace '[\r\n]+')"
                        
                    }
                    
                } # end of inner try block
                
                catch {
                    
                    $Errors.$Computer = "Error (terminating): $($Error[0] -replace '[\r\n]+')"
                    continue
                    
                }
                
            } # end of Invoke-Command
            
        } # end of outer try block
        
        # Catch the Invoke-Command errors here
        catch {
            
            $Errors.$Computer = "Error with Invoke-Command: $($Error[0] -replace '[\r\n]+')"
            continue
            
        }
        
        # $Result here is what's returned from the invoke-command call.
        # I can't populate the data hashes inside the Invoke-Command due to variable scoping.
        if (-not $Result -is [array]) {
            
            $Errors.$Computer = $Result
            
        }
        
        else {
            
            $Title, $Date = $Result[0,1]
            
            $LastUpdates.$Computer = New-Object PSObject -Property @{
                
                'Title' = $Title
                'Date'  = $Date
                
            }
            
        }
        
    }
    
    # If -PSRemoting isn't provided as an argument, try remote COM.
    else {
        
        try {
            
            [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Update.Session')
            $Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session", $Computer))
        
            $UpdateSearcher   = $Session.CreateUpdateSearcher()
            $NumUpdates       = $UpdateSearcher.GetTotalHistoryCount()
            $InstalledUpdates = $UpdateSearcher.QueryHistory(1, $NumUpdates)
            
            if ($?) {
                
                $LastInstalledUpdate   = $InstalledUpdates | Select-Object Title, Date | Sort-Object -Property Date -Descending | Select-Object -first 1
                $LastUpdates.$Computer = New-Object PSObject -Property @{
                    
                    'Title' = $LastInstalledUpdate.Title
                    'Date'  = $LastInstalledUpdate.Date
                    
                }
                
            }
            
            else {
                
                $Errors.$Computer = "Error. Win update search query failed: $($Error[0].ToString())"
                
            }
            
        }
        
        catch {
            
            $Errors.$Computer = "Terminating error: $($Error[0].ToString())"
            
        }
        
    }
    
}

# Define properties for use with Select-Object
$Properties = 
    @{n='Server'; e={$_.Name}},
    @{n='Date';   e={$_.Value.Date}},
    @{n='Title';  e={$_.Value.Title}}

# Create HTML header used for both HTML reports.
$HtmlHead = @"
<title>Last Update Report ($(Get-Date -uformat %Y-%m-%d))</title>
<style type='text/css'>

    table        { width: 100%; border-collapse: collapse }
    td, th       { color: black; padding: 2px; }
    /* tr:nth-child(odd)  { background-color: #CCC }
    tr:nth-child(even) { background-color: #FFF } */
    th           { background-color: #C7C7C7; text-align: left }
    td           { background-color: #F7F7F7; text-align: left }
</style>
"@

## Create HTML data
# Create HTML body for updates report (successfully processed hosts)
$HtmlBody = $LastUpdates.GetEnumerator() | Sort -Property @{Expression={$_.Value.Date}; Ascending=$false},@{Expression={$_.Name}; Ascending=$true} |
    Select-Object -Property $Properties | ConvertTo-Html -Fragment
ConvertTo-Html -Head $HtmlHead -Body $HtmlBody | Set-Content $HtmlFile

# Creating new HTML Body for hosts with errors.
$HtmlBody = $null
$HtmlBody = $Errors.GetEnumerator() | Sort -Property Name | Select-Object Name,Value | ConvertTo-Html -Fragment
ConvertTo-Html -Head $HtmlHead -Body $HtmlBody | Set-Content $HtmlError

## Create CSV data
# Create last update CSV file
$LastUpdates.GetEnumerator() | Sort -Property @{Expression={$_.Value.Date}; Ascending=$false},@{Expression={$_.Name}; Ascending=$true} |
    Select-Object -Property $Properties | ConvertTo-Csv | Set-Content $CsvFile

# Create error CSV file
$Errors.GetEnumerator() | Sort -Property Name | Select-Object Name,Value |
    ConvertTo-Csv | Set-Content $CsvError

<# Comment out
@"

Error count:   $($Errors.Values.Count)
Success count: $($LastUpdates.Values.Count)
Total count:   $([int] $Errors.Values.Count + $LastUpdates.Values.Count)

Script start time: $StartTime
Script end time::  $(Get-Date)
HTML Output files: $HtmlFile, $HtmlError
CSV Output files:  $CsvFile, $CsvError

"@
#>

# Send Mail - Email Report
$Attachment= $CsvFile
#$emailFrom = "pburkhardt@glfhc.org"  
#$emailTo = "pburkhardt@glfhc.org"
$emailFrom = "wyang@glfhc.org"  
$emailTo = "wyang@glfhc.org"
$subject = "GLFHC Latest MS Update Report on $date from $ThisServer"  
$Body = "Please review the attached report and take corrective action, if needed..."
$smtpServer = "smtpmail.glfhc.local"
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body) 
$Attachment  = New-Object System.Net.Mail.Attachment($Attachment)
$SMTPMessage.Attachments.Add($Attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)
#$SMTPClient.EnableSsl = $true
#$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password) 
$SMTPClient.Send($SMTPMessage)
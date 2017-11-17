<#
Solution: Hydration Sharepoint
Purpose: Install SharePoint Server 2013 SP1
Version: 1.0 - 2014

Author - Jérôme Bezet-Torres
#>
Function Write-trace
{
	
	#Define and validate parameters
	[CmdletBinding()]
	Param (
		#Path to the log file
		[parameter(Mandatory = $True)]
		[String]$NewLog,
		#The information to log

		[parameter(Mandatory = $True)]
		[String]$Value,
		#The source of the error

		[parameter(Mandatory = $True)]
		[String]$Component,
		#The severity (1 - Information, 2- Warning, 3 - Error)

		[parameter(Mandatory = $True)]
		[ValidateRange(1, 3)]
		[Single]$Severity
	)
	
	
	#Obtain UTC offset
	$DateTime = New-Object -ComObject WbemScripting.SWbemDateTime
	$DateTime.SetVarDate($(Get-Date))
	$UtcValue = $DateTime.Value
	$UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21)
	
	
	#Create the line to be logged
	$LogLine = "<![LOG[$Value]LOG]!>" +`
	"<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
	"date=`"$(Get-Date -Format M-d-yyyy)`" " +`
	"component=`"$Component`" " +`
	"context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
	"type=`"$Severity`" " +`
	"thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
	"file=`"`">"
	
	#Write the line to the passed log file
	Add-Content -Path $NewLog -Value $LogLine
	
}

# Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")
$logFile = "$logPath\$($myInvocation.MyCommand).log"

# Start the logging 
Write-trace -NewLog $logFile -Value "Logging to $logFile" -Component Main -Severity 1

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Install Sharepoint Server" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Write-trace -NewLog $logFile -Value "Personalize Config XML File" -Component Main -Severity 1
$productKey = "NQGJR-63HC8-XCRQH-MYVCH-3J3QR" # Sharepoint 2016 Entreprise Trial Key / RTNGH-MQRV6-M3BWQ-DB748-VH7DM Standart Trial Key
$spLocalPath = "C:\Scripts\"
$LigneF = '</Configuration> '
$InstallLocation = '        <INSTALLLOCATION Value="e:\Program Files\Microsoft Office Servers\16.0" />'
$DATADIR = '        <DATADIR Value="e:\Program Files\Microsoft Office Servers\Data" />'
$spConfigFile = $spLocalPath + "config.xml"
New-Item -ItemType Directory -Force -Path $spLocalPath
Copy-Item "D:\Deploy\Applications\Install - Sharepoint Server\source\files\setupfarmsilent\config.xml" $spLocalPath
$configContent = [io.file]::ReadAllText($spConfigFile)
Get-ChildItem $spConfigFile -Recurse |
Where-Object { $_.GetType().ToString() -eq "System.IO.FileInfo" } |
Set-ItemProperty -Name IsReadOnly -Value $false
$configContent = $configContent -Replace "<!--", ""
$configContent = $configContent -Replace "-->", ""
$configContent = $configContent -Replace "Enter Product Key Here", $productKey
$configContent = $configContent -Replace """none""", """basic"""
$configContent = $configContent -replace 'CompletionNotice="no"', 'CompletionNotice="No" AcceptEula="Yes"'
$configContent = $configContent -Replace "</Configuration>", $InstallLocation
$configContent | Out-File $spConfigFile
$DATADIR | Add-Content -Path $spConfigFile
$LigneF | Add-Content -Path $spConfigFile

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Disable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $true

# Start Installation
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Starting Install SQL Server" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

$exe = "D:\Deploy\Applications\Install - Sharepoint Server\source\setup.exe"
$myargs = "/config  $spLocalPath\config.xml"

Write-trace -NewLog $logFile -Value "Start Install of Sharepoint Server " -Component Main -Severity 1


Start-process $exe -ArgumentList $myargs

$i = 0
Do
{
	
	$i++
	if ($i -eq 1)
	{
		Write-Host "~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Green
		Write-Host "Install begin....." -ForegroundColor Green
		Write-Host "~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Green
		
		Start-Sleep 15
	}
	else
	{
		Write-Host ..... -NoNewline -ForegroundColor Yellow
		Start-Sleep 25
		
	}
	
}
While (Get-Process -Name setup -ErrorAction SilentlyContinue)
Write-Host "Install Finished ..... !" -ForegroundColor Green
Stop-Process -Name psconfigui -Force

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Enable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $false


Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging..." -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


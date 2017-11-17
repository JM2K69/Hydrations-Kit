<#
Solution: Hydration Sharepoint
Purpose: Install SharePoint prerequis
Version: 1.2 - 2017


	This script is provided "AS IS" with no warranties, confers no rights and 
	is not supported by the author. 

    Author - Jérôme Bezet-Torres
    Twitter: @JM2K69
    
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
Write-trace -NewLog $logFile -Value "Configure - Prerequis For Sharepoint" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

$SPbits = "e:\Install"
$Sources = "D:\Deploy\Applications\Install - Sharepoint prerequisites\"
$files = Get-ChildItem -Path $Sources
New-Item -ItemType Directory -Force -Path $SPbits | Out-Null

foreach ($item in $files.name)
{
	Write-Host $SPbits\$item
	Copy-Item -Path $Sources$item -Destination "$SPbits\$item"
	Write-trace -NewLog $logFile -Value "Copying the File $Sources$item to $SPbits" -Component Main -Severity 1
	
}
# Install Prerequis for Sharepoint Server 2016

$Arguments = "/unattended /SQLNCli:$SPbits\sqlncli.msi /Sync:$SPbits\Synchronization.msi /AppFabric:$SPbits\WindowsServerAppFabricSetup_x64.exe /IDFX11:$SPbits\MicrosoftIdentityExtensions-64.msi /MSIPCClient:$SPbits\setup_msipc_x64.exe /KB3092423:$SPbits\AppFabric-KB3092423-x64-ENU.exe /WCFDataServices56:$SPbits\WcfDataServices.exe /ODBC:$SPbits\msodbcsql.msi /DotNetFx:$SPbits\NDP46-KB3045557-x86-x64-AllOS-ENU.exe /MSVCRT11:$SPbits\vcredist_x64.exe /MSVCRT14:$SPbits\vc_redist.x64.exe"

Write-trace -NewLog $logFile -Value "Starting Configuration..." -Component Main -Severity 1

Start-Process "$SPbits\PrerequisiteInstaller.exe" -ArgumentList $Arguments -wait

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End scripting" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


# Stop logging 
Stop-Transcript


<#
	Solution HydrationKit
	Action : Configure - MDTIntegrationSCCM
    Created:	 2017-02-1
    Version:	 1.1

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


# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Write-trace -NewLog $logFile -Value "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script." -Component Main -Severity 2
	Write-trace -NewLog $logFile -Value "Aborting script..." -Component Main -Severity 2
    Throw
}
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Integrate MDT with ConfigMgr" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

# Integrate MDT with ConfigMgr
$SiteServer = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
$SiteCode = (Get-WmiObject -ComputerName $SiteServer -Namespace "root\SMS" -Class "SMS_ProviderLocation").SiteCode
$MDTInstallDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Deployment 4' -Name Install_Dir).Install_Dir

Write-trace -NewLog $logFile -Value "Running script on the SiteServer $SiteServer with the Site Code $SiteCode" -Component Main -Severity 1

# Getting CM console installation folder via registry, because the $env:SMS_ADMIN_UI_PATH method requires console to be started once
$CMConsoleInstallDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Setup' -Name 'UI Installation Directory').'UI Installation Directory'
$MOF  = "$CMConsoleInstallDir\Bin\Microsoft.BDD.CM12Actions.mof"

Copy-Item "$MDTInstallDir\Bin\Microsoft.BDD.CM12Actions.dll" "$CMConsoleInstallDir\Bin\Microsoft.BDD.CM12Actions.dll"
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Bin\Microsoft.BDD.CM12Actions.dll" "to" "$CMConsoleInstallDir\Bin\Microsoft.BDD.CM12Actions.dll" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\Bin\Microsoft.BDD.Workbench.dll" "$CMConsoleInstallDir\Bin\Microsoft.BDD.Workbench.dll"
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Bin\Microsoft.BDD.Workbench.dll" "to" "$CMConsoleInstallDir\Bin\Microsoft.BDD.Workbench.dll" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\Bin\Microsoft.BDD.ConfigManager.dll" "$CMConsoleInstallDir\Bin\Microsoft.BDD.ConfigManager.dll"
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Bin\Microsoft.BDD.ConfigManager.dll" "to" "$CMConsoleInstallDir\Bin\Microsoft.BDD.ConfigManager.dll" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\Bin\Microsoft.BDD.CM12Wizards.dll" "$CMConsoleInstallDir\Bin\Microsoft.BDD.CM12Wizards.dll"
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Bin\Microsoft.BDD.CM12Wizards.dll" "to" "$CMConsoleInstallDir\Bin\Microsoft.BDD.CM12Wizards.dll" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\Bin\Microsoft.BDD.PSSnapIn.dll" "$CMConsoleInstallDir\Bin\Microsoft.BDD.PSSnapIn.dll"
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Bin\Microsoft.BDD.PSSnapIn.dll" "to" "$CMConsoleInstallDir\Bin\Microsoft.BDD.PSSnapIn.dll" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\Bin\Microsoft.BDD.Core.dll" "$CMConsoleInstallDir\Bin\Microsoft.BDD.Core.dll"
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Bin\Microsoft.BDD.Core.dll" "to" "$CMConsoleInstallDir\Bin\Microsoft.BDD.Core.dll" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\SCCM\Microsoft.BDD.CM12Actions.mof" $MOF
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\SCCM\Microsoft.BDD.CM12Actions.mof to $MOF" -Component Main -Severity 1

Copy-Item "$MDTInstallDir\Templates\CM12Extensions\*" "$CMConsoleInstallDir\XmlStorage\Extensions\" -Force -Recurse
Write-Trace -Message  -Type Information -Logfile $logFile
Write-trace -NewLog $logFile -Value "Copying $MDTInstallDir\Templates\CM12Extensions\*" "to" "$CMConsoleInstallDir\XmlStorage\Extensions\" -Component Main -Severity 1

(Get-Content $MOF).Replace('%SMSSERVER%', $SiteServer).Replace('%SMSSITECODE%', $SiteCode) | Set-Content $MOF | Out-Null
& "C:\Windows\System32\wbem\mofcomp.exe" "$CMConsoleInstallDir\Bin\Microsoft.BDD.CM12Actions.mof" | Out-Null

# Stop logging 
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


<#
	Solution HydrationKit
	Action : Config - WSUS   
    Created:	 2016-02-1
    Version:	 1.0

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
$logPath = "$env:USERPROFILE\Desktop"
$logFile = "$logPath\$($myInvocation.MyCommand).log"

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Config WSUS Server With SQL " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Disable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $true

#Get WSUS Server Object
$wsus = Get-WSUSServer
Write-trace -NewLog $logFile -Value "Server WSUS is $wsus" -Component Main -Severity 1
#Connect to WSUS server configuration
$wsusConfig = $wsus.GetConfiguration()

#Set to download updates from Microsoft Updates
Write-trace -NewLog $logFile -Value "Synchronization with Windows Update" -Component Main -Severity 1

Set-WsusServerSynchronization –SyncFromMU

#Set Update Languages to English and save configuration settings

$wsusConfig.AllUpdateLanguagesEnabled = $false
Write-trace -NewLog $logFile -Value "Activate French" -Component Main -Severity 1

$wsusConfig.SetEnabledUpdateLanguages("fr")
Write-trace -NewLog $logFile -Value "Activate Express Install" -Component Main -Severity 1
$wsusConfig.DownloadExpressPackages = $true
$wsusConfig.Save()



#Get WSUS Subscription and perform initial synchronization to get latest categories

$subscription = $wsus.GetSubscription()

$subscription.StartSynchronizationForCategoryOnly()



While ($subscription.GetSynchronizationStatus() -ne 'NotProcessing')
{
	
	Write-Host "....." 
	
	Start-Sleep -Seconds 25
	
}

Write-Host "Sync is done."

Write-trace -NewLog $logFile -Value "Remove All Product" -Component Main -Severity 1

Get-WsusProduct | Set-WsusProduct -Disable

Get-WsusProduct | where-Object {
	
	$_.Product.Title -in (
		
		'Windows 10',
		
		'Windows 10 Anniversary Update Server and Later Servicing Drivers',
		
		'Windows Server 2012 R2',
		
		'Windows Server 2016')
	
} | Set-WsusProduct

Write-trace -NewLog $logFile -Value "Set Product Window 10, 2012R2 and Server 2016" -Component Main -Severity 1


#Configure the Classifications

Get-WsusClassification | Where-Object {
	
	$_.Classification.Title -in (
		
		'Update Rollups',
		
		'Security Updates',
		
		'Critical Updates',
		
		'Service Packs',
		
		'Updates')
	
} | Set-WsusClassification



#Configure Synchronizations

$subscription.SynchronizeAutomatically = $true

#Set synchronization scheduled for midnight each night

$subscription.SynchronizeAutomaticallyTimeOfDay = (New-TimeSpan -Hours 0)

$subscription.NumberOfSynchronizationsPerDay = 1

$subscription.Save()


#Kick off a synchronization
Write-trace -NewLog $logFile -Value "Start Synchronization" -Component Main -Severity 1

$subscription.StartSynchronization()




Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Enable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $false


Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


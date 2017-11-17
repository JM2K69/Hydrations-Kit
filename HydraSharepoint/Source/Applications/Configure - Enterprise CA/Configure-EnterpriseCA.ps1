<#
	Solution HydrationKit
	Action : Configure - CA Entreprise
    Created:	 2017-08-4
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
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("LogPath") 
$logFile = "$logPath\$($myInvocation.MyCommand).log"

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "EntrepriseCA" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


#Get-Info
$info=get-addomain
$infoC=$info.DNSRoot
$split=$infoC.split(".")
$domain=$split[0]
$Ext = $split[1]
$key = "2048"
$HashAlgorithm = "SHA256"
$ValidityPeriod = "5"


Write-trace -NewLog $logFile -Value "================================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "The Root authority will create with the name $domain`RootCA" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "With this parameter : " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Key : $key " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "HashAlgorithm : $HashAlgorith" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Validity : $ValidityPeriod Years" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


# Configure Enterprise CA
Install-AdcsCertificationAuthority `
    –CAType EnterpriseRootCA `
    –CACommonName "$domain`RootCA" `
    –KeyLength $key `
    –HashAlgorithm $HashAlgorithm `
    –CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -ValidityPeriod Years `
    -ValidityPeriodUnits $ValidityPeriod `
    -Force

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


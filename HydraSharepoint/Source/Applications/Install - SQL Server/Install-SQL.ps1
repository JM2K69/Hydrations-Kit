<#
	Solution HydrationKit
	Action : Install - SQL Server  
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
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")
$logFile = "$logPath\$($myInvocation.MyCommand).log"

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Install SQL Server" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

$info = get-addomain
$infoC = $info.DNSRoot
$Rdomain = ""
$split = $infoC.split(".")
$nb = $split.Count

switch ($nb)
{
	2{
		
		$domain1 = $split[0]
		$Ext1 = $split[1]
		$Rdomain1 = "$domain1.$ext1"
		$UserDomain = $domain1.ToUpper() + "\" + $env:USERNAME
	}
	3{
		$sdomain = $split[0]
		$domain = $split[1]
		$Ext = $split[2]
		
		$Rdomain2 = "$sdomain.$domain.$ext"
		$UserDomain = $domain.ToUpper() + "\" + $env:USERNAME
	}
}
$SQLINSTANCENAME = "MSSQLSERVER"
$domain = (Get-ADDomain).NetBIOSName
$AdminShare = "$domain\AdminShare"
$Account = $UserDomain + '"' + " " + '"' + $AdminShare
$unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
set-Content $unattendFile "[OPTIONS]"
Add-Content $unattendFile "ACTION=""Install"""
Add-Content $unattendFile "SUPPRESSPRIVACYSTATEMENTNOTICE=""False"""
Add-Content $unattendFile "IACCEPTROPENLICENSETERMS=""False"""
Add-Content $unattendFile "ENU=""True"""
Add-Content $unattendFile "QUIET=""True"""
Add-Content $unattendFile "QUIETSIMPLE=""False"""
Add-Content $unattendFile "UpdateEnabled=""True"""
Add-Content $unattendFile "USEMICROSOFTUPDATE=""False"""
Add-Content $unattendFile "FEATURES=""SQLENGINE,""FULLTEXT"""
Add-Content $unattendFile "UpdateSource=""MU"""
Add-Content $unattendFile "HELP=""False"""
Add-Content $unattendFile "INDICATEPROGRESS=""False"""
Add-Content $unattendFile "X86=""False"""
Add-Content $unattendFile "INSTANCENAME=""$SQLINSTANCENAME"""
Add-Content $unattendFile "INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server"""
Add-Content $unattendFile "INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server"""
Add-Content $unattendFile "INSTANCEID=""$SQLINSTANCENAME"""
Add-Content $unattendFile "SQLTELSVCACCT=""NT Service\SQLTELEMETRY"""
Add-Content $unattendFile "SQLTELSVCSTARTUPTYPE=""Automatic"""
Add-Content $unattendFile "INSTANCEDIR=""c:\Program Files\Microsoft SQL Server"""
Add-Content $unattendFile "AGTSVCACCOUNT=""NT Service\SQLSERVERAGENT"""
Add-Content $unattendFile "AGTSVCSTARTUPTYPE=""Automatic"""
Add-Content $unattendFile "COMMFABRICPORT=""0"""
Add-Content $unattendFile "COMMFABRICNETWORKLEVEL=""0"""
Add-Content $unattendFile "COMMFABRICENCRYPTION=""0"""
Add-Content $unattendFile "MATRIXCMBRICKCOMMPORT=""0"""
Add-Content $unattendFile "SQLSVCSTARTUPTYPE=""Automatic"""
Add-Content $unattendFile "FILESTREAMLEVEL=""2"""
Add-Content $unattendFile "FILESTREAMSHARENAME=""$SQLINSTANCENAME"""
Add-Content $unattendFile "ENABLERANU=""False"""
Add-Content $unattendFile "SQLCOLLATION=""French_CI_AS"""
Add-Content $unattendFile "SQLSVCACCOUNT=""NT Service\MSSQLSERVER"""
Add-Content $unattendFile "SQLSVCINSTANTFILEINIT=""False"""
Add-Content $unattendFile "SQLSYSADMINACCOUNTS=""$Account"""
Add-Content $unattendFile "SQLTEMPDBFILECOUNT=""1"""
Add-Content $unattendFile "SQLTEMPDBFILESIZE=""8"""
Add-Content $unattendFile "SQLTEMPDBFILEGROWTH=""64"""
Add-Content $unattendFile "SQLTEMPDBLOGFILESIZE=""8"""
Add-Content $unattendFile "SQLTEMPDBLOGFILEGROWTH=""64"""
Add-Content $unattendFile "SQLBACKUPDIR=""e:\SQLBackup"""
Add-Content $unattendFile "SQLUSERDBDIR=""e:\SQLData"""
Add-Content $unattendFile "SQLUSERDBLOGDIR=""e:\SQLLogs"""
Add-Content $unattendFile "SQLTEMPDBDIR=""E:\SQLTemp"""
Add-Content $unattendFile "ADDCURRENTUSERASSQLADMIN=""False"""
Add-Content $unattendFile "TCPENABLED=""1"""
Add-Content $unattendFile "NPENABLED=""0"""
Add-Content $unattendFile "BROWSERSVCSTARTUPTYPE=""Automatic"""
Add-Content $unattendFile "FTSVCACCOUNT=""NT Service\MSSQLFDLauncher"""
Add-Content $unattendFile "IACCEPTSQLSERVERLICENSETERMS=""True"""


$exe = "D:\Deploy\Applications\Install - SQL Server\source\setup.exe"
$myargs = "/Configurationfile=$unattendFile"

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Disable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $true

# Start Installation
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Starting Install SQL Server" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Start-process $exe -ArgumentList $myargs -Wait

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Finished Install SQL Server" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Enable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $false

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


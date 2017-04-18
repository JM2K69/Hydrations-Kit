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

$info=get-addomain
$infoC=$info.DNSRoot
$Rdomain=""
$split=$infoC.split(".")
$nb=$split.Count

  switch ($nb)
  {
      2{

        $domain1=$split[0]
        $Ext1=$split[1]
        $Rdomain1= "$domain1.$ext1"
        $UserDomain=$domain1+"\"+$env:USERNAME
        }
      3{
        $sdomain=$split[0]
        $domain=$split[1]
        $Ext=$split[2]

        $Rdomain2="$sdomain.$domain.$ext"
        $UserDomain=$domain+"\"+$env:USERNAME
    }
  }

$LocalPath = "C:\Scripts\"
$INSTALLSHAREDDIR='INSTALLSHAREDDIR="e:\Program Files\Microsoft SQL Server"'
$SQLSYSADMINACCOUNTS="SQLSYSADMINACCOUNTS=$UserDomain"
$ConfigFile = $LocalPath + "ConfigurationFileConfigurationManager.ini"
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Modify ConfigurationFile.ini " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "With the parameter :" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Installation Path: $INSTALLSHAREDDIR" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "SQL Administrator : $SQLSYSADMINACCOUNTS" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "In the File : $ConfigFile " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

New-Item -ItemType Directory -Force -Path $LocalPath
Copy-Item "D:\Deploy\Applications\Install - SQL Server\ConfigurationFileConfigurationManager.ini" $LocalPath
$configContent =[io.file]::ReadAllText($ConfigFile)
Get-ChildItem $ConfigFile -Recurse |
Where-Object {$_.GetType().ToString() -eq "System.IO.FileInfo"} |
Set-ItemProperty -Name IsReadOnly -Value $false
$configContent = $configContent -Replace 'INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"', $INSTALLSHAREDDIR
$configContent = $configContent -Replace 'SQLSYSADMINACCOUNTS="VIAMONSTRA\\Administrator"', $SQLSYSADMINACCOUNTS
$configContent | Out-File $ConfigFile

$exe = "D:\Deploy\Applications\Install - SQL Server\source\setup.exe"
$myargs = "/Configurationfile=$ConfigFile"

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


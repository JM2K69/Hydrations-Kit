<#
	Solution HydrationKit
	Action : Authorize - DHCP
   Created:	 2017-04-02
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

# Start the logging 
Write-trace -NewLog $logFile -Value "Logging to $logFile" -Component Main -Severity 1


$Interface = Get-NetAdapter -Name Ethernet0
$IFindex = Get-NetIPAddress -InterfaceIndex $Interface.ifIndex -AddressFamily IPv4
$IP = $IFindex.IPv4Address
Write-trace -NewLog $logFile -Value "The DHCP Server have $IP address" -Component Main -Severity 1

    # Authorize DHCP SERVER
      Add-DhcpServerInDC -DnsName $env:COMPUTERNAME -IPAddress $IP
	Write-trace -NewLog $logFile -Value "The Server with the name $env:COMPUTERNAME is Authorize in Active Directory" -Component Main -Severity 1

	# Server Manager will be Happy  remove Flag AD and DHCP

	set-ItemProperty HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -name ConfigurationState -Value 0x000000002
	set-ItemProperty HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\10 -name ConfigurationStatus -Value 0x000000002
	Write-Trace -Message "Remove AD and DHCP Flag in Server Manager" -Logfile $logFile -Type Information
	Write-trace -NewLog $logFile -Value "Remove AD and DHCP Flag in Server Manager" -Component Main -Severity 1

# Stop logging 
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End scripting" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


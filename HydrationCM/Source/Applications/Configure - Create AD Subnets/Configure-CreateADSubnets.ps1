<#
	Solution HydrationKit
	Action : Configure - AD Subnets
    Created:	 2017-08-04
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
Write-trace -NewLog $logFile -Value "Configure ADSubnet" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

$Sites=(Get-ADForest).sites
$netlocal = get-wmiobject win32_networkadapterconfiguration | where { $_.ipenabled -eq "true" }

$ip = "$($netlocal.ipaddress)"
$ip = $ip.split()
$ip = $ip[0]
$masque = "$($netlocal.ipsubnet)"
$ip = $ip.split('.')
$masque2 = $masque.split('.')

$a = $ip[0] -band $masque2[0]
$b = $ip[1] -band $masque2[1]
$c = $ip[2] -band $masque2[2]
$d = $ip[3] -band $masque2[3]

#Network Address
$netaddr = "$a.$b.$c.$d"
#Network subnet
$1 = "128.0.0.0"
$2 = "192.0.0.0"
$3 = "224.0.0.0"
$4 = "240.0.0.0"
$5 = "248.0.0.0"
$6 = "252.0.0.0"
$7 = "254.0.0.0"
$8 = "255.0.0.0"
$9 = "255.128.0.0"
$10 = "255.192.0.0"
$11 = "255.224.0.0"
$12 = "255.240.0.0"
$13 = "255.248.0.0"
$14 = "255.252.0.0"
$15 = "255.254.0.0"
$16 = "255.255.0.0"
$17 = "255.255.128.0"
$18 = "255.255.192.0"
$19 = "255.255.224.0"
$20 = "255.255.240.0"
$21 = "255.255.248.0"
$22 = "255.255.252.0"
$23 = "255.255.254.0"
$24 = "255.255.255.0"
$25 = "255.255.255.128"
$26 = "255.255.255.192"
$27 = "255.255.255.224"
$28 = "255.255.255.240"
$29 = "255.255.255.248"
$30 = "255.255.255.252"
#Convert to CIDR
switch ($masque)
{
	$1 {
		$prefix = "/1"
	}
	$2 {
		$prefix = "/2"
	}
	$3 {
		$prefix = "/3"
	}
	$4 {
		$prefix = "/4"
	}
	$5 {
		$prefix = "/5"
	}
	$6 {
		$prefix = "/6"
	}
	$7 {
		$prefix = "/7"
	}
	$8 {
		$prefix = "/8"
	}
	$9 {
		$prefix = "/9"
	}
	$10 {
		$prefix = "/10"
	}
	$11 {
		$prefix = "/11"
	}
	$12 {
		$prefix = "/12"
	}
	$13 {
		$prefix = "/13"
	}
	$14 {
		$prefix = "/14"
	}
	$15 {
		$prefix = "/15"
	}
	$16 {
		$prefix = "/16"
	}
	$17 {
		$prefix = "/17"
	}
	$18 {
		$prefix = "/18"
	}
	$19 {
		$prefix = "/19"
	}
	$20 {
		$prefix = "/20"
	}
	$21 {
		$prefix = "/21"
	}
	$22 {
		$prefix = "/22"
	}
	$23 {
		$prefix = "/23"
	}
	$24 {
		$prefix = "/24"
	}
	$25 {
		$prefix = "/25"
	}
	$26 {
		$prefix = "/26"
	}
	$27 {
		$prefix = "/27"
	}
	$28 {
		$prefix = "/28"
	}
	$29 {
		$prefix = "/29"
	}
	$30 {
		$prefix = "/30"
	}
}
$FSites=$sites[0]
$name = $netaddr + $prefix
# Create AD Subnets 

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create the Subnet $name for the AD Site $FSites" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

New-ADReplicationSubnet -Name $name -Site $FSites

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1



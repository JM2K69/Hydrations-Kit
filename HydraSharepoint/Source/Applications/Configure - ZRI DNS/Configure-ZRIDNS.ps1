<#
	Solution HydrationKit
	Action : Configure - Reverse DNS Zone 
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


###Declaration Variables###

$a = Get-NetIPAddress -InterfaceAlias Ethernet* -AddressFamily IPv4
$IP=$a.IPAddress
$IPv4=$IP.split(".")
$IP1=$IPV4[0]
$IP2=$IPV4[1]
$IP3=$IPV4[2]
$IP4=$IPV4[3]
$info=get-addomain
$FQDN=$info.DNSRoot
$split=$FQDN.split(".")
$domain=$split[0]
$Ext=$split[1]
$zone= $info.Forest
$SRVDNS=$info.InfrastructureMaster
$records2 = New-Object System.Collections.ArrayList
$Netbios=$SRVDNS.Split(".")
$NetbiosDC=$Netbios[0]

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Configure DNS Reverse Zone" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Informations :" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "@IPv4: $IP" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "FQDN: $FQDN" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Zone DNS: $zone" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "DNS Server: $Netbios" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Domain Controller: $NetbiosDC" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


###Fin Variables###

$networkID = "$IP1.$IP2.$IP3.0/24"
$test1= Get-DnsServerZone -ComputerName $NetbiosDC
# Crétaion des Zones de recherches inversées

if ($test1.ZoneName -contains "$IP3.$IP2.$IP1.in-addr.arpa")
{
	Write-trace -NewLog $logFile -Value "DNS Zone Already exist"  -Component Main -Severity 1
	
}
else
{
	Add-DnsServerPrimaryZone -NetworkID $networkID -ZoneFile "$IP3.$IP2.$IP1.in-addr.arpa.dns" -ComputerName $NetbiosDC
	Write-trace -NewLog $logFile -Value "Create the Reverse Zone for the network $networkID with the name $IP3.$IP2.$IP1.in-addr.arpa.dns " -Component Main -Severity 1
	
}

# Ajout des enregistrements PTR

$records = Get-DnsServerResourceRecord -ZoneName $zone -ComputerName $SRVDNS -RRType A 
foreach ($item in $records)
{
    
    if(!$item.HostName.Equals("@") -and !$item.HostName.Equals("DomainDnsZones")-and !$item.HostName.Equals("ForestDnsZones")){

        $records2.Add($item)|Out-Null
    }
}


foreach ($item in $records2)
{
$info=get-addomain
$FQDN=$info.DNSRoot
$PTR = $item.HostName
$IPO4= $item.RecordData
$t=$ipo4.IPv4Address
$IPN4=$t.IPAddressToString.Split(".")
$octet4 = $IPN4[3]
$test2= Get-DnsServerResourceRecord -ZoneName "$IP3.$IP2.$IP1.in-addr.arpa" -ComputerName $SRVDNS -RRType Ptr
    if ($test2 -eq $null)
        {
     Add-DnsServerResourceRecordPtr -Name "$octet4" -ZoneName "$IP3.$IP2.$IP1.in-addr.arpa"   -PtrDomainName "$PTR.$FQDN"  -ComputerName $NetbiosDC
		Write-trace -NewLog $logFile -Value "Create the PTR record $octet4 in the Zone $IP3.$IP2.$IP1.in-addr.arpa with the FQDN $PTR.$FQDN" -Component Main -Severity 1
		
		}
    elseif ($test2.HostName -eq $octet4)
        {
		Write-trace -NewLog $logFile -Value "PTR Record Already Exist" -Component Main -Severity 2
		
        }
        else 
        {
         Add-DnsServerResourceRecordPtr -Name "$octet4" -ZoneName "$IP3.$IP2.$IP1.in-addr.arpa"   -PtrDomainName "$PTR.$FQDN"  -ComputerName $NetbiosDC
		Write-trace -NewLog $logFile -Value "Create the PTR record $octet4 in the Zone $IP3.$IP2.$IP1.in-addr.arpa with the FQDN $PTR.$FQDN" -Component Main -Severity 1
		
	}
  
    
}

# Stop logging 
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

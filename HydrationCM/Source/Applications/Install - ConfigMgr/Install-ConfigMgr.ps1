<#
	Solution HydrationKit
	Action : Install - ConfigMgr Curent Branch 
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
Write-trace -NewLog $logFile -Value "Install ConfigMgr" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

$info=get-addomain
$infoC=$info.DNSRoot
function get-UPN ($param1)
{
$Rdomain=""
$split=$param1.split(".")
$nb=$split.Count

  switch ($nb)
  {
      2{

        $domain1=$split[0]
        $Ext1=$split[1]
        $Rdomain= "$domain1.$ext1"

        return $Rdomain}
      3{
        $sdomain=$split[0]
        $domain=$split[1]
        $Ext=$split[2]

        $Rdomain="$sdomain.$domain.$ext"

    return $Rdomain}
  }
}

$dom = get-UPN $infoC

#Variables
$DB = $dom.split('.')
$DB[1]
$SiteCode = $DB[1].ToUpper()
$LocalPath = "C:\Scripts\"
$SDKServer="SDKServer=$env:computername.$dom"
$ManagementPoint="ManagementPoint=$env:computername.$dom"
$DistributionPoint="ManagementPoint=$env:computername.$dom"
$SQLServerName="SQLServerName=$env:computername.$dom"
$CloudConnectorServer="CloudConnectorServer=$env:computername.$dom"
$Database = "DatabaseName = CM_$DB"
$SiteCode = "SiteCode = $SiteCode"
$ConfigFile = $LocalPath + "ConfigMgrUnattend.ini"

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Modify ConfigMgrUnattend.ini" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "With the parameter :" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "SDK Server : $SDKServer " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "ManagementPoint : $ManagementPoint" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "DistributionPont : $DistributionPoint" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "CloudConnecterServer : $CloudConnectorServer" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "DatabaseName : $Database" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "SiteCode : $SiteCode" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "In the File : $ConfigFile " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


New-Item -ItemType Directory -Force -Path $LocalPath
Copy-Item "D:\Deploy\Applications\Install - ConfigMgr\ConfigMgrUnattend.ini" $LocalPath
$configContent =[io.file]::ReadAllText($ConfigFile)
Get-ChildItem $ConfigFile -Recurse |
Where-Object {$_.GetType().ToString() -eq "System.IO.FileInfo"} |
Set-ItemProperty -Name IsReadOnly -Value $false
$configContent = $configContent -Replace 'SDKServer=CM01.corp.viamonstra.com', $SDKServer
$configContent = $configContent -Replace 'ManagementPoint=CM01.corp.viamonstra.com', $ManagementPoint
$configContent = $configContent -Replace 'DistributionPoint=CM01.corp.viamonstra.com', $DistributionPoint
$configContent = $configContent -Replace 'SQLServerName=CM01.corp.viamonstra.com', $SQLServerName
$configContent = $configContent -Replace 'CloudConnectorServer=CM01.corp.viamonstra.com', $CloudConnectorServer
$configContent = $configContent -Replace 'DatabaseName=CM_ENI', $Database
$configContent = $configContent -replace 'SiteCode=ENI',$SiteCode
$configContent | Out-File $ConfigFile

# Workaround for bug in ConfigMgr / MDT 2013 Update 1, where ConfigMgr setup deletes the registry info the MDT task sequence needs
# reg export HKLM\SOFTWARE\Microsoft\SMS C:\Windows\Temp\TS.reg

$exe = "D:\Deploy\Applications\Install - ConfigMgr\source\SMSSETUP\BIN\X64\setup.exe"
$myargs = "/Script $ConfigFile /NoUserInput"

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Disable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $true

# Start Installation
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Starting Install ConfigMgr CB" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


Start-process $exe -ArgumentList $myargs -Wait


Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Finished Install ConfigMgr CB" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Enable Windows Defender Real-Time Protection" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Set-MpPreference -DisableRealtimeMonitoring $false



# Workaround for bug in ConfigMgr / MDT 2013 Update 1, where ConfigMgr setup deletes the registry info the MDT task sequence needs
#$cmd= "regedit /s C:\Windows\Temp\TS.reg"
#Invoke-Expression $cmd | Out-Null

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

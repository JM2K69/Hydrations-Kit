<#
Solution: Hydration Sharepoint
Purpose: Configure - SQL Administration Central
Version: 1.0 - 2017

Author - Jérôme Bezet-Torres
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
function Get-OsCulture
{
	[CmdletBinding()]
	param ()
	
	$oscode = Get-WmiObject Win32_OperatingSystem -ComputerName localhost -ErrorAction continue | foreach { $_.oslanguage }
	$Culture = switch ($oscode) `
	{
		1033 { "English" };
		1036 { "French" };
		default { "Unknown" }
	}
	
	switch ($Culture)
	{
		'French' {
			$AdminAccount = "Administrateur"
			$AdminGroupsAccount = "Administrateurs"
			$AdminDomaintGroupsAccount = "Admins du domaine"
			$OsCulture = "French"
			return $AdminAccount, $AdminGroupsAccount, $AdminDomaintGroupsAccount, $OsCulture
			
			
		}
		{ 'English' } {
			$AdminAccount = "Administrator"
			$AdminGroupsAccount = "Administrators"
			$AdminDomaintGroupsAccount = "Domain Admins"
			$OsCulture = "English"
			
			return $AdminAccount, $AdminGroupsAccount, $AdminDomaintGroupsAccount, $OsCulture
		}
		
		Default { }
	}
}
$AdminAccount = (Get-OsCulture)[0]
$AdminGroupsAccount = (Get-OsCulture)[1]
$AdminDomaintGroupsAccount = (Get-OsCulture)[2]
$OSCulture = (Get-OsCulture)[3]

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Configure SQL DB - AdministrationCentral" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

$regKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$key = "DisableLoopbackCheck"

New-ItemProperty -Path $regKeyPath -Name $key -Value "1" -PropertyType dword 

$domain= (Get-ADDomain).NetBIOSName
$AdminAccount = $domain + "\" + $AdminAccount



$DBServer = $env:COMPUTERNAME
$ConfigDB = 'spFarmConfiguration'
$CentralAdminContentDB = 'spCentralAdministration'
$CentralAdminPort = Get-Date -Format yyyy
$PassPhrase = 'SharePoint 2016 is Good ! ! '
$SecPassPhrase = ConvertTo-SecureString $PassPhrase –AsPlaintext –Force
Write-trace -NewLog $logFile -Value "The SharePoint Phrase is $PassPhrase" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "The Adinistration Central port is $CentralAdminPort" -Component Main -Severity 1

$FarmAcc = $AdminAccount
$FarmPassword = '123+aze'
Write-trace -NewLog $logFile -Value "The Admin Accoutn is : $FarmAcc with the password : $FarmPassword" -Component Main -Severity 1

$FarmAccPWD = ConvertTo-SecureString $FarmPassword  –AsPlaintext –Force
$cred_FarmAcc = New-Object System.Management.Automation.PsCredential $FarmAcc,$FarmAccPWD


#WebFrontEnd, Application, DistributedCache, Search, Custom, SingleServerFarm
$ServerRole = "SingleServerFarm"
Write-trace -NewLog $logFile -Value "Create a $ServerRole with the server $env:COMPUTERNAME" -Component Main -Severity 1


Write-Host " - Enabling SP PowerShell cmdlets..."  
If ((Get-PsSnapin |?{$_.Name -eq "Microsoft.SharePoint.PowerShell"})-eq $null)  
{
    Add-PsSnapin Microsoft.SharePoint.PowerShell | Out-Null
}
Start-SPAssignment -Global | Out-Null

Write-trace -NewLog $logFile -Value "- Creating configuration database... " -Component Main -Severity 1


Write-Host " - Creating configuration database..."   -ForegroundColor Green
New-SPConfigurationDatabase –DatabaseName "$ConfigDB" –DatabaseServer "$DBServer" –AdministrationContentDatabaseName "$CentralAdminContentDB" –Passphrase $SecPassPhrase –FarmCredentials $cred_FarmAcc -LocalServerRole $ServerRole
Write-trace -NewLog $logFile -Value "- DB Name : $ConfigDB / on $DBServer / DBName $CentralAdminContentDB " -Component Main -Severity 1

Write-trace -NewLog $logFile -Value "- Installing Help Collection..." -Component Main -Severity 1

Write-Host " - Installing Help Collection..."   -ForegroundColor Green
Install-SPHelpCollection -All

Write-trace -NewLog $logFile -Value "- Securing Resources..." -Component Main -Severity 1

Write-Host " - Securing Resources..."   -ForegroundColor Green
Initialize-SPResourceSecurity

Write-trace -NewLog $logFile -Value "- Installing Services..." -Component Main -Severity 1

Write-Host " - Installing Services..."   -ForegroundColor Green
Install-SPService

Write-trace -NewLog $logFile -Value "- Installing Features..." -Component Main -Severity 1

Write-Host " - Installing Features..."   -ForegroundColor Green
$Features = Install-SPFeature –AllExistingFeatures -Force
$url = $env:COMPUTERNAME + ":" + $CentralAdminPort
Write-trace -NewLog $logFile -Value "- Creating Central Admin... http://$url" -Component Main -Severity 1

Write-Host " - Creating Central Admin..."   -ForegroundColor Green
$NewCentralAdmin = New-SPCentralAdministration -Port $CentralAdminPort -WindowsAuthProvider "NTLM"

Write-Host " - Waiting for Central Admin to provision..." -NoNewline   -ForegroundColor Green
sleep 5  
Write-Host "Created!" -ForegroundColor Magenta

Write-Host " - Installing Application Content..."   -ForegroundColor Green
Install-SPApplicationContent


Stop-SPAssignment -Global | Out-Null

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Log Finished with Success" -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

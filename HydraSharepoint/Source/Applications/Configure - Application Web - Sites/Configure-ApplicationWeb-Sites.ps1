<#
Solution: Hydration Sharepoint
Purpose: Configure - Application Web Sites
Version: 1.2 - 2017


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

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Configure - Application Web Sites" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

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

Write-trace -NewLog $logFile -Value "The System is a $OsCulture Operating System " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "We use this Admin accounts $AdminAccount and Admnin Group $AdminGroupsAccount and the Domain Admin $AdminDomaintGroupsAccount  " -Component Main -Severity 1

#Get Domain Info and generate Administrator account
$info=get-addomain
$infoC=$info.DNSRoot
$split=$infoC.split(".")
$domain=$split[0]
$Ext=$split[1]
$AdminAccount = $domain + "\$AdminAccount"


# Load the SharePoint PowerShell cmdlets
# Load the SharePoint PowerShell cmdlets
Write-Host " - Enabling SP PowerShell cmdlets..."
If ((Get-PsSnapin | ?{ $_.Name -eq "Microsoft.SharePoint.PowerShell" }) -eq $null)
{
	Add-PsSnapin Microsoft.SharePoint.PowerShell | Out-Null
}

$webAppPort = 80
$authProvider = New-SPAuthenticationProvider
$adminManagedAccount = Get-SPManagedAccount $AdminAccount
$NewSPWebApp = New-SPWebApplication -Name "Sharepoint - 80" -ApplicationPool "SharePoint - 80" -ApplicationPoolAccount $adminManagedAccount -Port $webAppPort -AuthenticationProvider $authProvider
Install-SPFeature -AllExistingFeatures -Force | Out-Null #Active all required Farm Features
Write-trace -NewLog $logFile -Value "Create Web Application. Please be Patient..." -Component Main -Severity 1

Write-Host "Create Web Application. Please be Patient..." -ForegroundColor Green

Start-Sleep -Seconds 65

$Hostname = (Get-WmiObject Win32_ComputerSystem).name

$blankSiteTemplate = Get-SPWebTemplate STS#2
New-SPSite -Url "http://$Hostname/" -Name "Accueil" -Template $blankSiteTemplate -OwnerAlias $AdminAccount | Out-Null
Write-Host "The Url Site is http://$Hostname/" -ForegroundColor Green
Write-trace -NewLog $logFile -Value "The Url Site is http://$Hostname/" -Component Main -Severity 1


# Stop logging
Stop-Transcript

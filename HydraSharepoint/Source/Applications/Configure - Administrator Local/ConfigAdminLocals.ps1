<#
Solution: Hydration Sharepoint
Purpose: Configure - Administrator Locals
Version: 1.0 - 2014

Author - Jérôme Bezet-Torres
#>

# Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("LogPath") 
$logFile = "$logPath\$($myInvocation.MyCommand).log" 

# Start the logging 
Start-Transcript $logFile 
Write-Host "Logging to $logFile"


#Get Domain Info
$info=get-addomain
$infoC=$info.DNSRoot
$split=$infoC.split(".")
$domain=$split[0]
$Ext=$split[1]


Function Get-AdministratorsGroup
{
    If(!$builtinAdminGroup)
    {
        $builtinAdminGroup = (Get-WmiObject -Class Win32_Group -computername $env:COMPUTERNAME -Filter "SID='S-1-5-32-544' AND LocalAccount='True'" -errorAction "Stop").Name
    }
    Return $builtinAdminGroup
}

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


$builtinAdminGroup = Get-AdministratorsGroup
([ADSI]"WinNT://$env:COMPUTERNAME/$builtinAdminGroup,group").Add("WinNT://$domain/$AdminAccount")
([ADSI]"WinNT://$env:COMPUTERNAME/$builtinAdminGroup,group").Add("WinNT://$domain/AdminShare")


# Stop logging 
Stop-Transcript
               
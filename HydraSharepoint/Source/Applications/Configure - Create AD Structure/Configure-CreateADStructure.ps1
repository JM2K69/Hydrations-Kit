<#
	Solution HydrationKit
	Action : Configure - AD Structure
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

# récupération des informations du domaine racine
$info = get-addomain
$infoC = $info.DNSRoot
function get-DN ($param1)
{
	$Rdomain = ""
	$split = $param1.split(".")
	$nb = $split.Count
	
	switch ($nb)
	{
		2{
			
			$domain1 = $split[0]
			$Ext1 = $split[1]
			$Rdomain = "dc=$domain1,dc=$ext1"
			
			return $Rdomain
		}
		3{
			$sdomain = $split[0]
			$domain = $split[1]
			$Ext = $split[2]
			
			$Rdomain = "dc=$sdomain,dc=$domain,dc=$ext"
			
			return $Rdomain
		}
	}
}

$dom = get-DN $infoC
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "The Domain Active Directory Root is $dom" -Component Main -Severity 1
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


# All variables
$1niveau = @("Equipment", "Services")
$Users = $1niveau[1]
$ordi = $1niveau[0]
$Services = @("Marketing", "IT", "Direction", "Accounting", "Production", "Services_Account")
$Groupes = @("Groupes_DL", "Groupes_GL", "Groupes_U")
$Type = @("Computers", "Portables", "Servers")

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create Active Directory OU" -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

#Création des Ou de 1 er Niveaux Matériels, Users, Ordinateurs
Foreach ($x in $1niveau)
{
	New-ADOrganizationalUnit -Name $x -ProtectedFromAccidentalDeletion $false
	Write-trace -NewLog $logFile -Value "Create the First OU Level with the name $x" -Component Main -Severity 1
	
}

#Création des Ou sous Utilisteurs

New-ADOrganizationalUnit -Name "Services" -path "ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false
Foreach ($x in $Services)
{
	New-ADOrganizationalUnit -Name $x -path "ou=Services,ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false
	Write-trace -NewLog $logFile -Value "Create the OU for the Service $x in the path ou=Services,ou=$Users,$dom" -Component Main -Severity 1
	
}
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create Active Directory groups " -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


New-ADOrganizationalUnit -Name "Groupes" -path "ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false
Foreach ($x in $Groupes)
{
	New-ADOrganizationalUnit -Name $x -path "ou=Groupes,ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false
	Write-trace -NewLog $logFile -Value "Create the OU for group $x in the path ou=Groupes,ou=$Users,$dom" -Component Main -Component Main -Severity 1
	
}

#Création des Ou sous Ordinateurs
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create Ou Strucutre For equipement " -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Foreach ($x in $Type)
{
	
	New-ADOrganizationalUnit -Name $x -path "ou=$ordi,$dom" -ProtectedFromAccidentalDeletion $false
	Write-trace -NewLog $logFile -Value "Create the second level OU with the name $x in the path ou=$ordi,$dom"  -Component Main -Severity 1
	
}
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create Groups Global " -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

foreach ($x in $Services)
{
	
	New-ADGroup -DisplayName G_$x -GroupScope Global -Name G_$x -Path "OU=Groupes_GL,OU=Groupes,OU=Services,$dom"
	Write-trace -NewLog $logFile -Value "Create the Global Group $x in the Path OU=Groupes_GL,OU=Groupes,OU=Services,$dom " -Component Main -Severity 1
	
}

New-ADGroup -DisplayName "G_MDT" -GroupScope Global -Name "G_MDT" -Path "OU=Groupes_GL,OU=Groupes,OU=Services,$dom"
New-ADGroup -DisplayName "G_SysCenterSuite" -GroupScope Global -Name "G_SysCenterSuite" -Path "OU=Groupes_GL,OU=Groupes,OU=Services,$dom"
New-ADGroup -DisplayName "G_Tech Support" -GroupScope Global -Name "G_Tech Support" -Path "OU=Groupes_GL,OU=Groupes,OU=Services,$dom"
Write-trace -NewLog $logFile -Value "Create the Global Group G_MDT in the Path OU=Groupes_GL,OU=Groupes,OU=Services,$dom " -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create the Global Group G_SysCenterSuite in the Path OU=Groupes_GL,OU=Groupes,OU=Services,$dom " -Component Main -Severity 1


Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Create User For Lab " -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


$ITs = @("Julien", "Laurent", "Jerome", "Fabien")
$Password = "123+aze"
$ou = "OU=IT,ou=Services,ou=$Users,$dom"
foreach ($p in $ITs)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "$AdminGroupsAccount"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "$AdminGroupsAccount", "$AdminDomaintGroupsAccount", "G_IT"
	Enable-ADAccount -Identity $p
	
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	
}

$Marketing = @("Juliette", "Sylvie", "Anne", "Stéphane")
$Password = "123+aze"
$ou = "OU=Marketing,ou=Services,ou=$Users,$dom"
foreach ($p in $Marketing)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Employés Marketing"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Marketing"
	Enable-ADAccount -Identity $p
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	
}

$Accounting = @("Maria", "Nathalie", "Jean", "Bernard")
$Password = "123+aze"
$ou = "OU=Accounting,ou=Services,ou=$Users,$dom"
foreach ($p in $Accounting)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Employés Accounting"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Accounting"
	Enable-ADAccount -Identity $p
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	
}

$Directions = @("Alain", "Cammille")
$Password = "123+aze"
$ou = "OU=Direction,ou=Services,ou=$Users,$dom"
foreach ($p in $Directions)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Direction"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Direction"
	Enable-ADAccount -Identity $p
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	
}

$TechSupport = @("Jule", "Liza", "Kym", "Olivier")
$Password = "123+aze"
$ou = "OU=IT,ou=Services,ou=$Users,$dom"
foreach ($p in $TechSupport)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Employés ITs"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Tech Support"
	Enable-ADAccount -Identity $p
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	
}

$MDT = @("MDT_JD", "MDT_BA", "MDT_User")
$Password = "123+aze"
$ou = "OU=Services_Account,ou=Services,ou=$Users,$dom"
foreach ($p in $MDT)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "MDT_users"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_MDT", "G_IT"
	set-adUser -identity $p -PasswordNeverExpires $true
	Enable-ADAccount -Identity $p
	
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	Write-trace -NewLog $logFile -Value "The user $p is member of the Active Directory groups : G_MDT,G_IT" -Component Main -Component Main -Severity 1
	
}

$MDT = @("CM_NAA", "CM_CP", "CM_SR", "CM_JD", "CM_Admin")
$Password = "123+aze"
$ou = "OU=Services_Account,ou=Services,ou=$Users,$dom"
foreach ($p in $MDT)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "SystemCenter_users"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_SysCenterSuite", "$AdminGroupsAccount"
	set-adUser -identity $p -PasswordNeverExpires $true
	Enable-ADAccount -Identity $p
		
	Write-trace -NewLog $logFile -Value "Create the User with the name $p in the Path $ou with the a password and it don't expire" -Component Main -Component Main -Severity 1
	Write-trace -NewLog $logFile -Value "The user $p is member of the  Active Directory groups : G_SysCenterSuite and $AdminGroupsAccount " -Component Main -Component Main -Severity 1
	
}

# Stop logging 

Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Log Finished with Success" -Component Main -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1


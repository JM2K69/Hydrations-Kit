<#
	Solution HydrationKit
	Action : Configure - AD Structure
    Created:	 2016-02-1
    Version:	 1.0

	This script is provided "AS IS" with no warranties, confers no rights and 
	is not supported by the author. 

    Author - Jérôme Bezet-Torres
    Twitter: @JM2K69
    
#>

# Determine where to do the logging 
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")
$logFile = "$logPath\$($myInvocation.MyCommand).log"

# Start the logging 
Start-Transcript $logFile
Write-Host "Logging to $logFile"

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


# Décalaration des variables
$1niveau = @("Matériels", "Utilisateurs", "Ordinateurs")
$Users = $1niveau[1]
$ordi = $1niveau[2]
$Services = @("Marketing", "Informatique", "Direction", "Comptabilité", "Production", "Comptes_services")
$Groupes = @("Groupes_DL", "Groupes_GL", "Groupes_U")
$Type = @("Fixes", "Portables", "Serveurs")


#Création des Ou de 1 er Niveaux Matériels, Utilisateurs, Ordinateurs
Foreach ($x in $1niveau) { New-ADOrganizationalUnit -Name $x -ProtectedFromAccidentalDeletion $false }

#Création des Ou sous Utilisteurs

New-ADOrganizationalUnit -Name "Services" -path "ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false
Foreach ($x in $Services) { New-ADOrganizationalUnit -Name $x -path "ou=Services,ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false }

New-ADOrganizationalUnit -Name "Groupes" -path "ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false
Foreach ($x in $Groupes) { New-ADOrganizationalUnit -Name $x -path "ou=Groupes,ou=$Users,$dom" -ProtectedFromAccidentalDeletion $false }

#Création des Ou sous Ordinateurs

Foreach ($x in $Type) { New-ADOrganizationalUnit -Name $x -path "ou=$ordi,$dom" -ProtectedFromAccidentalDeletion $false }

New-ADGroup -DisplayName "G_Informatique" -GroupScope Global -Name "G_Informatique" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"
New-ADGroup -DisplayName "G_Marketing" -GroupScope Global -Name "G_Marketing" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"
New-ADGroup -DisplayName "G_Comptabilité" -GroupScope Global -Name "G_Comptabilité" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"
New-ADGroup -DisplayName "G_Directions" -GroupScope Global -Name "G_Directions" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"
New-ADGroup -DisplayName "G_Tech Support" -GroupScope Global -Name "G_Tech Support" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"
New-ADGroup -DisplayName "G_MDT" -GroupScope Global -Name "G_MDT" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"
New-ADGroup -DisplayName "G_SysCenterSuite" -GroupScope Global -Name "G_SysCenterSuite" -Path "OU=Groupes_GL,OU=Groupes,OU=Utilisateurs,$dom"


$Informatiques = @("Julien", "Laurent", "Jerome", "Fabien")
$Password = "123+aze"
$ou = "OU=Informatique,ou=Services,ou=$Users,$dom"
foreach ($p in $Informatiques)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Administrateurs"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "Administrateurs", "Admins du domaine", "G_Informatique"
	Enable-ADAccount -Identity $p
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
}

$Comptabilité = @("Maria", "Nathalie", "Jean", "Bernard")
$Password = "123+aze"
$ou = "OU=Comptabilité,ou=Services,ou=$Users,$dom"
foreach ($p in $Comptabilité)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Employés Comptabilité"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Comptabilité"
	Enable-ADAccount -Identity $p
}

$Directions = @("Alain", "Cammille")
$Password = "123+aze"
$ou = "OU=Direction,ou=Services,ou=$Users,$dom"
foreach ($p in $Directions)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Direction"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Directions"
	Enable-ADAccount -Identity $p
}

$TechSupport = @("Jule", "Liza", "Kym", "Olivier")
$Password = "123+aze"
$ou = "OU=Informatique,ou=Services,ou=$Users,$dom"
foreach ($p in $TechSupport)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "Employés Informatiques"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_Tech Support"
	Enable-ADAccount -Identity $p
}

$MDT = @("MDT_JD", "MDT_BA", "MDT_User")
$Password = "123+aze"
$ou = "OU=Comptes_services,ou=Services,ou=$Users,$dom"
foreach ($p in $MDT)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "MDT_users"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_MDT", "G_Informatique"
	set-adUser -identity $p -PasswordNeverExpires $true
	Enable-ADAccount -Identity $p
}

$MDT = @("CM_NAA", "CM_CP", "CM_SR", "CM_JD", "CM_Admin")
$Password = "123+aze"
$ou = "OU=Comptes_services,ou=Services,ou=$Users,$dom"
foreach ($p in $MDT)
{
	New-ADUser -Name $p -GivenName $p -DisplayName "$p" -SamAccountName $p -Path $OU -PasswordNeverExpires 1 -Description "SystemCenter_users"
	Set-ADAccountPassword -Identity $p -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
	Add-ADPrincipalGroupMembership -Identity $p -MemberOf "G_SysCenterSuite", "Administrateurs"
	set-adUser -identity $p -PasswordNeverExpires $true
	Enable-ADAccount -Identity $p
}

# Stop logging 
Stop-Transcript

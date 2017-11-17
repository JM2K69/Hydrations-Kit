<#
.Synopsis
    Sample script for Hydration Kit
.DESCRIPTION
    Created: 2016-01-07
    Version: 1.2

    Author : Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author or DeploymentArtist..
.EXAMPLE
    NA
#>


# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Break
}

# Verify that MDT 8443 is installed
if (!((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft Deployment Toolkit (6.3.8443.1000)"}).Displayname).count) {Write-Warning "MDT 8443 not installed, aborting...";Break}

# Validation, verify that the deployment share doesnt exist already
$RootDrive = "C:"
If (Get-SmbShare | Where-Object { $_.Name -eq "HydrationCM$"}){Write-Warning "HydrationCM$ share already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\HydrationCM\DS") {Write-Warning "$RootDrive\HydrationCMW\DS already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\HydrationCM\ISO") {Write-Warning "$RootDrive\HydrationCMW\ISO already exist, please cleanup and try again. Aborting...";Break}

# Validation, verify that the PSDrive doesnt exist already
if (Test-Path -Path "DS001:") {Write-Warning "DS001: PSDrive already exist, please cleanup and try again. Aborting...";Break}

# Check free space on C: - Minimum for the Hydration Kit is 50 GB
$NeededFreeSpace = 50 #GigaBytes
$Disk = Get-wmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" 
$FreeSpace = [MATH]::ROUND($disk.FreeSpace /1GB)
Write-Host "Checking free space on C: - Minimum is $NeededFreeSpace GB"

if($FreeSpace -lt $NeededFreeSpace){
    
    Write-Warning "Oupps, you need at least $NeededFreeSpace GB of free disk space"
    Write-Warning "Available free space on C: is $FreeSpace GB"
    Write-Warning "Aborting script..."
    Write-Host ""
    Write-Host "TIP: If you don't have space on C: but have other volumes, say D:, available, " -ForegroundColor Yellow
    Write-Host "then copy the HydrationCM folder to D: and use mklink to create a synlink on C:" -ForegroundColor Yellow
    Write-Host "The syntax is: mklink C:\HydrationCM D:\HydrationCM /D" -ForegroundColor Yellow
    Break
}

# Validation OK, create Hydration Deployment Share
$MDTServer = (get-wmiobject win32_computersystem).Name

Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction SilentlyContinue 
md C:\HydrationCMWS2016\DS
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "C:\HydrationCM\DS" -Description "Hydration ConfigMgr" -NetworkPath "\\$MDTServer\HydrationCM$" | add-MDTPersistentDrive
New-SmbShare –Name HydrationCM$ –Path "C:\HydrationCM\DS"  –ChangeAccess EVERYONE

md C:\HydrationCM\ISO\Content\Deploy
new-item -path "DS001:\Media" -enable "True" -Name "MEDIA001" -Comments "" -Root "C:\HydrationCM\ISO" -SelectionProfile "Everything" -SupportX86 "False" -SupportX64 "True" -GenerateISO "True" -ISOName "HydrationCM.iso"
new-PSDrive -Name "MEDIA001" -PSProvider "MDTProvider" -Root "C:\HydrationCM\ISO\Content\Deploy" -Description "Hydration ConfigMgr Media" -Force

# Configure MEDIA001 Settings (disable MDAC) - Not needed in the Hydration Kit
Set-ItemProperty -Path MEDIA001: -Name Boot.x86.FeaturePacks -Value ""
Set-ItemProperty -Path MEDIA001: -Name Boot.x64.FeaturePacks -Value ""

# Copy sample files to Hydration Deployment Share
Copy-Item -Path "C:\HydrationCM\Source\Hydration\Applications" -Destination "C:\HydrationCM\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCM\Source\Hydration\Control" -Destination "C:\HydrationCM\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCM\Source\Hydration\Operating Systems" -Destination "C:\HydrationCM\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCM\Source\Hydration\Scripts" -Destination "C:\HydrationCM\DS" -Recurse -Force
Copy-Item -Path "C:\HydrationCM\Source\Media\Control" -Destination "C:\HydrationCM\ISO\Content\Deploy" -Recurse -Force

﻿


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
If (Get-SmbShare | Where-Object { $_.Name -eq "HYDRASHARE$"}){Write-Warning "HYDRASHARE$ share already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\HYDRASHARE\DS") {Write-Warning "$RootDrive\HYDRASHARE\DS already exist, please cleanup and try again. Aborting...";Break}
if (Test-Path -Path "$RootDrive\HYDRASHARE\ISO") {Write-Warning "$RootDrive\HYDRASHARE\ISO already exist, please cleanup and try again. Aborting...";Break}

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
    Write-Host "then copy the HYDRASHARE folder to D: and use mklink to create a synlink on C:" -ForegroundColor Yellow
    Write-Host "The syntax is: mklink C:\HYDRASHARE D:\HYDRASHARE /D" -ForegroundColor Yellow
    Break
}

# Validation OK, create Hydration Deployment Share
$MDTServer = (get-wmiobject win32_computersystem).Name

Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction SilentlyContinue 
md C:\HYDRASHAREWS2016\DS
new-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "C:\HYDRASHARE\DS" -Description "Hydration SharePoint" -NetworkPath "\\$MDTServer\HYDRASHARE$" | add-MDTPersistentDrive
New-SmbShare -Name HYDRASHARE$ -Path "C:\HYDRASHARE\DS"  -ChangeAccess EVERYONE

md C:\HYDRASHARE\ISO\Content\Deploy
new-item -path "DS001:\Media" -enable "True" -Name "MEDIA001" -Comments "" -Root "C:\HYDRASHARE\ISO" -SelectionProfile "Everything" -SupportX86 "False" -SupportX64 "True" -GenerateISO "True" -ISOName "HYDRASHARE.iso"
new-PSDrive -Name "MEDIA001" -PSProvider "MDTProvider" -Root "C:\HYDRASHARE\ISO\Content\Deploy" -Description "Hydration ConfigMgr Media" -Force

# Configure MEDIA001 Settings (disable MDAC) - Not needed in the Hydration Kit
Set-ItemProperty -Path MEDIA001: -Name Boot.x86.FeaturePacks -Value ""
Set-ItemProperty -Path MEDIA001: -Name Boot.x64.FeaturePacks -Value ""

# Copy sample files to Hydration Deployment Share
Copy-Item -Path "C:\HYDRASHARE\Source\Hydration\Applications" -Destination "C:\HYDRASHARE\DS" -Recurse -Force
Copy-Item -Path "C:\HYDRASHARE\Source\Hydration\Control" -Destination "C:\HYDRASHARE\DS" -Recurse -Force
Copy-Item -Path "C:\HYDRASHARE\Source\Hydration\Operating Systems" -Destination "C:\HYDRASHARE\DS" -Recurse -Force
Copy-Item -Path "C:\HYDRASHARE\Source\Hydration\Scripts" -Destination "C:\HYDRASHARE\DS" -Recurse -Force
Copy-Item -Path "C:\HYDRASHARE\Source\Media\Control" -Destination "C:\HYDRASHARE\ISO\Content\Deploy" -Recurse -Force

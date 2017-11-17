<#
	Solution HydrationKit
	Action : Configure - Wallpaper
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

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$logPath = $tsenv.Value("LogPath")
$logFile = "$logPath\$($myInvocation.MyCommand).log"
$LocalPath = "C:\wallpaper\"
Write-trace -NewLog $logFile -Value "Create the directory $LocalPath" -Component Main -Severity 1
New-Item -ItemType Directory -Force -Path $LocalPath | Out-Null
$OSType = (Get-WmiObject win32_operatingSystem).ProductType


Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "Configure HydrationWallpaper" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

Write-trace -NewLog $logFile -Value "Configure Windows Interface and JPG Quality Import" -Component Main -Severity 1
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name JPGImportQality -Type DWord -Value 100
Stop-Process -Name explorer
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name DisableLogonBackgroundImage -Value 1
Set-Location HKLM:\SOFTWARE\Policies\Microsoft\Windows |Out-Null
New-Item -Name Personalization|Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value "%SystemRoot%\\Web\\Screen\\img105.jpg"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name NoChangingLockScreen -Type DWord -Value 1


switch ($OSType)
{
	'1' {

$a = get-itemproperty -path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$build=$a.CurrentBuild
if ($build -eq "15063")
{
  Write-trace -NewLog $logFile -Value "The OS Type is Client  with the buildNumber $build" -Component Main -Severity 1

$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$DesktopPath = "DesktopImagePath"
$DesktopStatus = "DesktopImageStatus"
$DesktopUrl = "DesktopImageUrl"
$LockScreenPath = "LockScreenImagePath"
$LockScreenStatus = "LockScreenImageStatus"
$LockScreenUrl = "LockScreenImageUrl"

$StatusValue = "1"
$DesktopImageValue = "C:\wallpaper\WallpaperC.jpg"  
$LockScreenImageValue = "C:\Wallpaper\LockScreenHydration.jpg"  

if(!(Test-Path $RegKeyPath))

  {
        Write-trace -NewLog $logFile -Value "Copying D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperC.jpg $LocalPath" -Component Main -Severity 1
   	    Write-trace -NewLog $logFile -Value "Copying D:\Deploy\Applications\Configure - Wallpaper\source\LockScreenC.jpg $LocalPath" -Component Main -Severity 1
        Copy-Item "D:\Deploy\Applications\Configure - Wallpaper\source\LockScreenC.jpg" $LocalPath
        Copy-Item "D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperC.jpg" $LocalPath
		Write-trace -NewLog $logFile -Value "Default Client Wallpaper" -Component Main -Severity 1


    New-Item -Path $RegKeyPath -Force | Out-Null

    New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenPath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenUrl -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
    
		
    }

 else {
        
        Write-trace -NewLog $logFile -Value "Copying D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperC.jpg $LocalPath" -Component Main -Severity 1
   	    Write-trace -NewLog $logFile -Value "Copying D:\Deploy\Applications\Configure - Wallpaper\source\LockScreenC.jpg $LocalPath" -Component Main -Severity 1
        Copy-Item "D:\Deploy\Applications\Configure - Wallpaper\source\LockScreenHydration.jpg" $LocalPath
        Copy-Item "D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperC.jpg" $LocalPath
		Write-trace -NewLog $logFile -Value "Default Client Wallpaper" -Component Main -Severity 1


        New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $Statusvalue -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name $LockScreenStatus -Value $value -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name $LockScreenPath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $RegKeyPath -Name $LockScreenUrl -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
    }
}
else
{
        Write-trace -NewLog $logFile -Value "The OS Type is Client" -Component Main -Severity 1
		Write-trace -NewLog $logFile -Value "Copying D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperC.jpg $LocalPath" -Component Main -Severity 1
	    Copy-Item "D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperC.jpg" $LocalPath
		Write-trace -NewLog $logFile -Value "Default Client Wallpaper"  -Component Main -Severity 1
		Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value "C:\Wallpaper\wallpaperC.jpg"
		Write-trace -NewLog $logFile -Value "Default Client Wallpaper" -Component Main -Severity 1

Set-Location HKLM:\SOFTWARE\Policies\Microsoft\Windows |Out-Null
New-Item -Name Personalization|Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value "%SystemRoot%\\Web\\Screen\\img105.jpg" 
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name NoChangingLockScreen -Type DWord -Value 1


}
		
		
        }
    {$OSType -in '2','3'}
     {
		Write-trace -NewLog $logFile -Value "The OS Type is Server" -Component Main -Severity 1
		Write-trace -NewLog $logFile -Value "Copying D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperS.jpg $LocalPath" -Component Main -Severity 1
  	    Copy-Item "D:\Deploy\Applications\Configure - Wallpaper\source\wallpaperS.jpg" $LocalPath
		Write-trace -NewLog $logFile -Value "Default Server Wallpaper" -Component Main -Severity 1
   	    Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value "C:\Wallpaper\wallpaperS.jpg"
		Write-trace -NewLog $logFile -Value "Default Server Wallpaper" -Component Main -Severity 1
     }
    
    Default {Write-Host error}
}


Write-Trace  -NewLog $logFile -Value "Refresh Desktop" -Component Main -Severity 1
Rundll32.exe user32.dll, UpdatePerUserSystemParameters

# Stop logging 
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "End Logging" -Component Main -Severity 1
Write-trace -NewLog $logFile -Value "===========================================" -Component Main -Severity 1

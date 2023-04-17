<#  

Sysmon Management


This is a demo script inteded for use with sysmon to setup a new installation and if not present, install.  If installation is present
pull the configuration version and do a check with GitHub.  

https://github.com/MicrosoftDocs/sysinternals/blob/main/sysinternals/downloads/sysmon.md
https://github.com/totemtechnologies/Sysmon-Tools

Version 1.1.0

v 1.1 -  Created foundation for installer log, to be implemented at a later date  
    Improved installer flow 
    Added check for running as an admin
    Minor typo fixes
    Changed name to Sysmon_setup

v 1.0.1 - Minor corrections to initial release


#>

#Requires -RunAsAdministrator

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

If (Test-Administrator) {
    Write-Host "User is running as an admin"
    } else {
    Write-Host "User is not running as an admin, exiting"
    Write-Host " "
    Pause
    Exit
    }

Set-ExecutionPolicy -ExecutionPolicy bypass

##Getting started by making the proper log folders in \windows\logs

## First make the log spot##
$SysLog = 'Sysmon Logs'
$Folder = 'C:\Windows\logs\sysmon logs'
function Get-TimeStamp {return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)}

"Test to see if folder [$Folder] exists"
if (Test-Path -Path $Folder) {
    Write-host "Sysmon Log folder is present"
    #Exit
} else {
    Write-host "Sysmon log folder is not present"
    New-Item -ItemType Directory -path C:\Windows\Logs -name $syslog
    Write-host "all done"
    #Exit
}

Write-Output "$(Get-TimeStamp) starting syslog log installer/update file" | Out-File -filepath $folder\syslog_log.txt 


#download from sysinternals github
        Invoke-WebRequest 'https://download.sysinternals.com/files/Sysmon.zip' -outfile "C:\Windows\Temp\sysmon.zip" 
#blowup the zip and drop in temp
        Expand-archive -literalpath C:\Windows\Temp\sysmon.zip -DestinationPath C:\Windows\Temp | Write-Output "$(Get-TimeStamp) Unpacking zip file to temp directory"
#Configfile for HBA
        Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/sysmonconfig-export.xml' -outfile "C:\Windows\sysmonconfig-export.xml" 


## Variables in call ##

$service = "sysmon64"
[int]$CurVer = ((Get-ItemProperty 'C:\Windows\sysmon64.exe')|Select -ExpandProperty VersionInfo).ProductVersion -replace '[.]'
$NewVerpath = "c:\windows\temp"
[int]$newver = ((get-itemproperty $newverpath\sysmon64.exe)|Select -ExpandProperty VersionInfo).ProductVersion -replace '[.]' 
Function start-Sy64service {start-service -name Sysmon64}
Function stop-Sy64service {stop-service -name Sysmon64}
$temppath = "c:\windows\temp"
$conf = "c:\windows\sysmonconfig-export.xml"


$logpath = 'C:\windows\logs\sysmon logs'
$start = (Get-Date).addMinutes(-1440)
$Events = 22,3,1
$logfilehost = hostname

#CLS

##Heres the run##

if (get-service $service) {

#CLS
    write-host "Sysmon is already installed, checking for updates" 
    Function stop-Sy64service {stop-service -name Sysmon64}

        If ($CurVer -lt $newver){
        
        Write-Host "current sysmon is out of date" 
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/u"

        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/i $conf" 
        
        } else {
        
        write-host "Current version is newer" 
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/c $conf"
        write-host "We updated your configuration" 
        
        }
    } else { 
    
#CLS
    Write-host "sysmon is not installed, installing" 
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/i $conf"

    }

##clean up the mess##
Get-ChildItem -Path "C:\Windows\Temp" *sysmon* -Recurse | Remove-Item -Force -Recurse
Get-ChildItem -Path "C:\Windows\Temp" *eula* -Recurse | Remove-Item -Force -Recurse

#stop-Sy64service

#LinusTechTips
#Modify SecPol to support 
secedit /export /cfg c:\secpol.cfg
 (gc C:\secpol.cfg).replace("AuditProcessTracking = 0", "AuditProcessTracking = 3") | Out-File C:\secpol.cfg
 secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
 rm -force c:\secpol.cfg -confirm:$false

#start-Sy64service 

Set-ExecutionPolicy -ExecutionPolicy default

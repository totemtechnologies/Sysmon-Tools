<#  

Sysmon Management

------>>>>!!!READ THIS FIRST!!!<<<<------------------------->>>>!!!READ THIS FIRST!!!<<<<--------------------------------------->>>>!!!READ THIS FIRST!!!<<<<--------------------


TLDR:
Do your homework on this script before using it.

This script is inteded for use with Sysmon provided as freeware from microsoft sysinternals GitHub.  
It is provided with no warranty and in no way guarantees function.  
Script is provided as-is and users are encouraged to review this script in its entirety prior to utilization to ensure it will not cause impact on any computer or organization.  
The SHA256 check included in the script is not fool proof, users should check the script thoroughly before leveraging.  
This script was written and developed from an internal need and published in support of the greater IT Ecosystem.  It is in no way directly related to Sysmon from Sysinternals, 
Microsoft or any of its related products or subsidiaries.


---Script outline---
setup log file
download from Totem Github
SHA256 check
check versioning install as needed, update config regardless
modify secpol
setup schedule tasks
exit

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

https://github.com/MicrosoftDocs/sysinternals/blob/main/sysinternals/downloads/sysmon.md
https://github.com/totemtechnologies/Sysmon-Tools

Version 1.2.5

v 1.2.5 - added opensource warning; rebranded to avoid naming issues.  Minor cleanup

v 1.2.0 - added SHA256 Check against provided SHA256 txt file

v 1.1.6 - Minor clean up and corrections


v 1.1.5 - Created scheduled task for regular updating and log pull
    Moved execution policy to task scheduler.  
    setup transcription of output, its not ideal but its what was needed. Will make it prettier later.
    the tasks within scheduler do not update the "last run result" field.  in the history it does show a run though.  will look into later


v 1.1 -  Created foundation for installer log, to be implemented at a later date  
    Improved installer flow 
    Added check for running as an admin
    Minor typo fixes
    Changed name to Sysmon_setup

v 1.0.1 - Minor corrections to initial release


#>

$SysLog = 'Sysmon Logs'
$Folder = 'C:\Windows\logs\sysmon logs'
$syslogout =  'C:\Windows\Logs\Sysmon Logs\totem_sysman.log'

#Set-ExecutionPolicy -ExecutionPolicy bypass -force

Write-host " "
Start-Transcript -append $syslogout -Force
Write-host " "
Write-host "####################################################################################"
Write-host " "
function Get-TimeStamp {return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)}
Write-Output "$(Get-TimeStamp)"
Write-Output "starting Syslog installer/update file" #| Out-File -filepath $syslogout -NoClobber -append
Write-host " "

##Wait how old is the existing log if there is one??##

"Test to see if folder [$Folder] exists..."
if (Test-Path -Path $Folder) {
    Write-host "Sysmon Log folder is present"
    Get-ChildItem –Path "$syslogout" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item
} else {
    Write-host "Sysmon log folder is not present"
    New-Item -ItemType Directory -path C:\Windows\Logs -name $syslog
    Write-host "created"
    }

#Start-Sleep -Seconds 2
Write-host " "

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
If (Test-Administrator) {
    Write-Host "User is running as an admin"
    } else {
    Write-Host "User is not running as an admin, exiting"
    Write-host " "
    Write-host "####################################################################################"
    #Start-Sleep -Seconds 1
    stop-transcript
    Exit
    }
Write-host " "

#download from sysinternals github
        Write-host "downloading sysmon"
        Write-host " "
        Invoke-WebRequest 'https://live.sysinternals.com/Sysmon64.exe' -outfile "C:\Windows\Temp\sysmon64.exe" | Write-Output "$(Get-TimeStamp) downloading sysmon" -filepath $syslogout -NoClobber -append
#blowup the zip and drop in temp
        <#Write-host "unpacking sysmon"
        Write-host " "
        Expand-archive -literalpath C:\Windows\Temp\sysmon.zip -DestinationPath C:\Windows\Temp 
        #>
#Configfile for HBA
        Write-host "Getting config file"
        Write-host " "
        Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/sysmonconfig-export.xml' -outfile "C:\Windows\sysmonconfig-export.xml" 

Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/totem_sysman.ps1' -outfile "C:\windows\Logs\Sysmon Logs\totem_sysman.ps1" 
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/sysmon_updatecheck.xml' -outfile "C:\windows\Logs\Sysmon Logs\sysmon_updatecheck.xml"
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/Sysmonlog_pull.xml' -outfile "C:\windows\Logs\Sysmon Logs\Sysmonlog_pull.xml"
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/SysmonLogpull.ps1' -OutFile 'C:\windows\Logs\Sysmon Logs\SysmonLogpull.ps1'
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/syshash_sha256.txt' -OutFile 'C:\windows\Logs\Sysmon Logs\syshash_sha256.txt'

## Variables in call ##

$file = "C:\windows\Logs\Sysmon Logs\totem_sysman.ps1"
$service = "sysmon64"
$CurVer = ((Get-Item 'C:\Windows\sysmon64.exe').VersionInfo)
$NewVerpath = "c:\windows\temp"
$newver = ((Get-Item $newverpath\sysmon64.exe).VersionInfo) 
Function start-Sy64service {start-service -name Sysmon64}
Function stop-Sy64service {stop-service -name Sysmon64}
$temppath = "c:\windows\temp"
$conf = "c:\windows\sysmonconfig-export.xml"
$hashSrc = Get-FileHash $file -Algorithm SHA256
$hashDest = get-content -Path "C:\windows\Logs\Sysmon Logs\syshash_sha256.txt"
$logpath = 'C:\windows\logs\sysmon logs'
$start = (Get-Date).addMinutes(-1440)
$Events = 22,3,1
$logfilehost = hostname

#CLS

##Heres the run##

##SHA 256 Check

If ($hashSrc.Hash -ne $hashDest)
{
  write-host
  " The file that was downloaded doesnt match the provided SHA256.  Something is wrong so Im taking the exit ramp now.... "
  Get-FileHash $file -Algorithm SHA256
  get-content -Path "C:\windows\Logs\Sysmon Logs\syshash_sha256.txt"
  Start-Sleep -Seconds 5
  exit
} else {
write-host "Source file and hash are equal, carrying on"
}

if (get-service $service) {

#CLS
    write-host "Sysmon is already installed, checking version" 
    Write-host " "
    Function stop-Sy64service {stop-service -name Sysmon64}

        If ($curver.FileVersion -lt $newver.FileVersion){
        
        Write-Host "Current sysmon is out of date" -ForegroundColor Yellow
        Write-host " "
        Start-Process -wait -FilePath "c:\windows\sysmon64.exe" -ArgumentList "-u force"
        remove-item C:\Windows\sysmon64.exe
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/i $conf" 
        
        } else {
        
        write-host "Current version is installed" -ForegroundColor Green
        Write-host " "
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/c $conf"
        write-host "Configuration updated..." -ForegroundColor Yellow
        Write-host " "
        
        }
    } else { 
    
#CLS
    Write-host "sysmon is not installed, installing" 
    Write-host " "
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/i $conf"

    }

##clean up the mess##
Write-host "Doing a little cleanup"
Write-host " "
Get-ChildItem -Path "C:\Windows\Temp" *sysmon* -Recurse | Remove-Item -Force -Recurse
Get-ChildItem -Path "C:\Windows\Temp" *eula* -Recurse | Remove-Item -Force -Recurse

#stop-Sy64service

#LinusTechTips
#Modify SecPol to support
Write-host "Modifying secpol configuration to support better sysmon output"
Write-host " "
secedit /export /cfg c:\secpol.cfg
 (gc C:\secpol.cfg).replace("AuditProcessTracking = 0", "AuditProcessTracking = 3") | Out-File C:\secpol.cfg
 secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
 rm -force c:\secpol.cfg -confirm:$false

#start-Sy64service 

##Create the scheduled task to run this script at a regular cadence

Write-host "Getting latest updater script"
Write-host " "

$taskname = "Sysmon Update Check"
if (Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }) {
Write-Host "update Task is already setup"
Write-host " "
} else {
Write-host "Setting up scheduled updater task"
Write-host " "

Register-ScheduledTask -xml (Get-Content 'C:\windows\Logs\Sysmon Logs\sysmon_updatecheck.xml' | Out-String) -TaskName "Sysmon Update Check" -Force

}

Register-ScheduledTask -xml (Get-Content 'C:\windows\Logs\Sysmon Logs\SysmonLog_Pull.xml' | Out-String) -TaskName "Sysmon Log Pull" -Force

Write-host " "
Write-host "####################################################################################"

Start-Sleep -Seconds 1

stop-transcript

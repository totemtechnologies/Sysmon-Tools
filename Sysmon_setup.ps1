<#  

Sysmon Management


This script inteded for use with sysmon to setup a new installation and if not present, install.  If installation is present
pull the configuration version and do a check with GitHub.  

https://github.com/MicrosoftDocs/sysinternals/blob/main/sysinternals/downloads/sysmon.md
https://github.com/totemtechnologies/Sysmon-Tools

Version 1.1.6

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
$syslogout =  'C:\Windows\Logs\Sysmon Logs\syslog_setup.log'

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

#Requires -RunAsAdministrator
Start-Sleep -Seconds 2
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
    Start-Sleep -Seconds 1
    stop-transcript
    Exit
    }
Write-host " "

#download from sysinternals github
        Write-host "downloading sysmon"
        Write-host " "
        Invoke-WebRequest 'https://download.sysinternals.com/files/Sysmon.zip' -outfile "C:\Windows\Temp\sysmon.zip" | Write-Output "$(Get-TimeStamp) downloading sysmon" -filepath $syslogout -NoClobber -append
#blowup the zip and drop in temp
        Write-host "unpacking sysmon"
        Write-host " "
        Expand-archive -literalpath C:\Windows\Temp\sysmon.zip -DestinationPath C:\Windows\Temp 
#Configfile for HBA
        Write-host "Getting config file"
        Write-host " "
        Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/sysmonconfig-export.xml' -outfile "C:\Windows\sysmonconfig-export.xml" 

Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/Sysmon_setup.ps1' -outfile "C:\windows\Logs\Sysmon Logs\sysmon_setup.ps1" 
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/sysmon_updatecheck.xml' -outfile "C:\windows\Logs\Sysmon Logs\sysmon_updatecheck.xml"
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/Sysmonlog_pull.xml' -outfile "C:\windows\Logs\Sysmon Logs\Sysmonlog_pull.xml"
Invoke-WebRequest 'https://raw.githubusercontent.com/totemtechnologies/Sysmon-Tools/main/SysmonLogpull.ps1' -OutFile 'C:\windows\Logs\Sysmon Logs\SysmonLogpull.ps1'


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
    write-host "Sysmon is already installed, checking version" 
    Write-host " "
    Function stop-Sy64service {stop-service -name Sysmon64}

        If ($CurVer -lt $newver){
        
        Write-Host "Current sysmon is out of date" 
        Write-host " "
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/u"

        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/i $conf" 
        
        } else {
        
        write-host "Current version is installed" 
        Write-host " "
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/c $conf"
        write-host "Configuration updated..." 
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

<#
$action = New-ScheduledTaskAction -execute powershell.exe -Argument -file '-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass "C:\windows\Logs\Sysmon Logs\sysmon_setup.ps1"'
$trigger = New-ScheduledTaskTrigger -weekly -WeeksInterval 2 -daysofweek Monday -At 1pm
$principal = New-ScheduledTaskPrincipal -User "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
#$settings = New-ScheduledTaskSettingsSet 

Register-ScheduledTask -taskname "Sysmon Update Check" -Action $action -Trigger $trigger -Principal $principal
#>
}


Register-ScheduledTask -xml (Get-Content 'C:\windows\Logs\Sysmon Logs\SysmonLog_Pull.xml' | Out-String) -TaskName "Sysmon Log Pull" -Force


<#
$taskname1 = "Sysmon Log Pull"
if (Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }) {
Write-Host "Log Pull Task is already setup"
Write-host " "

} else {

Write-host "Setting up logpull task"
Write-host " "


}

$action = New-ScheduledTaskAction -execute %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -Argument '-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "C:\windows\Logs\Sysmon Logs\sysmonlogpull.ps1"'
$trigger = New-ScheduledTaskTrigger -Once -at (get-date) -RepetitionInterval (New-TimeSpan -Minutes 60)
$principal = New-ScheduledTaskPrincipal -User "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
#$settings = New-ScheduledTaskSettingsSet 

Register-ScheduledTask -taskname "Sysmon Log Pull" -Action $action -Trigger $trigger -Principal $principal -force
#>

#Set-ExecutionPolicy -ExecutionPolicy default -force

Write-host " "
Write-host "####################################################################################"

Start-Sleep -Seconds 1

stop-transcript

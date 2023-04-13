<#  

Sysmon Management


This is a demo script inteded for use with sysmon to setup a new installation and if not present, install.  If installation is present
pull the configuration version and do a check with GitHub.  

https://github.com/MicrosoftDocs/sysinternals/blob/main/sysinternals/downloads/sysmon.md


#>

#download from sysinternals github
        Invoke-WebRequest 'https://download.sysinternals.com/files/Sysmon.zip' -outfile "C:\Windows\Temp\sysmon.zip"
#blowup the zip and drop in temp
        Expand-archive -literalpath C:\Windows\Temp\sysmon.zip -DestinationPath C:\Windows\Temp 
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

CLS

##Heres the run##

if (get-service $service) {
    CLS
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
    
    CLS
    Write-host "sysmon is not installed, installing"
        Start-Process -wait -FilePath "$temppath\sysmon64.exe" -ArgumentList "/i $conf"

    }

##clean up the mess##
Get-ChildItem -Path "C:\Windows\Temp" *sysmon* -Recurse | Remove-Item -Force -Recurse
Get-ChildItem -Path "C:\Windows\Temp" *eula* -Recurse | Remove-Item -Force -Recurse



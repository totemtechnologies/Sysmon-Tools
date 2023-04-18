
<#


Script in Dev, use at your own risk.

Script to pull logs from sysmon and put into reachable repo in a user-friendly format


Known issues:
File output is not in a readable format for DATE column
date column is not sorted newest to oldest
logs are not generated per day and contain some overlap
logs do not purge after 30 days
script does not run automatically, must be configued for a scheduled task


#>

$logfilehost = hostname
$start = (Get-Date).addMinutes(-60)
$Events = 22,3,1
$logpath = 'C:\windows\logs\sysmon logs'



$result = Get-WinEvent -FilterHashtable @{LogName = 'Microsoft-Windows-Sysmon/Operational'; ID = $Events; starttime = $start} | ForEach-Object {
    # convert the event to XML and grab the Event node
    $eventXml = ([xml]$_.ToXml()).Event

    # output a PsCustomObject to collect $result
    [PsCustomObject]@{
        Computer = $eventXml.System.Computer
        Time_Stamp = ($eventXml.EventData.Data | Where-Object { $_.Name -eq 'UtcTime' }).'#text'
        Event_ID = $eventXml.System.EventID
        Query_Name = ($eventXml.EventData.Data | Where-Object { $_.Name -eq 'QueryName' }).'#text'
        Image = ($eventXml.EventData.Data | Where-Object { $_.Name -eq 'Image' }).'#text'
        Dest_IP = ($eventXml.EventData.Data | Where-Object { $_.Name -eq 'DestinationIP' }).'#text'
        Dest_Port_Name = ($eventXml.EventData.Data | Where-Object { $_.Name -eq 'DestinationPort' }).'#text'
        
    }
}

#Craft the first log and setup the sysmonlog pull task

if (Test-Path -Path $logpath\$($logfilehost)_$((Get-Date).ToString('MM-dd-yyyy'))_syslog.csv) {
    
    $result_old = import-csv "$logpath\$($logfilehost)_$((Get-Date).ToString('MM-dd-yyyy'))_syslog.csv"

    # Compare properties from both lists. Excludes duplicates by default:
    $NewResults = Compare $result_old $result -Property Time_Stamp -PassThru |
    Where { $_.SideIndicator -eq '=>' } |
    Select * -ExcludeProperty SideIndicator  # clean up the SideIndicator field

    $NewResults | Export-Csv -Append "$logpath\$($logfilehost)_$((Get-Date).ToString('MM-dd-yyyy'))_syslog.csv"
    
    
    
    
} else {
  
   $result | Export-Csv "$logpath\$($logfilehost)_$((Get-Date).ToString('MM-dd-yyyy'))_syslog.csv" 
    
}

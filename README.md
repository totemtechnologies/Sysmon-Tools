# Sysmon-Tools
KNOWN ISSUES:
script is occasionally being deleted, not clear why.  


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

Contributors:
BowserRipken
BlownFuse



Sysmon Source Code
https://github.com/MicrosoftDocs/sysinternals/blob/main/sysinternals/downloads/sysmon.md?plain=1

Config File 
https://github.com/SwiftOnSecurity/sysmon-config

Secpol Management
https://linustechtips.com/topic/1169905-powershell-change-a-local-security-policy/?do=findComment&comment=13427038

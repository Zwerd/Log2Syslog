# Log2Syslog

This tool used to convert generic log file ot DNS log file to syslog

## How to run Log2Syslog:
```
PS C:\> .\thisscript.ps1 <logsfullpath> <logname> <extention> <data sourc name>

PS C:\> .\ConvertDNSlogs.ps1 \\dnssrv01\dnslogs\ Dhcp* *.log DHCP-SERVER
```

### How to run DNSLog2Syslog:
```
PS C:\> .\thisscript.ps1 <dnslogs path name> <dns src name> <dst server> <dst port>

PS C:\> .\ConvertDNSlogs.ps1 \\dnssrv01\dnslogs dns-dc01 10.0.0.135 514
```

### About that tool.
I have created this tool for for transfer log files to SIEM system, the idea about the windows DNS Log is to take them and transfer them from debug type (windows Diagnostic DNS) as syslog to SIEM after render each log for contain the web domain and it's IP address that the DNS respond with.

### Enhance Network Visibility with PowerShell: DNS Diagnostic Logs to SIEM

I’ve developed a PowerShell script that transforms Windows DNS diagnostic logs (debug) into a format compatible with SIEM systems. This integration boosts our ability to monitor and analyze DNS queries from local network clients. By capturing both the queries and the responding addresses for each web domain, we gain a more detailed view of network activity, helping to identify potential threats and unusual behaviors more effectively.

With this script, we can turn DNS logs into actionable insights, enhancing our overall cybersecurity posture. Stay tuned for more updates!

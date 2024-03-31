# this script created by zwerd 
# this code is used to take some log file and convert it to syslog
<#
.DESCRIPTION
This script is writen to get logs file and send any logline to syslog server.

.EXAMPLE
    PS C:\> .\thisscript.ps1 <logsfullpath> <logname> <extention> <data sourc name>

    PS C:\> .\ConvertDNSlogs.ps1 \\dnssrv01\dnslogs\ Dhcp* *.log DHCP-SERVER


    Please note: DNS source name can be any name.
#>

function CreateSyslog{
    param($LogName, $FilePath, $lastcounter, $datasource)
	#Write-Host "in function CreateSyslog $LogName $FilePath $lastcounter"
	#Write-Host '$FilePath'
	$filelog = Get-Content $FilePath
    Write-Host "data source $datasource"
	Start-Sleep -Seconds 5
	$currentcounter = $filelog.count
	$looper = 0
	foreach ($line in $filelog){
		
        if($currentcounter -eq 0){
			$HashTable[$LogName] = $currentcounter
			#Write-Output "going to break - looper:$looper"
			break
        }
		elseif($looper -eq $currentcounter){
			
			#Write-Output "going to break - looper:$looper"
			break
		}
		elseif($looper -ge $lastcounter){
			$Server = '10.4.11.128'
			$Message = "$LogName $line"
			#0=EMERG 1=Alert 2=CRIT 3=ERR 4=WARNING 5=NOTICE  6=INFO  7=DEBUG
			$Severity = '1'
			#(16-23)=LOCAL0-LOCAL7
			$Facility = '22'
			$Hostname = $datasource
			# Create a UDP Client Object
			$UDPCLient = New-Object System.Net.Sockets.UdpClient
			$UDPCLient.Connect($Server, 514)
			# Calculate the priority
			$Priority = ([int]$Facility * 8) + [int]$Severity
			#Time format the SW syslog understands
			$Timestamp = Get-Date -Format "MMM dd HH:mm:ss"
			# Assemble the full syslog formatted message
			$FullSyslogMessage = "<{0}>{1} {2} {3}" -f $Priority, $Timestamp, $Hostname, $Message
			Write-Host $FullSyslogMessage
            # create an ASCII Encoding object
			$Encoding = [System.Text.Encoding]::ASCII
			# Convert into byte array representation
			$ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)
			# Send the Message
			$UDPCLient.Send($ByteSyslogMessage, $ByteSyslogMessage.Length)
			$looper += 1
			$lastcounter += 1
			#Write-Output "start to send syslog - looper:$looper"
		}elseif($looper -lt $lastcounter){
			$looper += 1
			#Write-Output "loop counter less then lastcounter - looper:$looper"
			Continue
		}
	}
	#Write-Output "check looper: $looper check currentcounter: $currentcounter"
	$HashTable[$LogName] = $currentcounter
	$HashTable
}



$loop = 0
$Path = $args[0]
$srcfile = $args[1]
$extention = $args[2]
$datasource = $args[3]
$HashTable = @{}
foreach($FileName in (Get-ChildItem $Path$srcfile -Name  -File)){
	$HashTable.Add($FileName.Trim($extention),0)
	$HashTable
}
while($true){
	#Write-Host "in while loop start sleep 5 second!"
	Start-Sleep -Seconds 5
	foreach($FileName in (Get-ChildItem $Path -Name -File)){
		$FilePath = $Path + $FileName
		Write-Host "check filepath $FileName $FilePath"
		$HashTable.($FileName.Trim($extention))
		CreateSyslog $FileName.Trim($extention) $FilePath $HashTable.($FileName.Trim($extention)) $datasource
		$loop += 1
		#Write-Host "in while loop! $filename $loop"
	}
}

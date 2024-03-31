<#
.DESCRIPTION
This script is writen by zwerd, to get DNS logs and parse them with DNS DATA which contain the converted IP for quesried domain name.
Also it's have beeing writen for DNS server that sertup as Debug logging

.EXAMPLE
    PS C:\> .\thisscript.ps1 <dnslogs path name> <dns src name> <dst server> <dst port>

    PS C:\> .\ConvertDNSlogs.ps1 \\dnssrv01\dnslogs dns-dc01 10.0.0.135 514


    Please note: DNS source name can be any name.
#>
function SyslogSender{
    param($DNSsrcname, $Server, $dport, $Message)
    write-host "SYSLOG: $DNSsrcname, $Server, $dport, $Message"
	#0=EMERG 1=Alert 2=CRIT 3=ERR 4=WARNING 5=NOTICE  6=INFO  7=DEBUG
	$Severity = '1'
	#(16-23)=LOCAL0-LOCAL7
	$Facility = '22'
	$Hostname = $DNSsrcname
	# Create a UDP Client Object
	$UDPCLient = New-Object System.Net.Sockets.UdpClient
	$UDPCLient.Connect($Server, $dport)
	# Calculate the priority
	$Priority = ([int]$Facility * 8) + [int]$Severity
	#Time format the SW syslog understands
	$Timestamp = Get-Date -Format "MMM dd HH:mm:ss"
	# Assemble the full syslog formatted message
    $FullSyslogMessage = "<{0}>{1} {2} {3}" -f $Priority, $Timestamp, $Hostname, $Message
	# create an ASCII Encoding object
	$Encoding = [System.Text.Encoding]::ASCII       
	# Convert into byte array representation
	$ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)
	# Send the Message, also write the byte length
	$UDPCLient.Send($ByteSyslogMessage, $ByteSyslogMessage.Length)
	#$looper += 1
	#$lastcounter += 1
	#Write-Output "start to send syslog - looper:$looper"
}

function CreateDNSLogFile{
    param($logfile, $dnslogpath, $lastcounter, $lastfilezise, $dnssrcname, $server, $dport)
    #$FileStream = New-Object -TypeName IO.FileStream -ArgumentList ($dnslogpath), ([System.IO.FileMode]::Open), ([System.IO.FileAccess]::Read), ([System.IO.FileShare]::ReadWrite);
    #$logfile = New-Object -TypeName System.IO.StreamReader -ArgumentList ($FileStream, [System.Text.Encoding]::ASCII, $true);
    #$logfile = $dnslogpath
    $linenumber = 0
    $dnsinfo = ""
    $dnsdata = ""
    $outlinelog = ""
    while(!$logfile.EndOfStream){
        $linelog = $logfile.ReadLine()
        $filesize.($dnslogpath) = (Get-Item $dnslogpath).length
        if($filesize.($dnslogpath) -lt $lastfilezise){
			$linecounter[$dnslogpath] = $linenumber
            #write-host "Going to break!"
            #write-host "currentfilesize: $filesize.($dnslogpath) less tehn lastfilesize: " $lastfilezise
            #write-host "Going to clear content! ------> filename: $dnsoutputfile"
            Clear-Content $dnsoutputfile
			break
        }
        elseif($linenumber -ge $lastcounter){
            ## get information about the first line that contain src, dst, type and more.
            #write-host "-------> $linenumber is grater then $lastcounter"
            if($linelog -match '^[\d]+\/[\d]+\/[\d]+' ){
                $dnsinfo = $linelog
                $dnsdata = ""
            }
            ## get information about the data fro each packeg, that data is the converted IP for each query domain.
            elseif($linelog -match 'DATA[\s]+([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'){
                $dnsdata = $linelog
                #write-host "New LOG: $dnsinfo $dnsdata"
                $lastdata = "$dnsinfo $dnsdata"
                SyslogSender $dnssrcname $server $dport $lastdata
                
            }
            # get any new line and write the logs so far
            elseif($linelog -notmatch '[a-z]|[A-Z]|[\-\(\)\:]'){
                $outline = "$dnsinfo $dnsdata"
                if($lastdata -ne $outline -And $dnsinfo -ne ""){
                    #write-host "New LOG: $dnsinfo $dnsdata"
                    $outline = "$dnsinfo $dnsdata"
                    SyslogSender $dnssrcname $server $dport $outline
                    $dnsinfo = ""
                    $dnsdata = ""
                }
            }
            $linenumber += 1
            $lastcounter += 1
        }
        elseif($linenumber -lt $lastcounter){
            #write-host "-------> $linenumber less then $lastcounter"
			$linenumber += 1
			Continue
		}
    $linecounter[$dnslogpath] = $linenumber
    #$filesize[$dnslogpath] = (Get-Item $dnslogpath).length
    #write-host "inside function counter is: $currentcounter"
    #$linecounter
    }
    return $filesize.($dnslogpath)
}


$linecounter = @{}
$filesize = @{}
$dnslogpath = $args[0]
$dnssrcname = $args[1]
$server = $args[2]
$dport = $args[3]
$linecounter.Add($dnslogpath,1)
$originalfilesize = (Get-Item $dnslogpath).length
$filesize.Add($dnslogpath,$originalfilesize)

while($true){
    <#
    This loop is used for looking new DNS events comming from DNSLogFile.
    If found new event, then it should be write down to the destination file.
    #>
    #write-host "<------- STARTING NEW LOOP -------->"
    #write-host "Reaset orogonalfilesize value"
    $originalfilesize = (Get-Item $dnslogpath).length
    #write-host "filesize: " $originalfilesize "less then? :"  $filesize.($dnslogpath)
    if($originalfilesize -lt $filesize.($dnslogpath)){
        #write-host "inside if --->"
		$linecounter[$dnslogpath] = $linenumber
        $originalfilesize = (Get-Item $dnslogpath).length
        $filesize.($dnslogpath) = $originalfilesize
        #write-host "Going to clear content! ------> filename: $dnsoutputfile"
        Clear-Content $dnsoutputfile
    }
    #$linecounter
    #$linecounter.($dnslogpath)
    $FileStream = New-Object -TypeName IO.FileStream -ArgumentList ($dnslogpath), ([System.IO.FileMode]::Open), ([System.IO.FileAccess]::Read), ([System.IO.FileShare]::ReadWrite);
    $ReadLogFile = New-Object -TypeName System.IO.StreamReader -ArgumentList ($FileStream, [System.Text.Encoding]::ASCII, $true);
    #write-host "OUTPUT FILE: $dnsoutputfile"
    $filesize.($dnslogpath) = CreateDNSLogFile $ReadLogFile $dnslogpath $linecounter.($dnslogpath) $originalfilesize $dnssrcname $server $dport
    Start-Sleep -Seconds 5
}



<#
.SYNOPSIS
    Lock/Unlock ports by knocking closed ports

.DESCRIPTION
    Enable/Disable ports by sending a sequence of SYN packets
    to pre-defined ports. The Knockd service checks the windows
    firewall logs to see if SYN packets were sequentially sent 
    to the defined ports within a space of 10 seconds from the 
    same IP address and then, enable/disable a port.

.EXAMPLE
    .\port-knocker.ps1

.LINK
    https://github.com/Tomiwa-Ot/windows-port-knocker
#>

$FirewallLogs = "$($Env:SystemRoot)\system32\LogFiles\Firewall\pfirewall.log"
$IP = $null

Function Write-Toast {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    # Powershell Launcher ID
    $LauncherId = (Get-StartApps | Where-Object -Property Name -eq "Windows Powershell").AppID

    # Load windows toast assemblies
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    # Xml template
    [xml]$ToastTemplate = @"
        <toast>
            <visual>
                <binding template="ToastImageAndText03">
                    <text id="1">Port Knocker</text>
                    <text id="2">$($Message)</text>
                </binding>
            </visual>
        </toast>
"@

    $ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::New()
    $ToastXml.LoadXml($ToastTemplate.OuterXml)
    $ToastMessage = [Windows.UI.Notifications.ToastNotification]::New($ToastXml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($LauncherId).Show($ToastMessage)
}


Function Watch-Logs {
    param()

    $Timeout = 10 

    $LogPath = Split-Path $FirewallLogs -Parent
    $LogFile = Split-Path $FirewallLogs -Leaf
    $Watcher = New-Object IO.FileSystemWatcher $LogPath, $LogFile -Property @{
        IncludeSubdirectories = $false
        EnableRaisingEvents = $true
    }
    
    Register-ObjectEvent $Watcher -SourceIdentifier 'Knockd.LogWatcher' -Action {
        $LogsLastLine = Get-Content $FirewallLogs -Tail 1
        $global:IP = $LogsLastLine.Split(' ')[4]
        $global:Protocol = $LogsLastLine.Split(' ')[3]
        $DestinationPort = $LogsLastLine.Split(' ')[7]
        $global:json = Get-Content '.\data.json' | ConvertFrom-Json
        foreach ($global:object in $global:json.Daemon) {
            if ($global:object.OpenSequence.Split(' ')[0] -eq $DestinationPort -and $global:object.Protocol -eq $Protocol) {
                Register-ObjectEvent $Watcher -SourceIdentifier 'Knockd.OpenSeq1' -Action {
                    $LogsLastLine2 = Get-Content $FirewallLogs -Tail 1
                    $IP2 = $LogsLastLine2.Split(' ')[4]
                    $Protocol2 = $LogsLastLine2.Split(' ')[3]
                    $DestinationPort2 = $LogsLastLine2.Split(' ')[7]
                    if ($global:object.OpenSequence.Split(' ')[1] -eq $DestinationPort2 -and $IP2 -eq $global:IP -and $global:Protocol -eq $Protocol2) {
                        Register-ObjectEvent $Watcher -SourceIdentifier 'Knockd.OpenSeq2' -Action {
                            $LogsLastLine3 = Get-Content $FirewallLogs -Tail 1
                            $IP3 = $LogsLastLine3.Split(' ')[4]
                            $Protocol3 = $LogsLastLine3.Split(' ')[3]
                            $DestinationPort3 = $LogsLastLine3.Split(' ')[7]
                            if ($global:object.OpenSequence.Split(' ')[1] -eq $DestinationPort3 -and $IP3 -eq $global:IP -and $global:Protocol -eq $Protocol3) {
                                if ($global:Protocol -eq 'TCP') {
                                    Start-Service (Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess).ProcessName
                                    Write-Toast -Message "Knockd started $((Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess).ProcessName) service $($global:object.Port)/$($global:Protocol)"
                                }
                                if($global:Protocol -eq 'UDP') {
                                    Start-Service (Get-Process -Id (Get-NetUDPEndpoint -LocalPort $Port).OwningProcess).ProcessName
                                    Write-Toast -Message "Knockd started $((Get-Process -Id (Get-NetUDPEndpoint -LocalPort $Port).OwningProcess).ProcessName) service $($global:object.Port)/$($global:Protocol)"
                                }
                            }
                        }
                        Wait-Event -SourceIdentifier 'Knockd.OpenSeq2' -Timeout $Timeout
                    }
                }
                Wait-Event -SourceIdentifier 'Knockd.OpenSeq1' -Timeout $Timeout
            }
            if($global:object.CloseSequence.Split(' ')[0] -eq $DestinationPort -and $global:object.Protocol -eq $Protocol) {
                Register-ObjectEvent $Watcher -SourceIdentifier 'Knockd.CloseSeq1' -Action {
                    $LogsLastLine2 = Get-Content $FirewallLogs -Tail 1
                    $IP2 = $LogsLastLine2.Split(' ')[4]
                    $Protocol2 = $LogsLastLine2.Split(' ')[3]
                    $DestinationPort2 = $LogsLastLine2.Split(' ')[7]
                    if ($global:object.OpenSequence.Split(' ')[1] -eq $DestinationPort2 -and $IP2 -eq $global:IP -and $global:Protocol -eq $Protocol2) {
                        Register-ObjectEvent $Watcher -SourceIdentifier 'Knockd.CloseSeq2' -Action {
                            $LogsLastLine3 = Get-Content $FirewallLogs -Tail 1
                            $IP3 = $LogsLastLine3.Split(' ')[4]
                            $Protocol3 = $LogsLastLine3.Split(' ')[3]
                            $DestinationPort3 = $LogsLastLine3.Split(' ')[7]
                            if ($global:object.OpenSequence.Split(' ')[1] -eq $DestinationPort3 -and $IP3 -eq $global:IP -and $global:Protocol -eq $Protocol3) {
                                if ($global:Protocol -eq 'TCP') {
                                    Stop-Service (Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess).ProcessName
                                    Write-Toast -Message "Knockd stopped $((Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess).ProcessName) service $($global:object.Port)/$($global:Protocol)"
                                }
                                if($global:Protocol -eq 'UDP') {
                                    Stop-Service (Get-Process -Id (Get-NetUDPEndpoint -LocalPort $Port).OwningProcess).ProcessName
                                    Write-Toast -Message "Knockd stopped $((Get-Process -Id (Get-NetUDPEndpoint -LocalPort $Port).OwningProcess).ProcessName) service $($global:object.Port)/$($global:Protocol)"
                                }
                            }
                        }
                        Wait-Event -SourceIdentifier 'Knockd.CloseSeq2' -Timeout $Timeout
                    }
                }
                Wait-Event -SourceIdentifier 'Knockd.CloseSeq1' -Timeout $Timeout
            }
        }
    }
    
}

while ($true) {
    Watch-Logs
}
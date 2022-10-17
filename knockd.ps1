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

$firewallLogs = "$($Env:SystemRoot)\system32\LogFiles\Firewall\pfirewall.log"
$timeout = 10
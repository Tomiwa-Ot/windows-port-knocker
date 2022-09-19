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

$firewallLogs = "$($Env:SystemRoot)\system32\LogFiles\Firewall\pfirewall.log"
$timeout = 10
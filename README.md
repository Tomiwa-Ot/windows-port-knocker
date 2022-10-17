# Windows Port-Knocker

![Screenshot](/screenshots/knockd.png)
Enable/Disable ports by sending a sequence of SYN packets
to pre-defined ports. The Knockd service checks the windows
firewall logs to see if SYN packets were sequentially sent 
to the defined ports within a space of x (default = 10) seconds
from the same IP address and then, enable/disable a port.
## Usage
- Open Windows Powershell as an Administrator and execute the following command
```powershell
.\port-knocker-ps1
```

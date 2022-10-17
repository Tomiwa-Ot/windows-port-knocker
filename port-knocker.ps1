<#
.SYNOPSIS
    Lock/Unlock ports by knocking closed ports

.DESCRIPTION
    Enable/Disable ports by sending a sequence of SYN packets
    to pre-defined ports. The Knockd service checks the windows
    firewall logs to see if SYN packets were sequentially sent 
    to the defined ports within a space of x (default = 10) seconds
    from the same IP address and then, enable/disable a port.

.EXAMPLE
    .\port-knocker.ps1

.LINK
    https://github.com/Tomiwa-Ot/windows-port-knocker
#>

Function Clear-Screen {
    param ()
    Clear-Host
}

Function Write-Banner {
    param ()
    Write-Host "`t*******                    **         **   **                           **                   "
    Write-Host "`t/**////**                  /**        /**  **                           /**                   "
    Write-Host "`t/**   /**  ******  ****** ******      /** **   *******   ******   ***** /**  **  *****  ******"
    Write-Host "`t/*******  **////**//**//*///**/       /****   //**///** **////** **///**/** **  **///**//**//*"
    Write-Host "`t/**////  /**   /** /** /   /**        /**/**   /**  /**/**   /**/**  // /****  /******* /** / "
    Write-Host "`t/**      /**   /** /**     /**        /**//**  /**  /**/**   /**/**   **/**/** /**////  /**   "
    Write-Host "`t/**      //****** /***     //**       /** //** ***  /**//****** //***** /**//**//******/***   "
    Write-Host "`t//        //////  ///       //        //   // ///   //  //////   /////  //  //  ////// /// "
    Write-Host "`t                                                                              by @Tomiwa-Ot"
    Write-Host ""
    Write-Host ""
}

Function Write-Menu {
    param ()
    Clear-Screen
    Write-Banner

    Write-Host "1: Start knocking service"
    Write-Host "2: Stop knocking service"
    Write-Host "3: Knockd service status"
    Write-Host "4: Knock a port"
    Write-Host "5: Disable knocking for a port"
    Write-Host "6: List knocked ports"
    Write-Host "7: Exit`n"

    $choice = Read-Host -Prompt '> '

    switch ($choice) {
        1 { Start-KnockdService }
        2 { Stop-KnockdService }
        3 { Get-KnockdStatus }
        4 { Enable-PortKnocking }
        5 { Disable-PortKnocking }
        6 { Get-KnockedPorts }
        7 { Clear-Screen }
        Default { Write-Menu }
    }
}

Function Enable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner
    
    $port = Read-Host -Prompt 'Enter port to knock (1 - 65535) '
    $protocol = Read-Host -Prompt 'Enter protocol (tcp/udp) '
    $openSequence = (Read-Host -Prompt "Enter knock sequence for unlocking $port (use commas to seperate values)").Split(',') -replace " ", ""
    $closeSequence = (Read-Host -Prompt "Enter knock sequence for locking $port (use commas to seperate values)").Split(',') -replace " ", ""
    
    $output = Get-PortStatus -Port $port -Protocol $protocol
    if ($null -ne $output.ErrorMessage) {
        Write-Warning $output.ErrorMessage
        Read-Host -Prompt 'Press any key to continue... '
        Write-Menu
        return
    }

    foreach ($value in $openSequence) {
        if (!([int]$value -ge 1 -or [int]$value -le 65355)) {
            Write-Warning 'Port cannot less than 1 and greater than 65535'
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
        Get-NetTCPConnection -LocalPort $value -ErrorAction Ignore | Out-Null
        if ($?) {
            $service = (Get-Process -Id (Get-NetTCPConnection -LocalPort $value).OwningProcess).ProcessName
            Write-Warning "Cannot use port $value in open sequence, $service is using it"
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
    }

    foreach ($value in $closeSequence) {
        if (!([int]$value -ge 1 -or [int]$value -le 65355)) {
            Write-Warning 'Port cannot less than 1 and greater than 65535'
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
        Get-NetTCPConnection -LocalPort $value -ErrorAction Ignore | Out-Null
        if ($?) {
            $service = (Get-Process -Id (Get-NetTCPConnection -LocalPort $value).OwningProcess).ProcessName
            Write-Warning "Cannot use port $value in close sequence, $service is using it"
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
    }

    $yes  = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Proceed to knock port')
    $no = [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Stop process')

    Write-Host "`nPort: $port/$protocol"
    Write-Host "Service: $($output.ServiceName)"
    Write-Host "Open Sequence: $openSequence"
    Write-Host "Close Sequence: $closeSequence`n"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.UI.PromptForChoice('', "Are you sure want to knock $($output.ServiceName) $Port/tcp?", $options, 0)
    
    switch ($result) {
        0 { 
            Write-Host ''
            Write-Host 'Writing to cache ...'
            Add-JsonCache -Service "$($output.ServiceName)" -Port $port -Protocol $protocol -OpenSequence $openSequence -CloseSequence $closeSequence
            Write-Host "$port/$protocol knocked successfully`n"
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
        }
        1 { Write-Menu }
        Default { Write-Menu }
    }
}

Function Add-JsonCache {
    param (
        [Parameter(Mandatory)]
        [string]$Service,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [string]$Protocol,

        [Parameter(Mandatory)]
        [array]$OpenSequence,

        [Parameter(Mandatory)]
        [array]$CloseSequence
    )

    $json = Get-Content '.\data.json' | ConvertFrom-Json
    $data = "" | Select-Object Service, Port, Protocol, OpenSequence, CloseSequence
    $data.Service = $Service
    $data.Port = $Port
    $data.Protocol = $Protocol
    [array]$openSeq = foreach ($sequence in $OpenSequence) {
        [int]::Parse($sequence)
    }
    $data.OpenSequence = $openSeq
    [array]$closeSeq = foreach ($sequence in $CloseSequence) {
        [int]::Parse($sequence)
    }
    $data.CloseSequence = $closeSeq
    [array]$json.Daemon += $data

    $json | ConvertTo-Json | Set-Content '.\data.json'
}

Function Disable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner

    $Port = Read-Host -Prompt 'Enter knocked port to disable '
    $Protocol = Read-Host -Prompt 'Enter protocol (tcp/udp) '
    $json = Get-Content '.\data.json' | ConvertFrom-Json
    foreach ($object in $json.Daemon) {
        if ($object.Port -eq $Port -and $object.Protocol -eq $Protocol) {
            $yes  = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', "Disable knocking on port $($object.Port)/$($object.Protocol) $($object.Service)")
            $no = [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Cancel')
            
            Write-Host ""
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $result = $host.UI.PromptForChoice('', "Are you sure disable knocking on $($object.Service) $Port/$($object.Protocol)?", $options, 0)
            
            switch ($result) {
                0 { 
                    Write-Host 'Updating cache...'
                    [array]$json.Daemon = $json.Daemon | Where-Object { $_.Service -ne $object.Service }
                    $json | ConvertTo-Json | Set-Content '.\data.json'
                    Write-Host "Knocking on port $($object.Port)/$($object.Protocol) has been disabled"
                    Read-Host -Prompt 'Press any key to continue...'
                    Write-Menu
                    return
                }
                1 { Write-Menu; return }
                Default { Write-Menu; return }
            }
        }
    }

    Write-Warning "Port $Port/$Protocol is not knocked"
    Read-Host -Prompt 'Press any key to continue...'
    Write-Menu

    
}

Function Get-KnockedPorts {
    param ()
    Clear-Screen
    Write-Banner

    $json = Get-Content '.\data.json' | ConvertFrom-Json
    $json.Daemon | Select-Object Service, Port, Protocol, OpenSequence, CloseSequence | Format-Table | Out-Host
    
    Read-Host -Prompt 'Press any key to continue... '
    Write-Menu
}

Function Get-PortStatus {
    param (
        [int]$Port,
        [string]$Protocol
    )

    $output = '' | Select-Object ServiceName, ErrorMessage
    if (!($Port -ge 1 -or $Port -le 65355)) {
        $output.ErrorMessage = 'Port cannot less than 1 and greater than 65535'
        return $output
    }

    if ($Protocol.ToLower() -eq 'tcp') {
        Get-NetTCPConnection -LocalPort $Port -ErrorAction Ignore | Out-Null
        if ($?) {
            $output.ServiceName = (Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess).ProcessName
        } else {
            $output.ErrorMessage = "No service is running on $Port/tcp"
        }
    } elseif ($Protocol.ToLower() -eq 'udp') {
        Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Ignore | Out-Null
        if ($?) {
            $output.ServiceName = (Get-Process -Id (Get-NetUDPEndpoint -LocalPort $Port).OwningProcess).ProcessName
        } else {
            $output.ErrorMessage = "No service is running on $Port/udp"
        }
    } else {
        $output.ErrorMessage = 'Invalid protocol'
    }

    return $output
    
}

Function Start-KnockdService {
    param ()
    Write-Host 'Starting windows firewall...'
    Write-Host 'Enabling logging for blocked requests...'
    Set-NetFirewallProfile -Enabled True -LogBlocked True
    $service = Get-Service -ErrorAction Ignore | Where-Object -Property Name -eq Knockd
    if ($null -ne $service) {
        if ($service.Status -eq 'Stopped') {
            Write-Host 'Starting Knockd service...'
            Start-Service Knockd
            if($?) {
                Write-Host 'Knockd service started successfully'
            } else {
                Write-Warning 'Something went wrong. Knockd not started'
            }
        } else {
            Write-Host 'Knockd is already running'
        }
    } else {
        $params = @{
            Name = 'Knockd'
            BinaryPathName = "$($PSScriptRoot)\knockd.ps1"
            DisplayName = 'Port Knocking Service'
            StartupType = 'Automatic'
            Description = 'Windows Port Knocking Service'
        }
        Write-Host 'Creating Knockd service'
        New-Service @params
        Write-Host 'Starting Knockd service...'
        Start-Service Knockd
        if($?) {
            Write-Host 'Knockd service started successfully'
        } else {
            Write-Warning 'Something went wrong. Knockd not started'
        }
    }
    Read-Host -Prompt "`nPress any key to continue..."
    Write-Menu
}

Function Stop-KnockdService {
    param ()
    Clear-Screen
    Write-Banner

    Stop-Service Knockd -ErrorAction Ignore
    if ($?) {
        Write-Host 'Knockd service has been stopped'
    } else {
        Write-Warning 'Something went wrong'
    }
    Write-Host ''
    Read-Host -Prompt 'Press any key to continue'
    Write-Menu
}

Function Get-KnockdStatus {
    param ()
    Clear-Screen
    Write-Banner

    Get-Service Knockd -ErrorAction Ignore
    if(!$?) {
        Write-Warning "Knockd service doesn't exist"
    }
    Read-Host -Prompt 'Press any key to continue...'
    Write-Menu
}

Write-Menu
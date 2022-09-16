<#
.SYNOPSIS
    Lock/Unlock ports by knocking closed ports

.DESCRIPTION
    A longer description.

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
    Write-Host "*******                    **         **   **                           **                   "
    Write-Host "/**////**                  /**        /**  **                           /**                   "
    Write-Host "/**   /**  ******  ****** ******      /** **   *******   ******   ***** /**  **  *****  ******"
    Write-Host "/*******  **////**//**//*///**/       /****   //**///** **////** **///**/** **  **///**//**//*"
    Write-Host "/**////  /**   /** /** /   /**        /**/**   /**  /**/**   /**/**  // /****  /******* /** / "
    Write-Host "/**      /**   /** /**     /**        /**//**  /**  /**/**   /**/**   **/**/** /**////  /**   "
    Write-Host "/**      //****** /***     //**       /** //** ***  /**//****** //***** /**//**//******/***   "
    Write-Host "//        //////  ///       //        //   // ///   //  //////   /////  //  //  ////// /// "
    Write-Host "                                                                              by @Tomiwa-Ot"
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
    Write-Host "7: Exit"
    Write-Host ""

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

Function Get-FirewallState {
    param()
    # check if firewall is enabled and also logging
}


Function Enable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner

    $port = Read-Host -Prompt 'Enter port to knock (1 - 65535) '
    $openSequence = (Read-Host -Prompt "Enter knock sequence for unlocking $port (use commas to seperate values)").Split(',')
    $closeSequence = (Read-Host -Prompt "Enter knock sequence for locking $port (use commas to seperate values)").Split(',')
    
    $output = Get-PortStatus -Port $port
    if ($null -ne $output.ErrorMessage) {
        Write-Warning $output.ErrorMessage
        Read-Host -Prompt 'Press any key to continue... '
        Write-Menu
        return
    }

    foreach ($value in $openSequence) {
        if (!([int]$value -ge 1 || [int]$value -le 65355)) {
            Write-Warning 'Port cannot less than 1 and greater than 65535'
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
        Get-NetTCPConnection -LocalPort [System.UInt16]$value -ErrorAction Ignore | Out-Null
        if ($?) {
            $service = (Get-Process -Id (Get-NetTCPConnection -LocalPort [int]$value).OwningProcess).ProcessName
            Write-Warning "Cannot use port $value in open sequence, $service is using it"
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
    }

    foreach ($value in $closeSequence) {
        if (!([int]$value -ge 1 || [int]$value -le 65355)) {
            Write-Warning 'Port cannot less than 1 and greater than 65535'
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
        Get-NetTCPConnection -LocalPort [int]$value -ErrorAction Ignore | Out-Null
        if ($?) {
            $service = (Get-Process -Id (Get-NetTCPConnection -LocalPort [int]$value).OwningProcess).ProcessName
            Write-Warning "Cannot use port $value in close sequence, $service is using it"
            Read-Host -Prompt 'Press any key to continue...'
            Write-Menu
            return
        }
    }

    $yes  = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Proceed to knock port')
    $no = [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Stop process')

    Write-Host "Port: $port/tcp"
    Write-Host "Service: $($output.ServiceName)"
    Write-Host "Open Sequence: $openSequence"
    Write-Host "Close Sequence: $closeSequence"
    Write-Host ""

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.UI.PromptForChoice('', "Are you sure want to knock $($output.ServiceName) $Port/tcp?", $options, 0)
    
    switch ($result) {
        0 { 
            Write-Host ''
            Write-Host 'Writing to cache ...'
            Add-JsonCache -Service $output.ServiceName -Port $port -OpenSequence $openSequence -CloseSequence $closeSequence
            # Set-NetFirewallProfile -Enabled True -LogBlocked True
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
        [array]$OpenSequence,

        [Parameter(Mandatory)]
        [array]$CloseSequence
    )

    $json = Get-Content '.\data.json' | ConvertFrom-Json
    $data = "" | Select-Object Service, Port, OpenSequence, CloseSequence
    $data.Service = $Service
    $data.Port = $Port
    $data.OpenSequence = $OpenSequence
    $data.CloseSequence = $CloseSequence
    $json.Daemon += $data

    $json | Set-Content '.\data.json'
}

Function Disable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner

    $Port = Read-Host -Prompt 'Enter knocked port to disable '
    $json = Get-Content '.\data.json' | ConvertFrom-Json
    foreach ($object in $json.Daemon) {
        if ($object.Port -eq $Port) {
            $yes  = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', "Disable knocking on port $($object.Port)/tcp $($object.Service)")
            $no = [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Cancel')
            
            Write-Host ""
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $result = $host.UI.PromptForChoice('', "Are you sure disable knocking on $($object.Service) $Port/tcp?", $options, 0)
            
            switch ($result) {
                0 { 
                    $index = [array]::IndexOf($json.Daemon, $object)
                    # remove object from json
                    Write-Host 'Updating cache...'
                    $json | Set-Content '.\data.json'
                    Write-Host 'Restarting knockd service...'
                    # restart service
                    Write-Host "Knocking on port $($object.Port) has been disabled"
                    Read-Host -Prompt 'Press any key to continue...'
                    Write-Menu
                    return
                }
                1 { Write-Menu; return }
                Default { Write-Menu; return }
            }
        }
    }

    Write-Warning "Port $Port is not knocked"
    Read-Host -Prompt 'Press any key to continue...'
    Write-Menu

    
}

Function Get-KnockedPorts {
    param ()
    Clear-Screen
    Write-Banner

    $json = Get-Content '.\data.json' | ConvertFrom-Json | Select-Object -Expand Daemon
    $json | Select-Object Service, Port, OpenSequence, CloseSequence | Out-Host
    
    Read-Host -Prompt 'Press any key to continue... '
    Write-Menu
}

Function Get-PortStatus {
    param (
        [int]$Port
    )

    $output = '' | Select-Object ServiceName, ErrorMessage
    if (!($Port -ge 1 || $Port -le 65355)) {
        $output.ErrorMessage = 'Port cannot less than 1 and greater than 65535'
        return $output
    }

    Get-NetTCPConnection -LocalPort $Port -ErrorAction Ignore | Out-Null
    if ($?) {
        $output.ServiceName = (Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess).ProcessName
    } else {
        $output.ErrorMessage = "No service is running on $Port'/tcp"
    }

    return $output
    
}

Function Start-KnockdService {
    param ()
    $service = Get-Service -ErrorAction Ignore | Where-Object -Property Name -eq Knockd
    if ($?) {
        if ($service.Status -eq 'Stopped') {
            Write-Host 'Starting Knockd service...'
            Start-Service Knockd
        } else {
            Write-Host 'Knockd is already running'
        }
    } else {
        $params = @{
            Name = 'Knockd'
            BinaryPathName = ""
            DisplayName = 'Port Knocking Service'
            StartupType = 'Automatic'
            Description = 'Windows Port Knocking Service'
        }
        Write-Host 'Creating Knockd service'
        New-Service @params
        Write-Host 'Starting Knockd service' # move knockd file to a location
        Start-Service Knockd
    }
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
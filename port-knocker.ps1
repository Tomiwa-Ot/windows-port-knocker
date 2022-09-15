<#
.SYNOPSIS
    Enable/Disable port knocking for a service

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

    Write-Host "1: Knock a port"
    Write-Host "2: Disable knocking for a port"
    Write-Host "3: List knocked ports"
    Write-Host "4: Exit"
    Write-Host ""

    $choice = Read-Host -Prompt '> '

    switch ($choice) {
        1 { Enable-PortKnocking }
        2 { Disable-PortKnocking }
        3 { Get-KnockedPorts }
        4 { Clear-Screen }
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
    $knockPorts = Read-Host -Prompt 'Enter ports to listen for knock ' # check if knockPorts are running a service
    
    $output = Get-PortStatus -Port $port
    if ($null -ne $output.ErrorMessage) {
        Write-Warning $output.ErrorMessage
        Read-Host -Prompt 'Press any key to continue... '
        Write-Menu
        return
    }

    $yes  = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Proceed to knock port')
    $no = [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Stop process')

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.UI.PromptForChoice('', "Are you sure want to knock $($output.ServiceName) $Port/tcp?", $options, 0)
    
    switch ($result) {
        0 { 

            Set-NetFirewallProfile -Enabled True -LogBlocked True
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
        [array]$KnockPorts
    )

    $json = Get-Content '.\data.json' | ConvertFrom-Json
    $data = "" | Select-Object Service, Port, KnockPorts
    $data.Service = $Service
    $data.Port = $Port
    $data.KnockPorts = $KnockPorts
    $json.Daemon += $data

    $json | Set-Content '.\data.json'
}

Function Disable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner

    $Port = Read-Host -Prompt 'Enter knocked port to disable '
    $json = Get-Content '.\data.json'
    foreach ($object in $json.Daemon) {
        if ($object.Port -eq $Port) {
            $index = [array]::IndexOf($json.Daemon, $object)
            # remove object from json
            $json | Set-Content '.\data.json'
            Write-Menu
            return
        }
    }

    Write-Warning "$Port is not knocked"
    Read-Host -Prompt 'Press any key to continue...'
    Write-Menu

    
}

Function Get-KnockedPorts {
    param ()
    Clear-Screen
    Write-Banner

    $json = Get-Content '.\data.json' | ConvertFrom-Json | Select-Object -Expand Daemon
    $json | Select-Object Service, Port, KnockPorts | Out-Host
    
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
    
}


Write-Menu
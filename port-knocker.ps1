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
    $protocol = Read-Host -Prompt 'Enter protocol (tcp/udp) '
    
    $output = Get-PortStatus -Port $port -Protocol $protocol
    if ($null -ne $output.ErrorMessage) {
        if ($output.InvalidPort) {
            Write-Warning $output.ErrorMessage
        } elseif ($output.NoService) {
            Write-Warning $output.ErrorMessage
        } elseif ($output.InvalidProtocol) {
            Write-Warning $output.ErrorMessage
        }
        Read-Host -Prompt 'Press any key to continue... '
        Write-Menu
        return
    }

    $yes  = [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Proceed to knock port')
    $no = [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Stop process')

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.UI.PromptForChoice('', 'Are you sure want to knock daemon/port tcp?', $options, 0)
    
    switch ($result) {
        0 { 

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
        [string]$Protocol,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [array]$KnockPorts
    )

    $json = Get-Content '.\data.json' | ConvertFrom-Json
    $data = "" | Select-Object Service, Protocol, Port, KnockPorts
    $data.Service = $Service
    $data.Protocol = $Protocol
    $data.Port = $Port
    $data.KnockPorts = $KnockPorts
    $json.Daemon += $data

    $json | Set-Content '.\data.json'
}

Function Disable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner


}

Function Get-KnockedPorts {
    param ()
    Clear-Screen
    Write-Banner

    $json = Get-Content '.\data.json' | ConvertFrom-Json | Select-Object -Expand Daemon
    $json | Select-Object Service, Protocol, Port, KnockPorts | Out-Host
    
    Read-Host -Prompt 'Press any key to continue... '
    Write-Menu
}

Function Get-PortStatus {
    param (
        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [string]$Protocol
    )

    $output = '' | Select-Object ServiceName, ErrorMessage, InvalidPort, InvalidProtocol, NoService
    if (!($Port -ge 1 || $Port -le 65355)) {
        $output.ErrorMessage = 'Port cannot less than 1 and greater than 65535'
        $output.InvalidPort = $true
        return $output
    }

    if ($Protocol.ToLower() -eq 'tcp') {
        Get-NetTCPConnection -LocalPort $Port -ErrorAction Ignore | Out-Null
        if ($?) {
            $output.ServiceName = Get-Process -Id (Get-NetTCPConnection -LocalPort $Port).OwningProcess | Select-Object ProcessName
        } else {
            $output.ErrorMessage = 'No service is running on ' + $Port + '/tcp'
            $output.NoService = $true
        }
    } elseif ($Protocol.ToLower() -eq 'udp') {
        Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Ignore | Out-Null
        if ($?) {
            $output.ServiceName = Get-Process -Id (Get-NetUDPEndpoint -LocalPort $Port).OwningProcess | Select-Object ProcessName
        } else {
            $output.ErrorMessage = 'No service is running on ' + $Port + '/udp'
            $output.NoService = $true
        }
    } else {
        $output.ErrorMessage = 'Invalid protocol specified'
        $output.InvalidProtocol = $true
    }

    return $output
    
}

Function Start-KnockdService {
    param ()
    
}


Write-Menu
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

Function Enable-FireWall {
    param ()
    
}

Function Enable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner

    $port = Read-Host -Prompt 'Enter port to knock: '
    # check if port is enabled and also the service running on the port

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

Function Disable-PortKnocking {
    param ()
    Clear-Screen
    Write-Banner


}

Function Get-KnockedPorts {
    param ()
    Clear-Screen
    Write-Banner


}

Function Get-PortStatus {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array] $Ports
    )

    foreach ($port in $Ports) {
        if ($port -ge 1 && $port -le 65355) { # check if port is being used by another service
            
        }
    }
    
}

Write-Menu
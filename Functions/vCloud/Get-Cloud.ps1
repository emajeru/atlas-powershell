Function Get-Cloud {
  <#
  .SYNOPSIS
    Pulls the cloud build data from an existing Organization

  .DESCRIPTION
    Queries an organizatino and pulls all data relevant to the CloudBuild object so that it can be exported, monitored or cloned.

  .EXAMPLE
    Get-Cloud -OrgName <org-name>

  .PARAMETER OrgName
    The Name of the organization to query against
  #>
  Param(
    [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()][Alias("-o","Org")][string[]]$OrgName
  )

  Begin{
    $Org = Get-Org -Name $OrgName
    $OrgUsers = @()
    $OrgVDCs = @()
    $NSXEdges = @()
  }

  Process{
    $Build = New-Object CloudBuild

    Write-Verbose "Using $Org"
    $OrgInfo = [ordered]@{
      'Name' = $Org.Name
      'FullName' = $Org.FullName
      'Description' = $Org.Description
    }

    $Cur_Users = Get-CIUser -Org $Org -ErrorAction SilentlyContinue | ?{$_.External -eq $False}

    Write-Verbose "Starting computing users"
    ForEach($Cur_User in $Cur_Users) {
      $Cur_User_View = $Cur_User | Get-CIView
      Write-Verbose "Starting Computing $($Cur_User_View.Name)"
      $New_User = [ordered]@{
        'Name' = $Cur_User_View.Name
        'Password' = $Cur_User_View.Password
        'FullName' = $Cur_User_View.Fullname
        'Role' = $Cur_User_View.Role.Name
      }

      $OrgUsers += $New_User
      Write-Verbose "Completed Computing $($Cur_User_View.Name)"
    }

    $Cur_Vdcs = Get-OrgVdc -Org $Org

    Write-Verbose "Starting computing vDCs"
    Foreach ($Cur_Vdc in $Cur_Vdcs) {
      $New_OrgVdc = [ordered]@{
        'Name' =  $Cur_Vdc.Name
        'CPU' = $Cur_Vdc.CpuAllocationGhz
        'MEM' = $Cur_Vdc.MemoryAllocationGB
        'Storage' = $Cur_Vdc.StorageLimitGB
        'Networks' = @()
      }

      $Cur_Vdc_Networks = Get-OrgVdcNetwork -OrgVdc $Cur_Vdc.Name
      Write-Verbose "Starting computing vDCs"
      ForEach($Cur_Network in $Cur_Vdc_Networks) {
        $Cur_Network_View =  $Cur_Network | Get-CiView
        Switch ($Cur_Network_View.Configuration.FenceMode) {
          "natRouted" {
            $Mode = "Routed"
          }
          "isolated" {
            $Mode = "Isolated"
          }
          "bridged" {
            $Mode = "Direct"
          }
        }
        $New_Network = [ordered]@{
          'Name' = $Cur_Network_View.Name
          'Type' = $Mode
          'Description' = $Cur_Network_View.Description
          'Shared' = $Cur_Network_View.IsShared
          'Network' = [ordered]@{
            'Gateway' = $Cur_Network_View.Configuration.IPScopes.IPScope.Gateway
            'Mask' = $Cur_Network_View.Configuration.IPScopes.IPScope.NetMask
            'StartAddress' = $Cur_Network_View.Configuration.IPScopes.IPScope.IpRanges.IpRange.StartAddress
            'EndAddress' = $Cur_Network_View.Configuration.IPScopes.IPScope.IpRanges.IpRange.EndAddress
            'DNS1' = $Cur_Network_View.Configuration.IPScopes.IPScope.DNS1
            'DNS2' = $Cur_Network_View.Configuration.IPScopes.IPScope.DNS2
          }
        }
        $New_OrgVdc.Networks += $New_Network
      }
      $OrgVdcs += $New_OrgVdc
    }
    
    $Cur_NSX_Edges = Get-EdgeGateway -Org $Org
    Write-Verbose "Starting computing vDCs"
    ForEach ($Cur_NSX_Edge in $Cur_NSX_Edges) {
      $Cur_NSX_Edge_View = $Cur_NSX_Edge | Get-CIView
      $New_NsxEdge = [ordered]@{
        'Name' = $Cur_NSX_Edge_View.Name
        'ExternalNetwork' = $Cur_NSX_Edge_View.ExternalNetwork
        'IPAddress' = $Cur_NSX_Edge_View.Configuration.GatewayInterfaces.GatewayInterface | ?{$_.InterfaceType -eq 'uplink'} | %{$_.SubnetParticipation.IPAddress}
        'SubnetMask' = $Cur_NSX_Edge_View.Configuration.GatewayInterfaces.GatewayInterface | ?{$_.InterfaceType -eq 'uplink'} | %{$_.SubnetParticipation.NetMask}
        'Gateway' = $Cur_NSX_Edge_View.Configuration.GatewayInterfaces.GatewayInterface | ?{$_.InterfaceType -eq 'uplink'} | %{$_.SubnetParticipation.Gateway}
        'Tunnels' = @()
      }
      $Cur_Tunnels = Get-EdgeTunnel $Cur_NSX_Edge_View.Name
      ForEach($Tunnel in $Cur_Tunnels.Tunnels) {
        $New_NsxEdge.Tunnels += $Tunnel
      }
      $NsxEdges += $New_NsxEdge
    }
    
    $Build.Org = $OrgInfo
    $Build.OrgUsers = $OrgUsers
    $Build.OrgVdcs = $OrgVdcs
    $Build.NsxEdges = $NsxEdges
  }

  End{
    return $Build
  }
}
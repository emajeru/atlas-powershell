Function New-CloudNetwork {
  <#
  .SYNOPSIS
    Creates client organization networks within a vDC
  
  .DESCRIPTION
    Creates client organization networks within a vDC

  .EXAMPLE
    New-CloudNetwork

  .PARAMETER Type
  .PARAMETER ServerName
  .PARAMETER OrgVdcName
  .PARAMETER EdgeName
  .PARAMETER Name
  .PARAMETER Description
  .PARAMETER IsShared
  .PARAMETER Gateway
  .PARAMETER Netmask
  .PARAMETER Dns1
  .PARAMETER Dns2
  .PARAMETER StartAddress
  .PARAMETER EndAddress

  #>

  Param (
    [Parameter(Mandatory=$False)][String]$Type,
    [Parameter(Mandatory=$False)][String]$ServerName,
    [Parameter(Mandatory=$False)][String]$OrgName,
    [Parameter(Mandatory=$False)][String]$OrgVdcName,
    [Parameter(Mandatory=$False)][String]$EdgeName,
    [Parameter(Mandatory=$False)][String]$Name,
    [Parameter(Mandatory=$False)][String]$Description,
    [Parameter(Mandatory=$False)][String]$IsShared,
    [Parameter(Mandatory=$False)][String]$Gateway,
    [Parameter(Mandatory=$False)][String]$Netmask,
    [Parameter(Mandatory=$False)][String]$Dns1,
    [Parameter(Mandatory=$False)][String]$Dns2,
    [Parameter(Mandatory=$False)][String]$StartAddress,
    [Parameter(Mandatory=$False)][String]$EndAddress
  )

  Begin {
  }
  Process {
    

    Switch($Type) {

      "Direct" {
        #Create a direct connect network
        $OrgVdcView = Get-OrgVdc -Server $ServerName $OrgvDCName | Get-CIView
        $ExtNetwork = $_.externalnetwork
        $ExtNetwork = Get-ExternalNetwork -Server $ServerName | Get-CIView | ?{$_.name -like "$ExternalNetwork"}
        $OrgNetwork = New-Object VMware.VimAutomation.Cloud.Views.OrgvDCNetwork
        $OrgNetwork.name = "$OrgName-RoutedNet01"
        $OrgNetwork.Configuration = New-Object VMware.VimAutomation.Cloud.Views.NetworkConfiguration
        $OrgNetwork.Configuration.FenceMode = 'bridged'
        $OrgNetwork.Configuration.ParentNetwork = New-Object VMware.VimAutomation.Cloud.Views.Reference
        $OrgNetwork.Configuration.ParentNetwork.href = $ExtNetwork.href
        
        $result = $OrgvDCView.CreateNetwork($OrgNetwork)

        $OrgvDCView
      }

      "Routed" {
        $OrgVdcView = Get-OrgVdc -Server $ServerName $OrgVdcName | Get-CIView
        $EdgeGateway = Get-EdgeGateway -Name $EdgeName | Get-CIView

        # Provision the device template
        $OrgNetwork = New-Object VMware.VimAutomation.Cloud.Views.OrgVdcNetwork
        $OrgNetwork.Configuration = New-Object VMware.VimAutomation.Cloud.Views.NetworkConfiguration
        $OrgNetwork.Configuration.IpScopes = New-Object VMware.VimAutomation.Cloud.Views.IpScopes
        $OrgNetwork.Configuration.IpScopes.IpScope = New-Object VMware.VimAutomation.Cloud.Views.IpScope
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges = New-Object VMware.VimAutomation.Cloud.Views.IpRanges
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges.IpRange = New-Object VMware.VimAutomation.Cloud.Views.IpRange

        $OrgNetwork.Name = $Name
        $OrgNetwork.Description = $Description

        $OrgNetwork.EdgeGateway = $EdgeGateway.href
        $OrgNetwork.IsShared = $IsShared

        $OrgNetwork.Configuration.FenceMode = "natRouted"

        $OrgNetwork.Configuration.IpScopes.IpScope[0].IsInherited = $FALSE
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Gateway = $Gateway
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Netmask = $Netmask
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Dns1 = $Dns1
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Dns2 = $Dns2
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IsEnabled = $TRUE
        
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges.IpRange[0].StartAddress = $StartAddress
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges.IpRange[0].EndAddress = $EndAddress

        $result = $OrgvDCView.CreateNetwork($OrgNetwork)
      }

      "Isolated" {
        $OrgVdcView = Get-OrgVdc -Server $ServerName $OrgVdcName | Get-CIView

        # Provision the device template
        $OrgNetwork = New-Object VMware.VimAutomation.Cloud.Views.OrgVdcNetwork
        $OrgNetwork.Configuration = New-Object VMware.VimAutomation.Cloud.Views.NetworkConfiguration
        $OrgNetwork.Configuration.IpScopes = New-Object VMware.VimAutomation.Cloud.Views.IpScopes
        $OrgNetwork.Configuration.IpScopes.IpScope = New-Object VMware.VimAutomation.Cloud.Views.IpScope
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges = New-Object VMware.VimAutomation.Cloud.Views.IpRanges
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges.IpRange = New-Object VMware.VimAutomation.Cloud.Views.IpRange

        $OrgNetwork.Name = $Name
        $OrgNetwork.Description = $Description

        $OrgNetwork.IsShared = $IsShared

        $OrgNetwork.Configuration.FenceMode = "isolated"

        $OrgNetwork.Configuration.IpScopes.IpScope[0].IsInherited = $FALSE
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Gateway = $Gateway
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Netmask = $Netmask
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Dns1 = $Dns1
        $OrgNetwork.Configuration.IpScopes.IpScope[0].Dns2 = $Dns2
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IsEnabled = $TRUE
        
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges.IpRange[0].StartAddress = $StartAddress
        $OrgNetwork.Configuration.IpScopes.IpScope[0].IpRanges.IpRange[0].EndAddress = $EndAddress

        $result = $OrgvDCView.CreateNetwork($OrgNetwork)
      }
    }
  }
  End {}
}
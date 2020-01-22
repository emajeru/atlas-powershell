Function New-EdgeGateway {
<#
.SYNOPSIS
    Creates a new client NSX Edge

.DESCRIPTION
    Creates a new client NSX Edge within the given vOrg.

.EXAMPLE
    New-EdgeGateway -Server $ServerName -Edgename "<edge-name>" -OrgName <org-name> -OrgvDCName "<org-vdc-name>" -ExternalNetwork "01-tenant-external-net" -IPAddress "1.1.1.9" -SubnetMask "255.255.255.0" -Gateway "1.1.1.254"

.PARAMETER ServerName
    URL of the vCloud instance

.PARAMETER EdgeName
    Name of the new NSX Edge Gateway

.PARAMETER OrgName
    Name of the org that the Edge will be created under

.PARAMETER OrgvDCName
    Name of the Org vDC that the Edge will be created under

.PARAMETER ExternalNetwork
    External network that the Edge will be routed through

.PARAMETER IPAddress
    IP Address of the NSX Edge

.PARAMETER SubnetMask
    Subnet Mask of the NSX Edge Device

.PARAMETER Gateway
    Gateway of the internal network

.PARAMETER IPRangeStart
    Start of the Internal IP Range subnet

.PARAMETER IPRangeEnd
    End of the Internal IP Range subnet

.PARAMETER Timeout
    Timeout value used to query completion of the NSX Edge creation

    #>
    Param (
      [Parameter(Mandatory=$False, HelpMessage="URL of the vCloud instance")]
      [ValidateNotNullorEmpty()]    
      [String]$ServerName,
      [Parameter(Mandatory=$True, HelpMessage="Name of the new NSX Edge Gateway")]
      [ValidateNotNullorEmpty()]
      [String]$EdgeName,
      [Parameter(Mandatory=$True, HelpMessage="Name of the org that the Edge will be created under")]
      [ValidateNotNullorEmpty()]
      [String]$OrgName,
      [Parameter(Mandatory=$True, HelpMessage="Name of the Org vDC that the Edge will be created under")]
      [ValidateNotNullorEmpty()]
      [String]$OrgvDCName,        
      [Parameter(Mandatory=$True, HelpMessage="External network that the Edge will be routed through")]
      [ValidateNotNullorEmpty()]
      [String]$ExternalNetwork,
      [Parameter(Mandatory=$True, HelpMessage="IP Address of the NSX Edge")]
      [ValidateNotNullorEmpty()]
      [IPAddress]$IPAddress,
      [Parameter(Mandatory=$True, HelpMessage="Subnet Mask of the NSX Edge Device")]
      [ValidateNotNullorEmpty()]
      [IPAddress]$SubnetMask,
      [Parameter(Mandatory=$True, HelpMessage="Gateway of the internal network")]
      [ValidateNotNullorEmpty()]
      [IPAddress]$Gateway,
      [Parameter(Mandatory=$False, HelpMessage="Start of the Internal IP Range subnet")]
      [ValidateNotNullorEmpty()]
      [IPAddress]$IPRangeStart,
      [Parameter(Mandatory=$False, HelpMessage="End of the Internal IP Range subnet")]
      [ValidateNotNullorEmpty()]
      [IPAddress]$IPRangeEnd,
      [Parameter(Mandatory=$False, HelpMessage="Timeout value used to query completion of the NSX Edge creation")]
      [ValidateNotNullorEmpty()]
      [Int]$Timeout=120
      )
    Begin{
      Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of NSX Edge: $EdgeName ...Starting" -ForegroundColor Yellow
    }
    Process{
      $OrgvDC = Get-OrgVdc -Server $ServerName -Name $OrgvDCName -Org $OrgName

      If ($OrgvDC.Count -gt 1) {Throw "Found vDC"}
      elseif ($OrgvDC.Count -lt 1) {Throw "No vDC Found"}

      # Get External Network Information
      $Network = Get-ExternalNetwork -Server $ServerName | Get-CIView -Verbose:$False | ?{$_.Name -eq $ExternalNetwork}

      # Begin creation of the NSX Edge build
      $EdgeGateway = New-Object Vmware.VimAutomation.Cloud.Views.Gateway
      $EdgeGateway.Name = $Edgename
      $EdgeGateway.Configuration = New-Object VMware.VimAutomation.Cloud.Views.GatewayConfiguration

      $EdgeGateway.Configuration.GatewayBackingConfig = "compact"
      $EdgeGateway.Configuration.UseDefaultRouteForDNSRelay = $False
      $EdgeGateway.Configuration.HaEnabled = $False
      
      $EdgeGateway.Configuration.EdgeGatewayServiceConfiguration = New-Object VMware.VimAutomation.Cloud.Views.GatewayFeatures
      $EdgeGateway.Configuration.GatewayInterfaces = New-Object VMware.VimAutomation.Cloud.Views.GatewayInterfaces

      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface = New-Object VMware.VimAutomation.Cloud.Views.GatewayInterface
      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].Name = $Network.Name
      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].DisplayName = $Network.Name
      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].Network = $Network.Href
      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].InterfaceType = "uplink"
      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].UseForDefaultRoute = $True
      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].ApplyRateLimit = $False

      $Subnet = New-Object VMware.VimAutomation.Cloud.Views.SubnetParticipation
      $Subnet.Gateway = $Gateway.IPAddressToString
      $Subnet.Netmask = $SubnetMask.IPAddressToString
      $Subnet.IpAddress = $IPAddress.IPAddressToString
      #$Subnet.IpRanges = New-Object VMware.VimAutomation.Cloud.Views.IpRanges
      #$Subnet.IpRanges.IpRange = New-Object VMware.VimAutomation.Cloud.Views.IpRange
      #$Subnet.IpRanges.IpRange[0].StartAddress = $IPRangeStart.IPAddressToString
      #$Subnet.IpRanges.IpRange[0].EndAddress = $IPRangeEnd.IPAddressToString

      $EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[0].SubnetParticipation = $Subnet

      # Begin creation of the NSX Edge
      $OrgvDC.ExtensionData.CreateEdgeGateway($EdgeGateway) | Out-Null

      # Pasing until the gateway has been registered
      While((Search-Cloud -Server $ServerName -QueryType EdgeGateway -Name $EdgeName -Verbose:$False).IsBusy -eq $True) {
        $i++
        Start-Sleep 5
        If ($i -gt $Timeout) {Write-Error "Creating Edge Gateway."; Break}
        Write-Progress -Activity "Creating Edge Gateway" -Status "Wait for Edge to become Ready..."
      }
      Write-Progress -Activity "Creating Edge Cateway" -Completed
      Start-Sleep 1

      #Search-Cloud -Server $ServerName -QueryType EdgeGateway -Name $EdgeName | Select-Object Name, IsBusy, GatewayStatus, HaStatus | Format-Table -AutoSize
    }
    End{
      Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of NSX Edge: $EdgeName ...Done" -ForegroundColor Green
    }
  }
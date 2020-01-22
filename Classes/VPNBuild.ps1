Class VPNBuild  : AtlasBuild {
  $Tunnel = [ordered]@{
    'Name' = ''
    'Description' = ''
    'LocalEndpoint' = [ordered]@{
      'Id'  = ''
      'IpAddress' = ''
      'Subnet' = @()
    }
    'PeerEndpoint' = [ordered]@{
      'Id' = ''
      'IpAddress' = ''
      'Subnet' = @()
    }
    'EncryptionProtocol' = ''
    'SharedSecret' = ''
    'SharedSecretEncrypted' = ''
    'Mtu' = ''
    'IsEnabled' = ''
    # $IpsecVpnThirdPartyPeer
  }

  VPNBuild() {
    $this.Tunnel.Name = ''
    $this.Tunnel.Description = ''

    $this.Tunnel.LocalEndpoint.Id = ''
    $this.Tunnel.LocalEndpoint.IpAddress = ''
    $this.Tunnel.LocalEndpoint.Subnet += [ordered]@{
      'Name' = ''
      'Gateway' = ''
      'Netmask' = ''
    }

    $this.Tunnel.PeerEndpoint.Id = ''
    $this.Tunnel.PeerEndpoint.IpAddress = ''
    $this.Tunnel.PeerEndpoint.Subnet += [ordered]@{
      'Name' = ''
      'Gateway' = ''
      'Netmask' = ''
    }

    $this.Tunnel.EncryptionProtocol = ''
    $this.Tunnel.SharedSecret = ''
    $this.Tunnel.SharedSecretEncrypted = ''
    $this.Tunnel.Mtu = ''
    $this.Tunnel.IsEnabled = ''
    # $this.Tunnel.IpsecVpnPeer = New-Object Vmware.VimAutomation.Cloud.Views.IpsecVpnThirdPartyPeer
  }
  <# VPNBuild([string]$Name,[string]$Description,[string]$PeerIpAddress,[string]$PeerId,[string]$LocalIpAddress,[string]$LocalId,[string]$LocalSubnet,[string]$PeerSubnet,[string]$IpsecVpnThirdPartyPeer){
  #     $this.Tunnel = New-Object PSObject -Property @{
  #         'Name' = ''
  #         'Description' = ''
  #         'PeerIpAddress' = ''
  #         'PeerId' = ''
  #         'LocalIpAddress' = ''
  #         'LocalId' = ''
  #         'LocalSubnet' = ''
  #         'PeerSubnet' = ''
  #         # 'IpsecVpnThirdPartyPeer' = 'IpsecVpnThirdPartyPeer'
  #         # 'SharedSecretEncrypted' = $false
  #     }
  # }#>

  VPNBuild([string]$Buildfile) {
    if (Test-Path $Buildfile) {
      $VPNInfo = (Get-Content -Raw -File $Buildfile | ConvertFrom-Json)

      $this.Tunnel.Name = $VPNInfo.Name
      $this.Tunnel.IpsecVpnThirdPartyPeer = $Buildfile.IpsecVpnThirdPartyPeer
      $this.Tunnel.EncryptionProtocol = $VPNInfo.EncryptionProtocol
      $this.Tunnel.SharedSecret = $VPNInfo.SharedSecret
      $this.Tunnel.SharedSecretEncrypted = $VPNInfo.SharedSecretEncrypted
      $this.Tunnel.IsEnabled = $VPNInfo.IsEnabled
      $this.Tunnel.Mtu = $VPNInfo.Mtu
      $this.Tunnel.Description = $VPNInfo.Description
      $this.Tunnel.PeerIpAddress = $VPNInfo.PeerIpAddress
      $this.Tunnel.PeerId = $VPNInfo.PeerId
      $this.Tunnel.LocalIpAddress = $VPNInfo.LocalIpAddress
      $this.Tunnel.LocalId = $VPNInfo.LocalId
      $this.Tunnel.LocalSubnet = $VPNInfo.LocalSubnet
      $this.Tunnel.PeerSubnet = $VPNInfo.PeerSubnet
    }
    else {Write-Host 'No build file located.' -ForegroundColor Yellow}
  }

  VPNBuild([System.Xml.XmlElement]$VPNConfig) {
    $this.Tunnel.Name = $VPNConfig.Name
    $this.Tunnel.Description = $VPNConfig.Description

    $this.Tunnel.LocalEndpoint.Id = $VPNConfig.LocalId
    $this.Tunnel.LocalEndpoint.IpAddress = $VPNConfig.LocalIpAddress
    ForEach($Subnet in $VPNConfig.LocalSubnet) {
      $this.Tunnel.LocalEndpoint.Subnet += [ordered]@{
        'Name' = $Subnet.Name
        'Gateway' = $Subnet.Gateway
        'Netmask' = $Subnet.Netmask
      }
    }

    $this.Tunnel.PeerEndpoint.Id = $VPNConfig.PeerId
    $this.Tunnel.PeerEndpoint.IpAddress = $VPNConfig.PeerIpAddress
    ForEach($Subnet in $VPNConfig.PeerSubnet) {
      $this.Tunnel.PeerEndpoint.Subnet += [ordered]@{
        'Name' = $Subnet.Name
        'Gateway' = $Subnet.Gateway
        'Netmask' = $Subnet.Netmask
      }
    }

    $this.Tunnel.EncryptionProtocol = $VPNConfig.EncryptionProtocol
    $this.Tunnel.SharedSecret = $VPNConfig.SharedSecret
    $this.Tunnel.SharedSecretEncrypted = $VPNConfig.SharedSecretEncrypted
    $this.Tunnel.Mtu = $VPNConfig.Mtu
    $this.Tunnel.IsEnabled = $VPNConfig.IsEnabled
  }

  VPNBuild([switch]$Test) {
    $this.Tunnel = New-Object PSObject -Property @{
      'Name' = 'VPN-Test'
      'Description' = 'Test VPN to confirm operation'
      'PeerIpAddress' = '<peer-address>'
      'PeerId' = '<peer-address>'
      'PeerSubnet' = '{<peer-cidr-subnet>}'
      'LocalIpAddress' = '<local-address>'
      'LocalId' = '<local-address>'
      'LocalSubnet' = '{<local-cidr-subnet>}'
    }
  }
}
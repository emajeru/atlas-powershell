Function New-EdgeTunnel {
  param(
    [parameter(Mandatory=$false,ValueFromPipeline=$true)][alias("-edge","e")][string]$edgeName="<gateway-name>",
    [string]$vpnName="$($edgeName)_vpn-01",
    [string]$vpnDesc="A tester for the Atlas VPN module",
    [string]$pIP="1.1.1.2",
    [string]$pNetName = "1.1.2.0/24",
    [string]$pNet= '1.1.1.1',
    [string]$lIP="1.1.2.2",
    [string]$lNetName = "$($vpnName)_routed-network-01",
    [string]$lNet= '1.1.2.1',
    [string]$proto="AES",
    [bool]$isEnabled=$true,
    [bool]$isOperational=$true,
    [string]$SharedSecret="<key>",
    [string]$vpnType="Remote"
    )

  try {
    $edgeview = Search-Cloud -QueryType EdgeGateway -Name $edgename -ErrorAction Stop | Get-CIView
  }
  catch{
    [System.Windows.Forms.MessageBox]::Show("Exception: " + $_.Exception.Message + " - Failed item:" + $_.Exception.ItemName ,"Error.",0,[System.Windows.Forms.MessageBoxIcon]::Exclamation)
    Exit
  }

  # Get Existing Rules
  $webclient = New-Object System.Net.Webclient
  $webclient.headers.add('x-vcloud-authorization',$edgeview.client.sessionkey)
  Write-Verbose "Header will be $($edgeview.Type)"
  $webclient.headers.add('accept',$edgeview.Type + ';version=5.5')
  Write-Verbose -Message "$($webclient.headers)"

  [xml]$edgexml = $webclient.downloadstring($edgeview.href)

  $vpnservice = New-Object Vmware.VimAutomation.Cloud.Views.gatewayipsecvpnservice
  $curvpnservice = $edgexml.edgegateway.configuration.EdgeGatewayServiceConfiguration.gatewayipsecvpnservice

  $tunnels = @()

  if($curvpnservice.tunnel.HasChildNodes) {
    $curvpnservice.tunnel | %{
      $tunnel = New-Object VMware.VimAutomation.Cloud.Views.GatewayIpsecVpnTunnel -Property @{
          Name = $_.Name;
          Description = $_.Description;
          PeerIpAddress = $_.PeerIpAddress;
          PeerId = $_.PeerId;
          LocalIpAddress = $_.LocalIpAddress;
          LocalId = $_.LocalId;
          LocalSubnet = New-Object VMware.Vimautomation.Cloud.Views.IpsecVpnSubnet -Property @{
            Gateway = $_.LocalSubnet.Gateway;
            Netmask = $_.LocalSubnet.Netmask;
            Name = $_.LocalSubnet.Name
          };
          PeerSubnet = New-Object VMware.Vimautomation.Cloud.Views.IpsecVpnSubnet -Property @{
            Gateway = $_.PeerSubnet.Gateway;
            Netmask = $_.PeerSubnet.Netmask;
            Name = $_.PeerSubnet.Name
          };
          SharedSecret = $_.SharedSecret;
          SharedSecretEncrypted = $_.SharedSecretEncrypted;
          EncryptionProtocol = $_.EncryptionProtocol;
          Mtu = $_.Mtu;
          IsEnabled = $_.IsEnabled;
          IsOperational = $_.IsOperational;
          IpsecVpnPeer = New-Object Vmware.VimAutomation.Cloud.Views.IpsecVpnThirdPartyPeer -Property @{
            PeerId = $_.IpsecVpnPeer.PeerId
          }
          # IpsecVpnLocalPeer = $_.IpsecVpnLocalPeer
      }
      $tunnels += $tunnel
    }
  }

  $vpnbuild = New-Object VMware.VimAutomation.Cloud.Views.GatewayIpsecVpnTunnel
  $vpnbuild.Name = $vpnName
  $vpnbuild.Description = $vpnDesc
  $vpnbuild.IpsecVpnPeer = New-Object Vmware.VimAutomation.Cloud.Views.IpsecVpnThirdPartyPeer
  $vpnbuild.IpsecVpnPeer.PeerId = $pIP
  $vpnbuild.PeerIpAddress = $pIP
  $vpnbuild.PeerId = $pIP
  $vpnbuild.LocalIpAddress = $lIP
  $vpnbuild.LocalId = $lIP
  $vpnbuild.LocalSubnet = New-Object VMware.Vimautomation.Cloud.Views.IpsecVpnSubnet

  $vpnbuild.LocalSubnet | %{
    $_.Gateway = $lNet;
    $_.Netmask = '255.255.255.0';
    $_.Name = $lNetName
  }
  $vpnbuild.PeerSubnet = New-Object VMware.Vimautomation.Cloud.Views.IpsecVpnSubnet
  $vpnbuild.PeerSubnet | %{
    $_.Gateway = $pNet;
    $_.Netmask = '255.255.255.0';
    $_.Name = $pNetName
  }
  $vpnbuild.SharedSecret = $SharedSecret
  $vpnbuild.SharedSecretEncrypted = "false"
  $vpnbuild.EncryptionProtocol = $proto
  $vpnbuild.IsEnabled = [string]$isEnabled
  $vpnbuild.IsOperational = [string]$isOperational
  $vpnbuild.Mtu = "1500"

  $tunnels += $vpnbuild

  ForEach($tunnel in $tunnels) {
    $vpnservice.tunnel += $tunnel
  }

  $vpnservice.tunnel

  $vpnservice.endpoint = $curvpnservice.endpoint
  $vpnservice.isEnabled = $curvpnservice.IsEnabled
  $edgeview.ConfigureServices($vpnservice)
}
Function Get-EdgeTunnel {
  param(
    [parameter()][alias("-edge","e")][string]$edgename="<edge-name>"
    )

  # Find the Edge to assign the rule to
  try {
    $Edgeview = Search-Cloud -QueryType EdgeGateway -Name $edgename -ErrorAction Stop | Get-CIView
  }
  catch{
    [System.Windows.Forms.MessageBox]::Show("Exception: " + $_.Exception.Message + " - Failed item:" + $_.Exception.ItemName ,"Error.",0,[System.Windows.Forms.MessageBoxIcon]::Exclamation)
    Exit
  }

  # Get Existing Rules
  $Webclient = New-Object System.Net.Webclient
  $Webclient.headers.add('x-vcloud-authorization',$Edgeview.client.sessionkey)
  Write-Verbose "Header will be $($Edgeview.Type)"
  $Webclient.headers.add('accept',$Edgeview.Type + ';version=5.5')
  Write-Verbose -Message "$($Webclient.headers)"

  [xml]$Edgexml = $Webclient.downloadstring($Edgeview.href)

  $Tunnels = [ordered]@{
    'Tunnels' = @()
  }

  $VPNTunnels = $Edgexml.edgegateway.configuration.EdgeGatewayServiceConfiguration.gatewayipsecvpnservice.tunnel
  if ($VPNTunnels) {
    foreach ($VPNTunnel in $VPNTunnels) {
      $Tunnel = New-Object VPNBuild $VPNTunnel
      $Tunnels.Tunnels += $Tunnel.Tunnel
    }
  }
  return $Tunnels
}
Function Get-EdgeNATRules {
  Param (
    [parameter(Mandatory = $true, HelpMessage="Edge Gateway Name")][alias("-edge","e")][ValidateNotNullOrEmpty()][string[]]$EdgeName,
    [parameter(Mandatory = $false, HelpMessage="Backup Edge rules")][alias("-backup","b")][switch]$Backup,
    [parameter(Mandatory = $false, HelpMessage="Backup File path")][alias("-filepath","f")][ValidateNotNullOrEmpty()][string]$FilePath
    )

  #Search EdgeGW
  try {
    $edgeView = Search-Cloud -QueryType EdgeGateway -Name $EdgeName -ErrorAction Stop | Get-CIView
  } 
  catch {
    [System.Windows.Forms.MessageBox]::Show("Exception: " + $_.Exception.Message + " - Failed item:" + $_.Exception.ItemName ,"Error.",0,[System.Windows.Forms.MessageBoxIcon]::Exclamation)
    Exit
  }

  # Get Existing Rules
  $webclient = New-Object System.Net.Webclient
  $webclient.headers.add('x-vcloud-authorization',$edgeview.client.sessionkey)
  $webclient.headers.add('accept',$edgeview.Type + ';version=5.5')

  [xml]$edgeconfxml = $webclient.downloadstring($edgeview.href)

  $NatRules = $edgeconfxml.edgegateway.configuration.edgegatewayserviceconfiguration.NatService.NatRule

  $oldRules = @()
  $NatRules | %{
    $oldRule = New-Object PSObject -Property @{
      RuleType = $_.RuleType;
      IsEnabled = $_.IsEnabled;
      OriginalIP = $_.GatewayNatRule.OriginalIP;
      TranslatedIP = $_.GatewayNatRule.TranslatedIP;
      Interface = $_.GatewayNatRule.Interface.Name
    }
    $oldRules += $oldRule
  }

  if($Backup -and $FilePath) {
    $oldrules | Export-CSV -path "$filepath/$edgename-natrules-backup_$(Get-Date -format "yyyyMMdd_hhmm").csv" -notypeinformation
  }
  elseif($Backup -and !($FilePath)) {
    $oldrules | Export-CSV -path "$edgename-natrules-backup_$(Get-Date -format "yyyyMMdd_hhmm").csv" -notypeinformation
  }
  else {$oldRules | Out-GridView}
}
Function New-EdgeNatRules {
  Param (
    [parameter(Mandatory = $true, HelpMessage="Edge Gateway Name")][alias("-edge","e")][ValidateNotNullOrEmpty()][string[]]$EdgeName,
    [parameter(Mandatory = $true, HelpMessage="CSV Path")][alias("-file","f")][ValidateNotNullOrEmpty()][string[]]$FileName,
    [parameter(Mandatory = $false, HelpMessage="Erase Current Rules")][alias("-clobber","c")][switch]$Clobber,
    [parameter(Mandatory = $false, HelpMessage="Debug")][alias("-debug","d")][switch]$DebugMode,
    [parameter(Mandatory = $false, HelpMessage="Debug Harder")][alias("-thorough","t")][switch]$Thorough
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
  $newRules = @()
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

  $natService = New-Object vmware.vimautomation.cloud.views.natService
  $natService.IsEnabled = $true
  $natService.NatRule = @()
  $rowNum = 0

  Import-CSV -Path $FileName | ForEach-Object {
    $newRule = New-Object PSObject -Property @{
      RuleType = $_.RuleType;
      IsEnabled = $_.IsEnabled;
      OriginalIP = $_.OriginalIP;
      TranslatedIP = $_.TranslatedIP;
      Interface = $_.Interface
    }
    $newRules += $newRule
  }

  $Ruleset = $newRules
  If($oldRules -and (!($Clobber))) {$Ruleset += $oldRules}

  $Ruleset | ForEach-Object {
    $natService.NatRule += New-Object vmware.vimautomation.cloud.views.NatRule

    $natService.NatRule[$rowNum].RuleType = $_.RuleType
    $natService.NatRule[$rowNum].IsEnabled = $_.IsEnabled
    $natService.NatRule[$rowNum].GatewayNatRule = New-Object vmware.vimautomation.cloud.views.NatRule.GatewayNatRule

    $natService.NatRule[$rowNum].GatewayNatRule.OriginalIP = $_.OriginalIP
    $natService.NatRule[$rowNum].GatewayNatRule.TranslatedIP = $_.TranslatedIP

    $natService.NatRule[$rowNum].GatewayNatRule.Interface = New-Object vmware.vimautomation.cloud.views.NatRule.GatewayNatRule.Interface

    $natInterface = Get-ExternalNetwork $_.Interface | Get-CIView
    $natService.NatRule[$rowNum].GatewayNatRule.Interface.Name = $_.Interface
    $natService.NatRule[$rowNum].GatewayNatRule.Interface.href = $natInterface.Href
    $natService.NatRule[$rowNum].GatewayNatRule.Interface.type = $natInterface.Type

    if($DebugMode -and $Thorough) {$natRule.NatRule[$rowNum] | Format-Table}
    $rowNum++
  }

  if($DebugMode -and $Thorough) {$natRule.NatRule | Format-Table}

  if(!($DebugMode)) {
    #configure Edge
    try {
      $edgeView.ConfigureServices($natService)
      Write-Host "New Edge NAT Rules added successfully on $($EdgeName)" -ForegroundColor Green
    }
    catch {
      Write-Host "Unable to add new NAT rules to $($EdgeName)" -ForegroundColor Red
    }
  }
}
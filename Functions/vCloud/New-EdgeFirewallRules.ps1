Function New-EdgeFirewallRules {
<#
.SYNOPSIS
    Add new firewall rules to an NSX Edge Gateway

.DESCRIPTION
    Retrieves all Listed firewall rules on an Edge Gateway and appends the new rules from a CSV file to them.

.EXAMPLE
    New-EdgeFirewallRules -EdgeName '<gateway-name>' -FileName '.\rules.csv'

.PARAMETER EdgeName
    Name of Edge device to be used

.PARAMETER RuleFile
    File that contains the new rules to add

.PARAMETER DebugMode
    Set the run to not create the rules but to display the proposed output

.PARAMETER Thorough
    Raises the output level of the debug

    #>

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

  $FwRules = $edgeconfxml.edgegateway.configuration.edgegatewayserviceconfiguration.firewallservice.firewallrule

  $oldRules = @()
  $newRules = @()
  $FwRules | %{ 

    if($_.Protocols.tcp -eq $true -and $_.Protocols.udp -eq $true) {$Proto = 'TCPUDP'}
    elseif($_.Protocols.tcp -eq $true -and $_.Protocols.udp -ne $true) {$Proto = 'TCP'}
    elseif($_.Protocols.tcp -ne $true -and $_.Protocols.udp -eq $true) {$Proto = 'UDP'}
    elseif($_.Protocols.icmp -eq $true) {$Proto = 'ICMP'}
    elseif($_.Protocols.any -eq $true) {$Proto = 'ANY'}

    $oldRule = New-Object PSObject -Property @{
      IsEnabled = $_.IsEnabled;
      Descr = $_.Description;
      Policy = $_.Policy;
      Proto = $Proto;
      DstPortRange = $_.DestinationPortRange;
      DstIP = $_.DestinationIP;
      SrcPort = $_.SourcePortRange;
      SrcIP = $_.SourceIP;
      EnableLogging = $_.EnableLogging
    }
    if($oldRule.Policy -ne $null) {$oldRules += $oldRule}
  }
  
  #Item to Configure Services
  $fwService = New-Object vmware.vimautomation.cloud.views.firewallservice
  $fwService.DefaultAction = "drop"
  $fwService.LogDefaultAction = $false
  $fwService.IsEnabled = $true
  $fwService.FirewallRule = @()
  $rowNum = 0

  Ipcsv -path $FileName | foreach-object {        
    $newRule = New-Object PSObject -Property @{
      IsEnabled = $_.IsEnabled;
      Descr = $_.Descr;
      Policy = $_.Policy;
      Proto = $_.Proto;
      DstPortRange = $_.DstPortRange;
      DstIP = $_.DstIP;
      SrcPort = $_.SrcPort;
      SrcIP = $_.SrcIP;
      EnableLogging = $_.EnableLogging
    }
    $newRules += $newRule
  }

  $Ruleset = $newRules
  if($oldRules -and (!($Clobber))) {$Ruleset += $oldRules}

  $Ruleset | foreach-object {
    $fwService.FirewallRule += New-Object vmware.vimautomation.cloud.views.firewallrule

    $fwService.FirewallRule[$rowNum].description = $_.Descr
    $fwService.FirewallRule[$rowNum].protocols = New-Object vmware.vimautomation.cloud.views.firewallRuleTypeProtocols
    switch ($_.Proto) {
      "tcpudp" { 
        $fwService.FirewallRule[$rowNum].protocols.tcp = $true
        $fwService.FirewallRule[$rowNum].protocols.udp = $true 
      }
      "tcp" { $fwService.FirewallRule[$rowNum].protocols.tcp = $true }
      "udp" { $fwService.FirewallRule[$rowNum].protocols.udp = $true }
      "icmp" { $fwService.FirewallRule[$rowNum].protocols.icmp = $true }
      "any" { $fwService.FirewallRule[$rowNum].protocols.any = $true }
      default { $fwService.FirewallRule[$rowNum].protocols.any = $true }
    }
    $fwService.FirewallRule[$rowNum].sourceip = $_.SrcIP

    if ($_.SrcPort -eq "any" ) { $srcPort = "-1" } else { $srcPort = $_.SrcPort }
    $fwService.FirewallRule[$rowNum].sourceport = $srcPort

    $fwService.FirewallRule[$rowNum].destinationip = $_.DstIP
    $fwService.FirewallRule[$rowNum].destinationportrange = $_.DstPortRange
    $fwService.FirewallRule[$rowNum].policy = $_.Policy
    $fwService.FirewallRule[$rowNum].isenabled = [System.Convert]::ToBoolean($_.isEnabled)
    $fwService.FirewallRule[$rowNum].enablelogging = [System.Convert]::ToBoolean($_.EnableLogging)

    if($DebugMode -and $Thorough) {$fwservice.FirewallRule[$rowNum] | Format-Table}
    $rowNum++
  }

  if($DebugMode -and $Thorough) {$fwservice.FirewallRule | Format-Table}
  
  if($DebugMode) {
    Write-Host "Existing Rules" -ForegroundColor Yellow
    $oldRules | Format-Table
    Write-Host "Rules to be added" -ForegroundColor Yellow
    $newRules | Format-Table
    Write-Host "Resulting Ruleset" -ForegroundColor Yellow
    $Ruleset | Format-Table
  }

  if(!($DebugMode)) {
    #configure Edge
    try {
      $edgeView.ConfigureServices($fwService)
      Write-Host "New Edge Rules added successfully on $($EdgeName)" -ForegroundColor Green
    }
    catch {
      Write-Host "Unable to add new rules to $($EdgeName)" -ForegroundColor Red
    }
  }
}
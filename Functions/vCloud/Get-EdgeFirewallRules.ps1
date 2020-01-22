Function Get-EdgeFirewallRules {
<#
.SYNOPSIS
    Retrieve all Listed firewall rules on an Edge Gateway

.DESCRIPTION
    Retrieve all Listed firewall rules on an Edge Gateway and displays them in the terminal window

.EXAMPLE
    Get-EdgeFirewallRules -EdgeName '<gateway-name>'

.PARAMETER EdgeName
    Name of Edge device to be used

.PARAMETER Backup
    Use this switch to backup the current config to a csv file

.PARAMETER FilePath
#>

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

$FwRules = $edgeconfxml.edgegateway.configuration.edgegatewayserviceconfiguration.firewallservice.firewallrule

$oldRules = @()
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
  $oldRules += $oldRule
}

if($Backup -and $FilePath) {
  $oldrules | Export-CSV -path "$filepath/$edgename-firewallrules-backup_$(Get-Date -format "yyyyMMdd_hhmm").csv" -notypeinformation
}
elseif($Backup -and !($FilePath)) {
  $oldrules | Export-CSV -path "$edgename-firewallrules-backup_$(Get-Date -format "yyyyMMdd_hhmm").csv" -notypeinformation
}
else {$oldRules | Out-GridView}
}
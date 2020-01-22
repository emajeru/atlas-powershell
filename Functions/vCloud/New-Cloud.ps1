Function New-Cloud {
<#
.SYNOPSIS
    Uses a build.json file to automate the provisioning of a cloud client

.DESCRIPTION
    Uses a build.json file to automate the provisioning of a cloud client

.EXAMPLE
    New-Cloud -BuildDoc .\build.json

.PARAMETER EnvDoc
    Path to the Environment file to be used

.PARAMETER BuildDoc
    Path to the Build file to be used

    #>
    Param (
      [Parameter(Mandatory=$True, HelpMessage="Environment file in JSON")][Alias("-env","e")]
      [String] $BuildEnv,
      [Parameter(Mandatory=$True, HelpMessage="Build file in JSON")]
      [String] $BuildDoc,
      [Parameter(Mandatory=$False, HelpMessage="Use This switch to run the build of the JSON file")]
      [Switch] $Autorun
      )

    # Start Build Session
    Write-Verbose "Start Build Session"
    $Environment = $(Get-Variable $BuildEnv).Value
    Write-Verbose "Assigning Variables $($Environment.Environment)"

    $Build = New-Object CloudBuild -ArgumentList $BuildDoc

    Write-Verbose "Completed Assigning Variables"

    If ($Build) {
      If (Get-Org -Server "$($Environment.Environment)" "$($Build.Org.Name)" -ErrorAction SilentlyContinue) {Write-Host "Organization Already Exists"}
      Else {
        New-CloudOrg -ServerName "$($Environment.Environment)" `
        -OrgName "$($Build.Org.Name)" `
        -OrgFullName "$($Build.Org.FullName)" `
        -OrgDescription "$($Build.Org.Description)"
      }

      ForEach($OrgUser in $Build.OrgUsers) {
        If (Get-CIUser -Server "$($Environment.Environment)" -Org "$($Build.Org.Name)" "$($OrgUser.Name)" -ErrorAction SilentlyContinue) {Write-Host "User Already Exists"}
        Else {
          New-CloudUser -ServerName "$($Environment.Environment)" `
          -OrgName "$($Build.Org.Name)" `
          -OrgUser "$($OrgUser.Name)" `
          -OrgUserFullName "$($OrgUser.FullName)" `
          -OrgUserPassword "$($OrgUser.Password)" `
          -OrgUserRole "$($OrgUser.Role)"
        }
      }

      ForEach($OrgVdc in $Build.OrgVdcs) {
        If (Get-OrgVdc -Server "$($Environment.Environment)" -Org "$($Build.Org.Name)" "$($OrgVdc.Name)" -ErrorAction SilentlyContinue) {Write-Host "Virtual DataCenter Already Exists"}
        Else {
          New-CloudvDC -ServerName "$($Environment.Environment)" `
          -OrgName "$($Build.Org.Name)" `
          -OrgvDCName "$($OrgVdc.Name)" `
          -ProviderVDC "$($Environment.ProviderVDC)" `
          -CPU "$($OrgVdc.CPU)" `
          -Mem "$($OrgVdc.MEM)" `
          -Storage "$($OrgVdc.Storage)" `
          -StorageProfile "$($Environment.StoragePolicy)" `
          -NetworkPool "$($Environment.NetworkPool)"
        }

        If ($Build.NSXEdges.length -gt 0) {
          ForEach($NSXEdge in $Build.NSXEdges) {
            If (Search-Cloud -Server "$($Environment.Environment)" -QueryType EdgeGateway -Name "$($NSXEdge.Name)") {Write-Host "Edge Gateway Already Exists"}
            Else {
              New-EdgeGateway -ServerName "$($Environment.Environment)" `
              -OrgName "$($Build.Org.Name)" `
              -OrgvDCName "$($OrgVdc.Name)" `
              -Edgename "$($NSXEdge.Name)" `
              -ExternalNetwork "$($NSXEdge.ExternalNetwork)" `
              -IPAddress "$($NSXEdge.IPAddress)" `
              -SubnetMask "$($NSXEdge.SubnetMask)" `
              -Gateway "$($NSXEdge.Gateway)"
            }
          }
        }
        Else {Write-Host "No Edge Requested"}

        If($OrgvDC.Networks.length -gt 0) {
          Write-Host "Building Networks"
          ForEach($Network in $OrgvDC.Networks) {
            Write-Host "Building Network $($Network.Name)"
            If($Build.NSXEdges) {
              New-CloudNetwork -Type $Network.Type `
              -ServerName "$($Environment.Environment)" `
              -OrgName "$($Build.Org.Name)" `
              -OrgVdcName "$($OrgvDC.Name)" `
              -EdgeName "$($NSXEdge.Name)" `
              -Name "$($Network.Name)" `
              -Description "$($Network.Description)" `
              -IsShared "$($Network.Shared)" `
              -Gateway $Network.Network.Gateway `
              -Netmask $Network.Network.Mask `
              -Dns1 $Network.Network.DNS1 `
              -Dns2 $Network.Network.DNS2 `
              -StartAddress $Network.Network.StartAddress `
              -EndAddress $Network.Network.EndAddress
            }
            Else {
              New-CloudNetwork -Type $Network.Type `
              -ServerName "$($Environment.Environment)" `
              -OrgName "$($Build.Org.Name)" `
              -OrgVdcName "$($OrgvDC.Name)" `
              -Name "$($Network.Name)" `
              -Description "$($Network.Description)" `
              -IsShared "$($Network.Shared)" `
              -Gateway $Network.Network.Gateway `
              -Netmask $Network.Network.Mask `
              -Dns1 $Network.Network.DNS1 `
              -Dns2 $Network.Network.DNS2 `
              -StartAddress $Network.Network.StartAddress `
              -EndAddress $Network.Network.EndAddress
            }
          }
        }
      }
    }
    Else {Throw "No Build Configuration Found!"}
  }
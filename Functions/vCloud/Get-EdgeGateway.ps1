Function Get-EdgeGateway {
<#
  .SYNOPSIS
    This is just to make it easier to search for NSX Edge devices

  .DESCRIPTION
    This is just to make it easier to search for NSX Edge devices
  
  .PARAMETER Name
#>

  Param (
    [Parameter(Mandatory=$False)][ValidateNotNullorEmpty()][String]$Name,
    [Parameter(Mandatory=$False)][ValidateNotNullorEmpty()][String]$Org,
    [Parameter(Mandatory=$False)][ValidateNotNullorEmpty()][String]$vDC
  )
  Begin {
    If($Name) {$Mode = "Single"}
    else {$Mode = "Multiple"}

    If($Org) {
      If($vDC) {
        $OrgVdcList = (Get-OrgVdc -Name $vDC -Org $Org | Select-Object Id).Id
      }
      Else {
        $OrgVdcList = (Get-OrgVdc -Org $Org | Select-Object Id).Id
      }
    }

    $EdgeList = @()
  }
  Process {

    Switch($Mode) {
      "Single" {
          $Edges = Search-Cloud -QueryType EdgeGateway -Name $Name
          $Edges | ForEach-Object { $EdgeList += $_ }
      }
      "Multiple" {
        If($OrgVdcList -gt 0) {
          ForEach($OrgVdcListItem in $OrgVdcList) {
            $Edges = Search-Cloud -QueryType EdgeGateway -Filter "Vdc==$OrgVdcListItem"
            $Edges | ForEach-Object { $EdgeList += $_ }
          }
        }
      }
    }
  }
  End {
    return $EdgeList
  }
}
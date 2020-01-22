Class CloudBuild : AtlasBuild {

  # Properties
  $Org
  $OrgUsers = @()
  $OrgVdcs = @()
  $NSXEdges = @()

  CloudBuild() {

    $this.Org = [ordered]@{
      'Name' = ""
      'FullName' = ""
      'Description' = ""
    }

    $this.orgUsers += [ordered]@{
      'Name' = ""
      'Password' = ""
      'FullName' = ""
      'Role' = ""
    }

    $this.orgVdcs += [ordered]@{
      'Name' = ""
      'CPU' = ""
      'MEM' = ""
      'Storage' = ""
      'Networks' = @(
        [ordered]@{
          'Name' = ""
          'Type' = ""
          'Description' = ""
          'Shared' = ""
          'Network' = [ordered]@{
            'Gateway' = ""
            'Mask' = ""
            'StartAddress' = ""
            'EndAddress' = ""
            'DNS1' = ""
            'DNS2' = ""
          }
        }
      )
    }

    $this.nsxEdges += [ordered]@{
      'Name' = ""
      'ExternalNetwork' = ""
      'IPAddress' = ""
      'SubnetMask' = ""
      'Gateway' = ""
      'Tunnels' = @(
        [ordered]@{
          'Name' = ""
          'Description' = ""

          'LocalEndpoint.Id' = ""
          'LocalEndpoint.IpAddress' = ""
          'LocalEndpoint.Subnet'= @(
            [ordered]@{
              'Name' = ""
              'Gateway' = ""
              'Netmask' = ""
            }
          )

          'PeerEndpoint.Id' = ""
          'PeerEndpoint.IpAddress' = ""
          'PeerEndpoint.Subnet'= @(
            [ordered]@{
              'Name' = ""
              'Gateway' = ""
              'Netmask' = ""
            }
          )

          'EncryptionProtoco' = ""
          'SharedSecre' = ""
          'SharedSecretEncrypte' = ""
          'Mt' = ""
          'IsEnable' = ""
        }
      )
    }
  }

  CloudBuild([string]$BuildFile) {
    if (Test-Path $BuildFile) {
      $BuildInfo = ""
      $Type = [System.IO.Path]::GetExtension($BuildFile)
      Switch($Type) {
        ".json" {$BuildInfo = (Get-Content -Raw -Path $BuildFile | ConvertFrom-Json)}
        ".yml" {$BuildInfo = (Get-Content -Raw -Path $BuildFile | ConvertFrom-Yaml)}
        ".yaml" {$BuildInfo = (Get-Content -Raw -Path $BuildFile | ConvertFrom-Yaml)}
        # default {
        #   Write-Host "No suitable build file found"
        #   return $False
        # }
      }

      $this.Org = [ordered]@{
        'Name' = $BuildInfo.Org.Name
        'FullName' = $BuildInfo.Org.FullName
        'Description' = $BuildInfo.Org.Description
      }

      $New_OrgUsers = @()
      $New_OrgVdcs = @()
      $New_NsxEdges = @()

      Foreach($BuildUser in $BuildInfo.OrgUsers) {
         $New_User = [ordered]@{
          'Name' = $BuildUser.Name
          'Password' = $BuildUser.Password
          'FullName' = $BuildUser.FullName
          'Role' = $BuildUser.Role
        }
        $New_OrgUsers += $New_User
      }

      Foreach($BuildOrgVdc in $BuildInfo.OrgVdcs) {
        $New_OrgVdc = [ordered]@{
          'Name' =  $BuildOrgVdc.Name
          'CPU' = $BuildOrgVdc.CPU
          'MEM' = $BuildOrgVdc.MEM
          'Storage' = $BuildOrgVdc.Storage
          'Networks' = @()
        }

        ForEach($BuildOrgNetwork in $BuildOrgVdc.Networks) {
          $New_Network = [ordered]@{
            'Name' = $BuildOrgNetwork.Name
            'Type' = $BuildOrgNetwork.Type
            'Description' = $BuildOrgNetwork.Description
            'Shared' = $BuildOrgNetwork.Shared
            'Network' = [ordered]@{
              'Gateway' = $BuildOrgNetwork.Network.Gateway
              'Mask' = $BuildOrgNetwork.Network.Mask
              'StartAddress' = $BuildOrgNetwork.Network.StartAddress
              'EndAddress' = $BuildOrgNetwork.Network.EndAddress
              'DNS1' = $BuildOrgNetwork.Network.DNS1
              'DNS2' = $BuildOrgNetwork.Network.DNS2
            }
          }
          $New_OrgVdc.Networks += $New_Network
        }
        $New_OrgVdcs += $New_OrgVdc
      }

      ForEach($BuildNsxEdge in $BuildInfo.NsxEdges) {
        $New_NsxEdge = [ordered]@{
          'Name' = $BuildNsxEdge.Name
          'ExternalNetwork' = $BuildNsxEdge.ExternalNetwork
          'IPAddress' = $BuildNsxEdge.IPAddress
          'SubnetMask' = $BuildNsxEdge.SubnetMask
          'Gateway' = $BuildNsxEdge.Gateway
        }
        $New_NsxEdges += $New_NsxEdge
      }

      $this.OrgUsers = $New_OrgUsers
      $this.OrgVdcs = $New_OrgVdcs
      $this.NsxEdges = $New_NsxEdges
    }
    else {Write-Host 'No build file located.' -ForegroundColor Yellow}
  }
}
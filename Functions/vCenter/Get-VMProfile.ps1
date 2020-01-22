Function Get-VMProfile {
<#
.SYNOPSIS
  This creates a collection of relevant information from a VM inside of vCenter based on information from vCenter and the VMTools data.

.DESCRIPTION
  This creates a collection of relevant information from a VM inside of vCenter based on information from vCenter and the VMTools data.

.EXAMPLE
  Get-VMProfile -VM "VM-PROD-01"

.PARAMETER VM
  The Name or VM object of to pull the data from

  #>
  [CmdletBinding(DefaultParameterSetName="ByName")]
  Param(
    [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ParameterSetName="ByName")][ValidateNotNullorEmpty()][Alias("-name","n")][string[]]$VMName,
    [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ByVM")][ValidateNotNullorEmpty()][Alias("-virtualmachine","v")][VMware.Vim.VirtualMachine[]]$VM
    )
  Begin {
    $psCmdlet.ParameterSetName
    Switch($psCmdlet.ParameterSetName) {
      "ByName" {
        Write-Verbose -Message "Using $($VMName)"
        $VMList = $VMName
      }
      "ByVM" {
        Write-Verbose -Message "Using $($VM)"
        $VMList = $VM
      }
    }
  }
  Process {
    $vmlist
    Foreach($VMitem in $VMList) {
      Try {
        $VMObject = Get-VM $VMitem -ErrorAction Stop
      }
      Catch {
        Write-Error "Cannot Read input"
        Break
      }

      $VMProfile = "" | Select-Object vmInfo,guestInfo,ip,disks,volumes

      $VMProfile.vmInfo += $VMObject | Select-Object name,notes,powerstate,guest,numcpu,corespersocket,memorygb,folder,version,resourcepool,resourcepoolid,datastoreidlist

      $VMProfile.guestInfo += $VMObject.guest | Select-Object osfullname,state,hostname

      $VMProfile.ip += $VMObject.guest.ipaddress

      $VMProfile.disks += Get-Harddisk $VMObject | Select-Object capacitygb,filename

      $VMProfile.volumes += $VMObject.guest.disks | Select-Object Path,CapacityGB
      Write-Host "----------------------------------- $($VMObject.Name) ---------------------------" -ForegroundColor Green
      Write-Host "VM Information" -ForegroundColor Yellow
      $VMProfile.vmInfo

      Write-Host "Guest Information" -ForegroundColor Yellow
      $VMProfile.guestInfo

      Write-Host "IP Address Information" -ForegroundColor Yellow
      $VMProfile.ip

      Write-Host "`nDisk Information" -ForegroundColor Yellow
      $VMProfile.disks

      Write-Host "Volume Information" -ForegroundColor Yellow
      $VMProfile.volumes
    }
  }
  End {}
}
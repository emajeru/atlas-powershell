Function Convert-VM {
<#
.SYNOPSIS
  This function recreates a VM with the options to keep the same MAC address and convert the disk type from or to another.

.DESCRIPTION
  This function recreates a VM with the same MAC addresses and allows teh ability to convert the disk type to another format such as thin, thick or eager-zeroed thick. A prefix or suffix are required to differentiate the newly created VM from the original as the original will then be renamed..

.EXAMPLE
  Convert-VM -VMName WINOS1 -Prefix 'job1' -Suffix '_NEW' -diskformat 'Thin'

#>
  param(
    [Parameter(Mandatory = $True)][String]$VMName,
    [String]$Prefix,
    [String]$Suffix = '_New',
    [String]$DiskFormat = 'Thin'
  )
  Process {
    $vm = get-vm $vmname
    try {
      $newVM = New-VM -VM $vm -Name "$prefix$($vm.name)$suffix" -Location "$($vm.folder)" -ResourcePool $(Get-ResourcePool -VM $vm) -DiskStorageFormat $diskformat
    }
    catch {
      Write-Output 'VM Already Exists' | Out-File -FilePath ".\Run_Log.txt"
    }

    if ($vm -and $newVM) {
      try {
        $vmView = $vm | Get-View
        $newVMView = $newVM | Get-View
      
        $oldNics = $($vmView | select @{N = 'Nics'; E = {$_.Config.Hardware.Device | ? {$_ -is [VMware.Vim.VirtualEthernetCard]}}}).Nics
        $newNics = $($newVMView | select @{N = 'Nics'; E = {$_.Config.Hardware.Device | ? {$_ -is [VMware.Vim.VirtualEthernetCard]}}}).Nics
      
        $vmConfig
      
        $oldNics | % {$count = 0} {
          # Write-Output "Running $count" | Out-File -FilePath ".\Run_Log.txt"
          $newNics[$count].MacAddress = $oldNics[$count].MacAddress
          $newNics[$count].addressType = "Manual"
          # Write-Output "Setting $($vmView.name) to $($newNics[$count].MacAddress)" | Out-File -FilePath ".\Run_Log.txt"
      
          $vmConfig = New-Object VMware.Vim.VirtualMachineConfigSpec -Property @{
            deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec -Property @{
              operation = "edit"
              device    = $newNics[$count]
            }
          }
          $count++
          $newVMView.ReconfigVM($vmConfig)
        }
      }
      catch {
        Write-Output 'Unable to clone the VM' | Out-File -FilePath ".\Run_Log.txt"
        return
      }
    
      if ($vm -and $newVM) {
        Set-VM -VM $vm -Name "$($vm.Name)_Old" -Confirm:$False
        if ($prefix -ne "") {
          Set-VM -VM $newVM -Name "$($newVM.Name -replace $prefix,'')" -Confirm:$False
        }
        if ($suffix -ne "") {
          Set-VM -VM $newVM -Name "$($newVM.Name -replace $suffix,'')" -Confirm:$False
        }
      }
    }
  }
}
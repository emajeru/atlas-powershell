Function New-CloudvDC {
    <#
.SYNOPSIS
    Creates a new Organization in vCloud with Default Parameters

.DESCRIPTION
    Creates a new Organization in vCloud with Default Parameters

.EXAMPLE
    New-CloudClientvDC -Server $ServerName -OrgName <org-name> -ProviderVDC "provider-vdc-01" -OrgvDCName "<org-vdc-name>" -CPU 5 -Mem 11 -Storage 50 -StorageProfile "Storage-01" -IsExternal -ExternalNetwork "01-tenant-external-net"

.PARAMETER ServerName
    URL of the vCloud instance

.PARAMETER OrgName
    Short-Name of the Organization in vCloud

.PARAMETER ProviderVDC
    Name of the Provider vDC

.PARAMETER OrgvDCName
    Name of the OrgvDC to be created

.PARAMETER CPU
    CPU Count to be assigned to the vDC

.PARAMETER Mem
    Memory amount to be assigned to the new vDC

.PARAMETER Storage
    Amount of storage in GB to be assigned to the vDC

.PARAMETER StorageProfile
    Storage profile to assign to the vDC

.PARAMETER IsExternal
    Assigns the vDC directly to an external network

.PARAMETER ExternalNetwork
    External Network to be used if the -IsExternal switch is used

    #>
    Param (
      [Parameter(Mandatory=$False, HelpMessage="URL of the vCloud instance")]
      [ValidateNotNullorEmpty()]    
      [String]$ServerName,
      [Parameter(Mandatory=$True, HelpMessage="Short-Name of the Organization in vCloud")]
      [ValidateNotNullorEmpty()]
      [String]$OrgName,
      [Parameter(Mandatory=$True, HelpMessage="Name of the Provider vDC")]
      [ValidateNotNullorEmpty()]
      [String]$ProviderVDC,
      [Parameter(Mandatory=$True, HelpMessage="Name of the OrgvDC to be created")]
      [ValidateNotNullorEmpty()]
      [String]$OrgvDCName,
      [Parameter(Mandatory=$True, HelpMessage="CPU Count to be assigned to the vDC")]
      [ValidateNotNullorEmpty()]
      [Int]$CPU=1,
      [Parameter(Mandatory=$True, HelpMessage="Memory amount to be assigned to the new vDC")]
      [ValidateNotNullorEmpty()]
      [Int]$Mem=1,
      [Parameter(Mandatory=$True, HelpMessage="Amount of storage in GB to be assigned to the vDC")]
      [ValidateNotNullorEmpty()]
      [Int]$Storage=1,
      [Parameter(Mandatory=$True, HelpMessage="Storage profile to assign to the vDC")]
      [ValidateNotNullorEmpty()]
      [String]$StorageProfile,
      [Parameter(Mandatory=$True, HelpMessage="Network pool that this vDC will function from")]
      [ValidateNotNullorEmpty()]
      [String]$NetworkPool,
      [Parameter(Mandatory=$False, HelpMessage="Assigns the vDC directly to an external network")]
      [Switch]$IsExternal,
      [Parameter(Mandatory=$False, HelpMessage="External Network to be used if the -IsExternal switch is used")]
      [ValidateNotNullorEmpty()]
      [String]$ExternalNetwork
      )
    Begin {
      Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of Virtual Datacenter: $OrgvDCName ...Starting" -ForegroundColor Yellow
    }
    Process {

      New-OrgVdc -Server $ServerName -Name $OrgvDCName -AllocationModelAllocationPool -CPUAllocationGHz $CPU -MemoryAllocationGB $Mem -Org $OrgName -ProviderVDC $ProviderVDC -StorageAllocationGB 1  | Out-Null

      # Add a Storage Profile to the newly created Org VDC
      # Find the desired Storage Profile in the Provider vDC to be added to the Org vDC
      $OrgPvDCProfile = Search-Cloud -Server $ServerName -QueryType ProviderVdcStorageProfile -Name $StorageProfile | Get-CIView

      # Create a new object of type VdcStorageProfileParams and configure the parameters for the Storage Profile
      $Storage = $Storage * 1024
      $spParams = New-Object VMware.VimAutomation.Cloud.Views.VdcStorageProfileParams
      $spParams.Limit = $Storage
      $spParams.Units = "MB"
      $spParams.ProviderVdcStorageProfile = $OrgPvDCProfile.href
      $spParams.Enabled = $true
      $spParams.Default = $false
      
      # Create an UpdateVdcStorageProfiles object and put the new parameters into the AddStorageProfile element
      $UpdateParams = New-Object VMware.VimAutomation.Cloud.Views.UpdateVdcStorageProfiles
      $UpdateParams.AddStorageProfile = $spParams
      
      # Get the Org VDC and create the Storage Profile
      $OrgVdc = Get-OrgVdc -Server $ServerName -Name $OrgvDCName
      $OrgVdc.ExtensionData.CreateVdcStorageProfile($UpdateParams) | Out-Null
      
      #Set the new storage profile as default
      $OrgvDCStorageProfile = Search-Cloud -Server $ServerName -Querytype AdminOrgVdcStorageProfile | Where {($_.Name -match $StorageProfile) -and ($_.VdcName -eq $OrgvDCName)} | Get-CIView
      $OrgvDCStorageProfile.Default = $True
      $OrgvDCStorageProfile.UpdateServerData() | Out-Null
      
      # Delete the *(Any) Storage Profile
      # Get object representing the * (Any) Profile in the Org vDC
      $OrgvDCAnyProfile = Search-Cloud -Server $ServerName -Querytype AdminOrgVdcStorageProfile | Where {($_.Name -match '\*') -and ($_.VdcName -eq $OrgvDCName)} | Get-CIView
      
      # Disable the "* (any)" Profile
      $OrgvDCAnyProfile.Enabled = $False
      $OrgvDCAnyProfile.UpdateServerData() | Out-Null
      
      # Remove the "* (any)" profile form the Org vDC completely
      $ProfileUpdateParams = New-Object VMware.VimAutomation.Cloud.Views.UpdateVdcStorageProfiles
      $ProfileUpdateParams.RemoveStorageProfile = $OrgvDCAnyProfile.href
      $OrgvDC.extensiondata.CreatevDCStorageProfile($ProfileUpdateParams) | Out-Null

      #Set Org VDC CPU and Memory guarantees
      Get-OrgVdc -Server $ServerName $OrgvDCName | Set-OrgVdc -CpuGuaranteedPercent 15 | Out-Null
      Get-OrgVdc -Server $ServerName $OrgvDCName | Set-OrgVdc -MemoryGuaranteedPercent 50 | Out-Null
      

      Get-OrgVdc -Server $ServerName $OrgvDCName | Set-OrgVdc -ThinProvisioned $True -UseFastProvisioning $False -VMMaxCount 10 | Out-Null

      #Create a private Catalog and share it to all Org members with Read/Write access
      $PrivateCatalog = New-Object VMware.VimAutomation.Cloud.Views.AdminCatalog
      $PrivateCatalog.name = "$OrgName-Catalog01"
      (Get-Org -Server $ServerName $OrgName | Get-CIView).CreateCatalog($PrivateCatalog) | Out-Null
      New-CIAccessControlRule -Server $ServerName -Entity $PrivateCatalog.name -EveryoneInOrg -AccessLevel Full -Confirm:$False | Out-Null
      
      #Assign Network Pool and number of available networks
      Get-OrgVdc -Server $ServerName $OrgvDCName | Set-OrgVdc -NetworkPool $NetworkPool | Out-Null
      Get-OrgVdc -Server $ServerName $OrgvDCName | Set-OrgVdc -NetworkMaxCount 10 | Out-Null

    }
    End {
      Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of Virtual Datacenter: $OrgvDCName ...Done" -ForegroundColor Green
    }

  }
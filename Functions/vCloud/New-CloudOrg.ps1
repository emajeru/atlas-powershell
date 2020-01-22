Function New-CloudOrg {
<#
.SYNOPSIS
Creates a new Organization in vCloud with Default Parameters

.DESCRIPTION
Creates a new Organization in vCloud with Default Parameters

.EXAMPLE
New-CloudOrg -Server $ServerName -OrgName <org-name> -OrgFullName "Testing vDC" -OrgDescription "Used for vCloud testing"

.PARAMETER ServerName
URL of the vCloud instance

.PARAMETER OrgName
Short-Name of the Organization in vCloud"

.PARAMETER OrgFullName
Full Name of the Organization"

.PARAMETER OrgDescription
Description of the vCloud Organization"

#>
Param (
  [Parameter(Mandatory=$False, HelpMessage="URL of the vCloud instance")]
  [ValidateNotNullorEmpty()]    
  [String]$ServerName,
  [Parameter(Mandatory=$True, HelpMessage="Short-Name of the Organization in vCloud")]
  [ValidateNotNullorEmpty()]    
  [String]$OrgName,
  [Parameter(Mandatory=$True, HelpMessage="Full Name of the Organization")]
  [ValidateNotNullorEmpty()]    
  [String]$OrgFullName,
  [Parameter(Mandatory=$True, HelpMessage="Description of the vCloud Organization")]
  [ValidateNotNullorEmpty()]
  [String]$OrgDescription
  )
Begin {
  Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of vOrg $OrgName...Starting" -ForegroundColor Yellow
}
Process {

  # Begin creation of the Organization
  Write-Verbose "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Beginning creation of vOrg $OrgName"
  New-Org -Name $OrgName -Fullname $OrgFullName -Description $OrgDescription | Out-Null

  # Configure Org Settings
  $Org = Get-Org -Server $ServerName -Name $OrgName

  $Org.ExtensionData.Settings.OrgGeneralSettings.DeployedVmQuota = 10
  $Org.ExtensionData.Settings.OrgGeneralSettings.StoredVmQuota = 10
  $Org.ExtensionData.Settings.OrgGeneralSettings.VdcQuota = 3

  ## Configure account lockout policy
  Write-Verbose "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Configuring Account Lockout Policy"
  $Org.ExtensionData.Settings.OrgPasswordPolicySettings.AccountLockoutEnabled = $True
  $Org.ExtensionData.Settings.OrgPasswordPolicySettings.AccountLockoutIntervalMinutes = 60
  $Org.ExtensionData.Settings.OrgPasswordPolicySettings.InvalidLoginsBeforeLockout = 10
  $Org.ExtensionData.UpdateServerData() | Out-Null

  ## Set vApp lease times
  Write-Verbose "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Setting vApp Lease Times"
  $Leases = $Org.ExtensionData.Settings.GetVAppLeaseSettings()
  $Leases.DeploymentLeaseSeconds = 0
  $Leases.StorageLeaseSeconds = 0
  $Leases.DeleteOnStorageLeaseExpiration = $False
  $Leases.UpdateServerData() | Out-Null

  ## Set vApp template lease times
  Write-Verbose "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Setting Template Lease Times"
  $TemplateLeases = $Org.ExtensionData.Settings.GetVAppTemplateLeaseSettings()
  $TemplateLeases.StorageLeaseSeconds = 0
  $TemplateLeases.DeleteOnStorageLeaseExpiration = $False
  $TemplateLeases.UpdateServerData() | Out-Null

  ## Set Org operations limits
  Write-Verbose "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Setting Operation Limits"
  $Limits = $Org.ExtensionData.Settings.GetOperationLimitsSettings()
  $Limits.OperationsPerUser = "3"
  $Limits.QueuedOperationsPerUser = "3"
  $Limits.OperationsPerOrg = "3"
  $Limits.QueuedOperationsPerOrg = "3"
  $Limits.ConsolesPerVmLimit = "3"
  $Limits.UpdateServerData() | Out-Null

  $Org = Get-Org -Server $ServerName -Name $OrgName
  $Org.ExtensionData.Settings.OrgGeneralSettings.CanSubscribe = $true
  $Org.ExtensionData.UpdateServerData() | Out-Null

  ## Set Org default administrators as 
  ## Uncomment the below lines and set the CustomUsersOu for LDAP login
  # $org.ExtensionData.Settings.OrgLdapSettings.OrgLdapMode = "SYSTEM"
  # $org.ExtensionData.Settings.OrgLdapSettings.CustomUsersOu = "<AD Organizational Unit>"
  # $org.ExtensionData.UpdateServerData()

  $NewGroup = New-Object VMware.VimAutomation.Cloud.Views.Group
  $GroupRole = $global:DefaultCIServers[0].ExtensionData.RoleReferences.RoleReference | Where {$_.Name -eq "Organization Administrator"}

  $NewGroup.Name = "Org-Admins"
  $NewGroup.Role = $GroupRole

  $Org.ExtensionData.CreateGroup($NewGroup)
  }
End {
  Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of vOrg $OrgName...Done" -ForegroundColor Green
}
}
Function New-CloudUser {
<#
.SYNOPSIS
Creates a new Organization in vCloud with Default Parameters

.DESCRIPTION
Creates a new Organization in vCloud with Default Parameters

.EXAMPLE
New-CloudUser -Server $ServerName -OrgName <org-name> -OrgUser "org.admin" -OrgUserFullName "Testing Administrator" -OrgUserPassword "<password>" -OrgUserRole "Organization Administrator"

.PARAMETER ServerName
URL of the vCloud instance

.PARAMETER OrgName
Short-Name of the Organization in vCloud

.PARAMETER OrgUser
Username for the new user

.PARAMETER OrgUserPassword
Password for the new user

.PARAMETER OrgUserRole
Role to be assigned to the new user

#>
  Param (
    [Parameter(Mandatory=$False, HelpMessage="URL of the vCloud instance")]
    [ValidateNotNullorEmpty()]    
    [String]$ServerName,
    [Parameter(Mandatory=$True, HelpMessage="Short-Name of the Organization in vCloud")]
    [ValidateNotNullorEmpty()]
    [String]$OrgName,
    [Parameter(Mandatory=$True, HelpMessage="Username for the new user")]
    [ValidateNotNullorEmpty()]
    [String]$OrgUser,
    [Parameter(Mandatory=$False, HelpMessage="Full name of the new user")]
    [ValidateNotNullorEmpty()]
    [String]$OrgUserFullName,
    [Parameter(Mandatory=$True, HelpMessage="Password for the new user")]
    [ValidateNotNullorEmpty()]
    [String]$OrgUserPassword,
    [Parameter(Mandatory=$True, HelpMessage="Role to be assigned to the new user")]
    [ValidateNotNullorEmpty()]
    [String]$OrgUserRole
    )
  Begin {
    Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of user $OrgUser...Starting" -ForegroundColor Yellow
  }
  Process {

    $Role = Search-Cloud -Server $ServerName -QueryType Role -Name "$OrgUserRole" | Get-CIView

    $User = New-Object VMware.VimAutomation.Cloud.Views.User
    $User.Name = $OrgUser
    $User.FullName = $OrgUserFullName
    $User.Password = $OrgUserPassword
    $User.Role = $Role.href
    $User.IsEnabled = $True
    
    (Get-Org -Server $ServerName -Name $OrgName).ExtensionData.CreateUser($User) | Out-Null
  }
  End {
    Write-Host "$(Get-Date -Format "MM/d/yyyy H:mm:ss tt")  Creation of user $OrgUser...Done" -ForegroundColor Green
  }
}
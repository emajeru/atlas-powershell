# Atlas - Functions

## Functions
**New-CloudClientOrg**
Creates the Organization to be used.

```powershell
# Run Example
New-CloudClientOrg -OrgName <org-name> -OrgFullName "Testing vDC" -OrgDescription "Used for vCloud testing"
```

**New-CloudClientUser**
Creates the user at the top-level of the Org.

```powershell
# Run Example
New-CloudClientUser -OrgName <org-name> -OrgUser "org.admin" -OrgUserFullName "Testing Administrator" -OrgUserPassword "<password>" -OrgUserRole "Organization Administrator"
```

**New-CloudClientvDC**
Creates the vDC under the named Org.

```powershell
# Run Example
New-CloudClientvDC -OrgName <org-name> -OrgvDCName "<org-vdc-name>" -ProviderVDC "provider-vdc-01" -CPU 5 -Mem 11 -Storage 50 -StorageProfile "Storage-01"
```

**New-CloudClientEdge**
Creates the NSX Edge Gateway under the named Org in the given vDC.

```powershell
# Run Example
New-CloudClientEdge -OrgName <org-name> -OrgvDCName "<org-vdc-name>"  -Edgename "<edge-name>" -ExternalNetwork "01-tenant-external-net" -IPAddress "1.1.1.9" -SubnetMask "255.255.255.0" -Gateway "1.1.1.254"
```

**New-Cloud**
This is a collection of the all of the previous functions into an automated task based on a build file to be provided at run-time.

```powershell
# Run Example
New-Cloud -BuildDoc .\build.json
```

**Get-EdgeGatewayRules**
Retrieve all Listed firewall rules on an Edge Gateway

```powershell
# Run Example 1
Get-EdgeGatewayRules -EdgeName '<gateway-name>'

# Run Example 2
# Export the existing rules to a csv file in the current working directory for either backup up or easier editing.
Get-EdgeGatewayRules -EdgeName '<gateway-name>' -Backup

# Run Example 3
# Export the existing rules to a csv file in a specified location.
Get-EdgeGatewayRules -EdgeName '<gateway-name>' -Backup -Filepath 'C:\EdgeRules'
```

**New-EdgeGatewayRules**
Add new firewall rules to an NSX Edge Gateway.

```powershell
# Run Example 1
# Import rules to NSX Edge Gateway
New-EdgeGatewayRules -EdgeName '<gateway-name>' -FileName '.\rules.csv'

# Run Example 2
# Show existing rules as well as the rules that will be added without adding them.
New-EdgeGatewayRules -EdgeName '<gateway-name>' -FileName '.\rules.csv' -Debug

# Run Example 3
# Remove existing rules and then import rules from CSV
New-EdgeGatewayRules -EdgeName '<gateway-name>' -FileName '.\rules.csv' -Clobber
```


# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- AtlasBuild class added and all other vCloud classes placed as subclasses of this.
- `Convert-VM` vCenter function to convert VMs from thick to thin while retaining MAC Address.

### Changed
- All Get commands of the Subclasses have been inherited from parent class AtlasBuild.
- Get-EdgeTunnel Command now returns VPNBuild objects that can be properly parsed and output to yaml or json files.
- Get-Cloudbuild now pulls VPN data as well.
- CloudBuild class modified to contain each VPN within a particular NSXEdge.
- Edges are now pulled irrespective of the vDC being scanned.
- Get-CloudUser now only pulls users that are local to the organiation.
- Tunnel documentation is done without instantiating all of the variables.
- PSYaml will now be used instead of powershell-yaml for pasring yaml configurations as the powershell-yaml utility does not yet work correctly with v11 of PowerCLI.

### Deprecated

### Removed

### Fixed
- EdgeGateway documentation using Get-Cloud now pulls only one copy of the Edges on the organization.
- GetYaml() Function now runs 

### Security

## [3.6.0] - 2018-07-13
### Added
- `Get-Cloud` function added that can pull an entire Organization profile from the individual vCloud Directory entry.
- Shortcut for the generation of a build file created that can be called using `New-Build` with optional variables.

### Changed
- Module renamed from vCloudX to **Atlas**.
- Build objects are now instantiated using the `[CloudBuild]` class.
- Environments consolidated into a single file and converted to script-scoped variables that can be referenced as a string i.e -BuildEnv 'env01'.
- Environment information is now loacated in `Variables\Environments.ps1` file.

### Fixed
- `Get-EdgeGateway` function updated to filter by Organization with new flag.
- VPN Appending has been fixed.

## [3.5.0] - 2018-06-11
### Added
- `New-Cloud` function added that can parse a YAML build file in order to provision an entire organization with multiple vDCs, Organization Users, NSXEdges and Networks.
- Added the ability to pull OrgNetwork information.

### Changed
- Build files from `[CloudBuild]` now use either YAML or JSON and can be parsed to and from the other.

### Deprecated
- All **CloudClient** functions renamed to **Cloud**.
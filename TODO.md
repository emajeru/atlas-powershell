# TODO
- [ ] Create gateway rules for either the firewall or NAT @edgegateway
- [ ] Add option to document multiple types of VPN Configurations. @EdgeTunnel
- [ ] Add ability to build VMs from existing build file @New-Cloud
- [ ] Add ability to search existing VPNs before adding new ones. @New-EdgeTunnel|New-Cloud

#FIXME
- [ ] Add Classes as Types so that 'using' is no longer required @all
- [ ] Adding multiple natRouted networks fails as the NSX Edge is busy creating the last item. There needs to be a check for status. @New-CloudNetwork
- [ ] Exporting components using convertto-yaml is no longer working as expected beyond a certain number of levels @Get-Cloud

#DONE
- [x] Create constructor for blank call @VPNBuild
- [x] Parse retrieved vpn tunnels as VPNBuild objects @Get-EdgeTunnel
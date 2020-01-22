$script:env_01 = [ordered]@{
	Environment   = "env01.domain.com"
	ProviderVDC   = "provider-vdc-01"
	NetworkPool   = "provider-vdc-01-vxlan"
	StoragePolicy = "provider-vdc-01-storage-01"
}

$script:env_02 = [ordered]@{
	Environment   = "env02.domain.com"
	ProviderVDC   = "provider-vdc-02"
	NetworkPool   = "provider-vdc-02-vxlan"
	StoragePolicy = "provider-vdc-02-storage-01"
}
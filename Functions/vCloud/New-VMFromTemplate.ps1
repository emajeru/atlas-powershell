Function New-VMFromTemplate {
<#
.SYNOPSIS        
    This script will Create vApp and deploy VMs from the selected Template VM.

.DESCRIPTION
    This script will Create vApp and deploy VMs from the selected Template VM.

.EXAMPLE

.PARAMETER OrgName
    Short-Name of the Organization in vCloud"

.PARAMETER OrgNetwork
    Organization Network"

.PARAMETER OrgvDCName
    Name of the Organization vDC"

.PARAMETER Template
    Name of the Template to be used in the deployment"

.PARAMETER Count
    Number of VMs to create"

.PARAMETER Index
    Index to begin suffixing the created vms with"

.PARAMETER vAppName
    Name of the vApp that hte VMs will be created under"

.PARAMETER VMPrefix
    Prefix to be used in nameing all created vms"
  #>
  [CmdletBinding(DefaultParameterSetName="ByFile")]
  Param(
    [Parameter(Mandatory=$True, HelpMessage="Short-Name of the Organization in vCloud", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][string]$OrgName,
    [Parameter(Mandatory=$True, HelpMessage="Organization Network", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][string]$OrgNetwork,
    [Parameter(Mandatory=$False, HelpMessage="Name of the Organization vDC", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][string]$OrgvDCName,
    [Parameter(Mandatory=$True, HelpMessage="Name of the Template to be used in the deployment", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][string]$Template,
    [Parameter(Mandatory=$True, HelpMessage="Number of VMs to create", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][int]$Count,
    [Parameter(Mandatory=$True, HelpMessage="Index to begin suffixing the created vms with", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][int]$Index,
    [Parameter(Mandatory=$True, HelpMessage="Name of the vApp that hte VMs will be created under", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][string]$vAppName,
    [Parameter(Mandatory=$True, HelpMessage="Prefix to be used in nameing all created vms", ParameterSetName="ByInfo")][ValidateNotNullorEmpty()][string]$VMPrefix,
    [Parameter(Mandatory=$False, HelpMessage="The Build File to run from", ParameterSetName="ByFile")][ValidateNotNullorEmpty()][string]$BuildDoc,
    [Parameter(HelpMessage="Use this to stop the vApp from starting")][switch]$NoStart
    )
  Begin {
    $psCmdlet.ParameterSetName
    Switch($psCmdlet.ParameterSetName) {
      "ByFile" {
        $Build = Get-Content $BuildDoc | ConvertFrom-Json
        $OrgName = $Build.OrgName
        $OrgNetwork = $Build.OrgNetwork
        $OrgvDCName = $Build.OrgvDCName
        $Template = $Build.Template
        $vAppName = $Build.vAppName
        $VMPrefix = $Build.VMPrefix
        $Count = $Build.Count
        $Index = $Build.Index
      }
      "ByInfo" {}
    }
  }
  Process {
    $Count = $Index + $Count 
    for($i=$Index; $i -lt $Count; $i++) 
    { 
      # $vAppName = $vAppNamePrefix+"$i"
      if($i -lt 10) {$Number="0$i"}
      else {$Number=$i}
      $VMName = $VMPrefix+"$Number"

      ### Building vApp Information
      $vAppParameters = @{
        'Name' = $vAppName
      }

      if($OrgvDCName -ne $null) {$vAppParameters['OrgVdc'] = $OrgvDCName} else { $vAppParameters['OrgVdc'] = (Get-OrgVdc -Org $OrgName)[0] } 
      ### Creating new vApp ### 
      if(!(Get-CIVapp $vAppName -ErrorAction 'SilentlyContinue')) {
        New-CIVApp @vAppParameters
      }
      
      ### Deploy the VM from template inside the newly created vApp### 
      New-CIVM -Name "$VMName" -VMTemplate (Get-CIVMTemplate $Template)[0] -VApp $vAppName -ComputerName "$VMName" 
      
      ### Creating new vApp Network ### 
      if(!(Get-CIVAppNetwork $OrgNetwork -ErrorAction 'SilentlyContinue')) {
        New-CIVAppNetwork -VApp $vAppName -Direct -ParentOrgNetwork $OrgNetwork 
      }
      $vAppNetwork = Get-CIVapp $vAppName | Get-CIVAppNetwork $OrgNetwork 
      $cVMs = Get-CIVapp $vAppName | Get-civm
      
      ### Connecting the vNIC to the network ### 
      ### Please change the allocation model if required### 
      foreach ($cVM in $cVMs) { 
        $cVM | Get-CINetworkAdapter | Set-CINetworkAdapter -vappnetwork $vAppNetwork -IPaddressAllocationMode Pool -Connected $True 
      } 
      
      ### Powering on the vApp ### 
      if(!($NoStart)) {Get-CIVApp -Name $vAppName | Start-CIVApp}
    } 
  }
  End {}
}
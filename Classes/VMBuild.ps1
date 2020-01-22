Class VMBuild {
[string]$OrgName
[string]$OrgNetwork
[string]$OrgvDCName
[string]$Template
[string]$vAppName
[string]$VMPrefix
[int]$Count
[int]$Index

VMBuild([string]$OrgName,[string]$OrgNetwork,[string]$OrgvDCName,[string]$Template,[string]$vAppName,[string]$VMPrefix,[int]$Count,[int]$Index) {
  $this = New-Object PSObject -Property @{
    'OrgName' = $OrgName
    'OrgNetwork' = $OrgNetwork
    'OrgvDCName' = $OrgvDCName
    'Template' = $Template
    'vAppName' = $vAppName
    'VMPrefix' = $VMPrefix
    'Count' = $Count
    'Index' = $Index
  }
}
VMBuild([string]$Buildfile) {
  if (Test-Path $Buildfile) {
    $BuildInfo = (Get-Content -Raw -File $Buildfile | ConvertFrom-Json)

    $this.OrgName = $BuildInfo.OrgName
    $this.OrgNetwork = $BuildInfo.OrgNetwork
    $this.OrgvDCName = $BuildInfo.OrgvDCName
    $this.Template = $BuildInfo.Template
    $this.vAppName = $BuildInfo.vAppName
    $this.VMPrefix = $BuildInfo.VMPrefix
    $this.Count = $BuildInfo.Count
    $this.Index = $BuildInfo.Index
  }
  else {Write-Host 'No build file located.' -ForegroundColor Yellow}
}
VMBuild() {
  $this = New-Object PSObject -Property @{
    'OrgName' = ""
    'OrgNetwork' = ""
    'OrgvDCName' = ""
    'Template' = ""
    'vAppName' = ""
    'VMPrefix' = ""
    'Count' = ""
    'Index' = ""
  }
}

[string] GetJSON() {
  return $this | ConvertTo-JSON
}
}
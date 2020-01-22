Function CCI {
  <#
.SYNOPSIS
Opens a CI connection to servers

.DESCRIPTION
Opens a CI connection to Cloud Infrastructure servers by shortname

.EXAMPLE
CCI -Server env01

.PARAMETER Server
The short-name for the CI Server to be used
#>
  param(
    [string]$server
  )

  switch ($server) {
    'env01' { $ciserver = "env01.domain.com" }
    'env02' { $ciserver = "env02.domain.com" }
    default { $ciserver = "env00.domain.com" }
  }

  Connect-CIServer -Server $ciserver
}

Function DCI {
  <#
.SYNOPSIS
Disconnect from the current CI Server without confirmation prompt
#>
  Disconnect-CIServer -Confirm:$False
}

Function New-Build {
  <#
.SYNOPSIS
This will create the build file required by Cloud Build Funciton

.DESCRIPTION
This shortcut speeds up teh process of Build File creation by quickly creating the file within the current directory under a default name with the date appended.

.EXAMPLE
New-Build -Name build_ThisCompany
#>
  Param (
    [Parameter()][String]$Name = "build_document_$(Get-Date -Format 'MM_dd_yyyy_HHmm')"
  )

  $Build = New-Object CloudBuild | ConvertTo-Yaml
  Out-File -InputObject $Build -FilePath ".\$Name.yml"
}
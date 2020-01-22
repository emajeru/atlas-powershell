Class AtlasBuild {
  AtlasBuild() {}

  [string] GetJSON() {
    $json = $this | ConvertTo-JSON -Depth 9

    return ($json -split '\r\n' |
        ForEach-Object {
        $line = $_
        if ($_ -match '^ +') {
          $len = $Matches[0].Length / 6
          $line = ' ' * $len + $line.TrimStart()
        }
        $line
      }) -join "`r`n"
  }

  [string] GetYAML() {
    $yaml = $this | ConvertTo-YAML
    $yaml = $this | ConvertTo-JSON -Depth 9 | ConvertFrom-JSON | ConvertTo-YAML
    return $yaml
  }

  MakeFile([string]$Format) {
    if ($Format -eq "Json") {$this.GetJSON() | Out-File ".\build_document.json"}
    elseif ($Format -eq "Yaml") {$this.GetYAML() | Out-File ".\build_document.yml"}
  }

  MakeFile([string]$Format, [String]$FileName, [String]$Location) {
    if ($Format -eq "Json") {$this.GetJSON() | Out-File "$Location\$Filename"}
    elseif ($Format -eq "Yaml") {$this.GetYAML() | Out-File "$Location\$Filename"}
  }
}
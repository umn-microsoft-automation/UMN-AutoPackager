function Get-WinGetLatestPackage {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true,
            ParameterSetName = "SearchById")]
        [string]$Id,

        [parameter(Mandatory = $true,
            ParameterSetName = "SearchByName")]
        [string]$Name,

        [parameter(Mandatory = $true,
            ParameterSetName = "SearchByMoniker")]
        [string]$Moniker,

        [parameter(Mandatory = $true,
            ParameterSetName = "SearchByPathPart")]
        [string]$PathPart,

        [Parameter(Mandatory = $true,
            ParameterSetName = "Manifest")]
        [string]$Manifest
    )

    if ($Id -ne '') {
        $App = Find-WinGetPackages -Id $Id -Latest
    }

    if ($Name -ne '') {
        $App = Find-WinGetPackages -Name $Name -Latest
    }

    if ($Moniker -ne '') {
        $App = Find-WinGetPackages -Moniker $Moniker -Latest
    }

    if ($PathPart -ne '') {
        $App = Find-WinGetPackages -PathPart $PathPart -Latest
    }

    if ($Manifest -eq '') {
        $Manifest = $App.ManifestPath
    }

    $Output = [text.encoding]::utf8.getstring((Invoke-WebRequest -Uri $Manifest).Content) | ConvertFrom-Yaml

    return $Output
}

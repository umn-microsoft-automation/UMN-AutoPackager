function Get-PkgContentLocations {
    <#
    .SYNOPSIS
        Takes the package config and returns an arraylist of the content locations.
    .DESCRIPTION
        Takes the package config and returns an arraylist of the content locations.
    .PARAMETER PackageConfig
        The package config that is pulled in when invoking the autopackager.
    .EXAMPLE
        PS C:\> Get-PkgContentLocations -PackageConfig $PackageConfig
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Input the values of the various PackageConfig.json files.")]
        [psobject[]]$PackageConfig
    )

    [System.Collections.ArrayList]$ContentLocations = New-Object -TypeName System.Collections.ArrayList

    foreach ($PackagingTarget in $PackageConfig.PackagingTargets) {
        foreach ($DeploymentType in $PackagingTarget.DeploymentTypes) {
            $ContentLocations.Add($DeploymentType.ContentLocation)
            $DeploymentType.ReplaceVariable("{contentLocation}", $DeploymentType.ContentLocation)
        }
    }

    return $ContentLocations
}

function Find-WinGetPackages {
    [cmdletbinding()]
    param(
        [Parameter(Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to store the WinGet source (default is ($env:TEMP\WinGetSource)).')]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$($env:TEMP)\WinGetSource",

        #[switch]$ForceUpdate,

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

        [switch]$Latest
    )

    if ($null -eq $WinGetPackages) {
        $FindPackages = Get-WinGetAllPackages -Path $Path -ForceUpdate:$ForceUpdate
    }
    elseif ($ForceUpdate) {
        $FindPackages = Get-WinGetAllPackages -Path $Path -ForceUpdate:$ForceUpdate
    }
    else {
        $FindPackages = $WinGetPackages
    }

    [System.Collections.ArrayList]$OutputObject = @()
    $OutputObject.Clear()
    foreach ($App in $FindPackages) {
        if ($Id -ne '') {
            if ($App.Id -like $Id) {
                $null = $OutputObject.Add($App)
            }
        }

        if ($Name -ne '') {
            if ($App.Name -like $Name) {
                $null = $OutputObject.Add($App)
            }
        }

        if ($Moniker -ne '') {
            if ($App.Moniker -like $Moniker) {
                $null = $OutputObject.Add($App)
            }
        }

        if ($PathPart -ne '') {
            if ($App.Path -like $PathPart) {
                $null = $OutputObject.Add($App)
            }
        }
    }

    $LatestObject = $null

    if ($Latest) {
        foreach ($Object in $OutputObject) {
            if ($null -eq $LatestObject) {
                $LatestObject = $Object
            }
            elseif (Compare-Version -ReferenceVersion "$($LatestObject.Version)" -DifferenceVersion "$($Object.Version)" -Verbose -InformationAction Continue) {
                $LatestObject = $Object
            }
        }

        return $LatestObject
    }

    return $OutputObject
}

<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Update-ConfigVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'GlobalConfig')]
        $GlobalConfig,

        [Parameter(Mandatory = $true, ParameterSetName = 'PackageConfig')]
        $PackageConfig
    )
    if ($GlobalConfig) {

    }
    elseif ($PackageConfig) {
        
    }
}

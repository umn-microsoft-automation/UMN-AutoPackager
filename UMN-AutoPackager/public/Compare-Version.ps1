<#
    .SYNOPSIS
        Takes a reference object and a difference object and determines if the reference object is greater than the difference object.
    .DESCRIPTION
        Takes a reference object and a difference object and determines if the reference object is greater than the difference object.

        Example: (reference) 1.0 > 0.1 (difference) would return true
    .EXAMPLE
        Compare-Version -ReferenceVersion "1.0.0.0" -DifferenceVersion "2.0.0.0" would return $false
    .EXAMPLE
        Compare-Version -ReferenceVersion "2.0.0-beta1" -DifferenceVersion "2.0.0-alpha12" would return $true
    .PARAMETER ReferenceVersion
        Version as a string which is on the left side of the greater than equation.
    .PARAMETER DifferenceVersion
        Version as a string which is on the right side of the greater than equation.
#>
function Compare-Version {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Version as a string which is on the left side of the greater than equation.")]
        [ValidateNotNullOrEmpty()]
        [string]$ReferenceVersion,

        [Parameter(Mandatory = $true,
            HelpMessage = "Version as a string which is on the right side of the greater than equation.")]
        [ValidateNotNullOrEmpty()]
        [string]$DifferenceVersion
    )
    
    $SemVerRegex = "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"
    $SystemVersionRegex = "^(\*|\d+(\.\d+){0,3}(\.\*)?)$"
    $NumberOnlyRegex = "^[0-9]+$"

    if ((($ReferenceVersion -match $SemVerRegex) -and ($DifferenceVersion -match $SemVerRegex)) -or (($ReferenceVersion -match $NumberOnlyRegex) -and ($DifferenceVersion -match $NumberOnlyRegex))) {
        if ([System.Management.Automation.SemanticVersion]$ReferenceVersion -gt [System.Management.Automation.SemanticVersion]$DifferenceVersion) {
            return $false
        }
        else {
            return $true
        }
    }
    elseif (($ReferenceVersion -match $SystemVersionRegex) -and ($DifferenceVersion -match $SystemVersionRegex)) {
        if ([System.Version]$ReferenceVersion -gt [System.Version]$DifferenceVersion) {
            return $false
        }
        else {
            return $true
        }
    }
    else {
        throw "One or more input objects not a Semantic Version or System.Version"
    }
}

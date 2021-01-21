function Compare-Version {
    [CmdletBinding()]
    param(
        [string]$ReferenceVersion,
        [string]$DifferenceVersion
    )
    
    $SemVerRegex = "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"
    $SystemVersionRegex = "^(\*|\d+(\.\d+){0,3}(\.\*)?)$"
    $NumberOnlyRegex = "^[0-9]+$"

    if ((($ReferenceVersion -match $SemVerRegex) -and ($DifferenceVersion -match $SemVerRegex)) -or (($ReferenceVersion -match $NumberOnlyRegex) -and ($DifferenceVersion -match $NumberOnlyRegex))) {
        if ([System.Management.Automation.SemanticVersion]$ReferenceVersion -gt [System.Management.Automation.SemanticVersion]$DifferenceVersion) {
            return $true
        }
        else {
            return $false
        }
    }
    elseif (($ReferenceVersion -match $SystemVersionRegex) -and ($DifferenceVersion -match $SystemVersionRegex)) {
        if ([System.Version]$ReferenceVersion -gt [System.Version]$DifferenceVersion) {
            return $true
        }
        else {
            return $false
        }
    }
    else {
        throw "One or more input objects not a Semantic Version or System.Version"
    }
}
function Confirm-RecipeFilesExist {
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
    [CmdletBinding()]
    param(
        $RecipeDirPath,

        $RecipeName
    )

    if ((Get-ChildItem -Path $RecipeDirPath -Filter "$RecipeName.json").Count -lt 1) {
        Write-Error -Message "Missing $RecipeName.json in $RecipeDirPath"
        return $false
    }
    elseif (-not (Test-Path -Path "$RecipeDirPath\detectVersion.ps1")) {
        Write-Error -Message "Missing detectVersion.ps1 in $RecipeDirName"
        return $false
    }
    elseif (-not (Test-Path -Path "$RecipeDirPath\packageApp.ps1")) {
        Write-Error -Message "Missing packageApp.ps1 in $RecipeDirName"
        return $false
    }
    else {
        return $true
    }
}

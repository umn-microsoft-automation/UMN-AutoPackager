function Copy-SupportFiles {
    <#
    .SYNOPSIS
        Copies the support files to the target content locations.
    .DESCRIPTION
        Takes in an array list of content locations and copies the support files to each of them.  It also replaces the given variables in the support files if they are .ps1 files.
    .PARAMETER ContentLocations
        This is a list of the content locations stored in an arraylist.  This can be generated using Get-PkgContentLocations.
    .PARAMETER ValuesToReplace
        This is a list of the values to replace in the support files stored in a hashtable.
    .PARAMETER SourcePath
        The path to where the support files are located, this should always be (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) unless otherwise required.
    .EXAMPLE
        PS C:\> Copy-SupportFiles -ContentLocations (Get-PkgContentLocations -PackageConfig $PackageConfig) -ValuesToReplace @{ "{currentVersion}" = "1.0.0" } -SourcePath (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Collections.ArrayList]$ContentLocations,

        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable]$ValuesToReplace,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory = $true, Position = 3)]
        [hashtable]$OtherFiles
    )

    foreach ($ContentLocation in $ContentLocations) {
        Write-Information -MessageData "ContentLocation: $ContentLocation"
        if (-not (Test-Path -Path $ContentLocation)) {
            $null = New-Item -Path $ContentLocation -ItemType Directory -Force
        }

        Write-Information -MessageData "Checking for additional support files to copy from: $SourcePath\supportfiles"
        if (Test-Path -Path "$SourcePath\supportfiles") {
            Copy-Item -Path "$SourcePath\supportfiles\*" -Destination $ContentLocation -Force -PassThru
        }

        if (-not ($null -eq $OtherFiles)) {
            foreach ($OtherFile in $OtherFiles.GetEnumerator()) {
                Write-Information -MessageData "Copying $($OtherFile.Value) to $($ContentLocation)\$($OtherFile.Key)"
                if (Test-Path -Path $OtherFile.Value) {
                    Copy-Item -Path $OtherFile.Value -Destination "$($ContentLocation)\$($OtherFile.Key)" -Force
                }
            }
        }

        if (-not ($null -eq $ValuesToReplace)) {
            # Update ps1 scripts with variables
            Get-ChildItem -Path $ContentLocation -Filter "*.ps1" -Recurse | ForEach-Object {
                Write-Information -MessageData "Updating file $_"
                $Content = Get-Content -Path $_.FullName

                foreach ($Value in $ValuesToReplace.GetEnumerator()) {
                    Write-Information -MessageData "Replacing $($Value.Name) with $($Value.Value)"
                    $Content = $Content.Replace($Value.Key, $Value.Value)
                }

                Set-Content -Path $_.FullName -Value $Content
            }
        }
    }
}

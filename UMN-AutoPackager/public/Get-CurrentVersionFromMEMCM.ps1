function Get-CurrentVersionFromMEMCM {
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
        [String]$AppName
    )

    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand)"
        Import-Module -Name $GlobalConfig.MEMCMModulePath.LocalPath
    } process {
        Push-Location
        Write-Verbose -Message "Processing $($SiteTarget.Site) Site..."
        $SiteCode = $SiteTarget.SiteCode

        try {
            if (-not (Test-Path -Path $SiteCode)) {
                $ConfigMgrDrive = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteTarget.Site -Credential $Credential
            }
        }
        catch {
            Write-Error $Error[0]
            Write-Warning -Message "Error: $($_.Exception.Message)"
        }

        Set-Location -Path "$SiteCode`:\"

        # Use 0.0.0 as default return version so if it's not found any version is newer.

        $ReturnVersion = "0.0.0"
        $ReturnAppName = ""

        $FindVariablesRegex = "{.*?}"

        $AppNameWithWildcards = $AppName -replace $FindVariablesRegex, "*"

        $AllApps = Get-CMApplication -Name $AppNameWithWildcards -Fast -ErrorAction SilentlyContinue | Select-Object -Property LocalizedDisplayName, CI_ID, SoftwareVersion

        if ($AllApps) {
            foreach ($App in $AllApps) {
                Write-Verbose -Message "Checking $($App.LocalizedDisplayName) :: ($($App.SoftwareVersion))"
                if (Compare-Version -ReferenceVersion $ReturnVersion -DifferenceVersion $App.SoftwareVersion -ErrorAction SilentlyContinue) {
                    Write-Verbose -Message "$($App.SoftwareVersion) is greater than $ReturnVersion for $($App.LocalizedDisplayName)"

                    $ReturnVersion = $App.SoftwareVersion
                    $ReturnAppName = $App.LocalizedDisplayName
                }
                else {
                    Write-Verbose -Message "$($App.SoftwareVersion) is less than or equal to $ReturnVersion for $($App.LocalizedDisplayName)"
                }
            }
        }

        Pop-Location
        $ConfigMgrDrive | Remove-PSDrive

        return @{
            AppName = $ReturnAppName
            Version = $ReturnVersion
        }
    } end {
        Write-Verbose -Message "Finished $($myinvocation.mycommand)"
    }
}

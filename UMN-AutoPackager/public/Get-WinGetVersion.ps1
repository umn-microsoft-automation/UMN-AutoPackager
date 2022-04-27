function Get-WingetVersion {
    <#
    .SYNOPSIS
        Get's the version for the specified winget package.
    .DESCRIPTION
        Takes in a package ID for winget and returns the version for the latest version of the package.
    .EXAMPLE
        PS C:\> Get-WinGetVersion -Id VideoLAN.VLC
        {version for the most recent version of the package}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id
    )
    
    $WingetPackageInfo = winget show --Id=$Id

    foreach ($line in $WingetPackageInfo) {
        if ($line.TrimStart(" ").StartsWith('Version:')) {
            $winget_output = $line -split ":", 2
            return $winget_output[1].TrimStart(' ') 
        }
    }
}

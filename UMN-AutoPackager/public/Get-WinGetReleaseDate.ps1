function Get-WinGetReleaseDate {
    <#
    .SYNOPSIS
        Get's the current release date for the specified winget package.
    .DESCRIPTION
        Takes in a package ID for winget and returns the release date for the latest version of the package.
    .EXAMPLE
        PS C:\> Get-WinGetReleaseDate -Id VideoLAN.VLC
        {DateTime object for the release date of most recent version of the package}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id
    )
    
    $WingetPackageInfo = winget show --Id=$Id

    foreach ($line in $WingetPackageInfo) {
        if ($line.TrimStart(" ").StartsWith('Release Date:')) {
            $winget_output = $line -split ":", 2
            return [datetime]$winget_output[1].TrimStart(' ') 
        }
    }
}

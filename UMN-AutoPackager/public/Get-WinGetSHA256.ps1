function Get-WinGetSHA256 {
    <#
    .SYNOPSIS
        Get's the SHA256 checksum for the specified winget package installer.
    .DESCRIPTION
        Takes in a package ID for winget and returns the SHA256 checksum for the latest version of the package.  This can be compared to what was downloaded to ensure it's correct.
    .EXAMPLE
        PS C:\> Get-WinGetSHA256 -Id VideoLAN.VLC
        {SHA256 checksum for the most recent version of the package}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id
    )
    
    $WingetPackageInfo = winget show --Id=$Id

    foreach ($line in $WingetPackageInfo) {
        if ($line.TrimStart(" ").StartsWith('SHA256:')) {
            $winget_output = $line -split ":", 2
            return $winget_output[1].TrimStart(' ') 
        }
    }
}

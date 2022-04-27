function Get-WingetDownloadUrl {
    <#
    .SYNOPSIS
        Get's the url to download the latest version of the specified package from winget.
    .DESCRIPTION
        Takes in a package ID for winget and returns the download url for the latest version of the package.
    .EXAMPLE
        PS C:\> Get-WingetDownloadUrl -Id VideoLAN.VLC
        {link to download for latest version of VLC}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id
    )
    
    $WingetPackageInfo = winget show --Id=$Id

    foreach ($line in $WingetPackageInfo) {
        if ($line.TrimStart(" ").StartsWith('Download Url:')) {
            $winget_output = $line -split ":", 2
            return $winget_output[1].TrimStart(' ')
        }
    }
}

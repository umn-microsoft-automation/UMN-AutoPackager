function Get-WinGetPublisherUrl {
    <#
    .SYNOPSIS
        Get's the url for the publisher page for the specified winget package.
    .DESCRIPTION
        Takes in a package ID for winget and returns the publisher url for the latest version of the package.
    .EXAMPLE
        PS C:\> Get-WinGetPublisherUrl -Id VideoLAN.VLC
        {link to the publisher page for latest version of VLC}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Id
    )
    
    $WingetPackageInfo = winget show --Id=$Id

    foreach ($line in $WingetPackageInfo) {
        if ($line.TrimStart(" ").StartsWith('Publisher Url:')) {
            $winget_output = $line -split ":", 2
            return $winget_output[1].TrimStart(' ') 
        }
    }
}

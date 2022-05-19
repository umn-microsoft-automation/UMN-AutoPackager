function Update-WinGetPkgSource {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to store the WinGet source (default is ($env:TEMP\WinGetSource)).')]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$($env:TEMP)\WinGetSource"
    )

    if (-not (Test-Path -Path "$Path\source")) {
        New-Item -Path $Path -Force -ItemType Directory
    }

    $null = Invoke-WebRequest -Uri "https://winget.azureedge.net/cache/source.msix" -OutFile "$Path\source.msix" -PassThru
    $null = Expand-Archive -Path "$Path\source.msix" -DestinationPath "$Path\source" -Force -PassThru

    return "$Path\source\Public\index.db"
}

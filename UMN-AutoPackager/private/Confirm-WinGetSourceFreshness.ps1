function Confirm-WinGetSourceFreshness {
    [CmdLetBinding()]
    param(
        [Parameter(Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Path to store the WinGet source (default is ($env:TEMP\WinGetSource)).')]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$($env:TEMP)\WinGetSource",

        [switch]$ForceUpdate
    )

    if (-not (Test-Path "$Path")) {
        Write-Information -MessageData "WinGet source not found. Running Update-WinGetSource."
        New-Item -ItemType Directory -Force -Path $Path
        Update-WinGetPkgSource -Path $Path
    }
    elseif (-not (Test-Path "$Path\source.msix")) {
        Write-Information -MessageData "WinGet source not found. Running Update-WinGetPkgSource."
        Update-WinGetPkgSource -Path $Path
    }
    elseif ((Get-Item -Path "$Path\source.msix").LastWriteTime -lt (Get-Date).AddHours(-1)) {
        Write-Information -MessageData "WinGet source is older than 1 hour. Updating..."
        Update-WinGetPkgSource -Path $Path
    }
    else {
        if ($ForceUpdate) {
            Write-Information -MessageData "Force update WinGet source"
            Update-WinGetPkgSource -Path $Path
        }
    }

    return "$Path\source\Public\index.db"
}

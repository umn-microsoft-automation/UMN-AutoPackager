function Get-WinGetAllPackages {
    [cmdletbinding()]
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

    if ($ForceUpdate) {
        $Database = Confirm-WinGetSourceFreshness -Path $Path -ForceUpdate
    }
    else {
        $Database = Confirm-WinGetSourceFreshness -Path $Path
    }

    $AllDataQuery = @"
select manifest.rowid, ids.id, names.name, monikers.moniker, versions.version, pathparts.pathpart, pathparts.parent
from manifest
left join ids on ids.rowid=manifest.id
left join names on names.rowid=manifest.name
left join monikers on monikers.rowid=manifest.moniker
left join versions on versions.rowid=manifest.version
left join pathparts on pathparts.rowid=manifest.pathpart
"@

    $RootQuery = "SELECT * FROM pathparts"

    $AllApps = Invoke-SqliteQuery -DataSource $Database -Query $AllDataQuery
    $AllPathparts = Invoke-SqliteQuery -DataSource $Database -Query $rootquery

    [hashtable]$parents = @{}
    [hashtable]$pathparts = @{}
    foreach ($pathpart in $AllPathparts) {
        $parents["$($pathpart.rowid)"] = $pathpart.parent
        $pathparts["$($pathpart.rowid)"] = $pathpart.pathpart
    }

    [System.Collections.ArrayList]$OutputObject = @()
    $OutputObject.Clear()
    foreach ($App in $AllApps) {
        $AppManifestPath = $App.pathpart
        $PathBuilder = $App.parent
        do {
            $Parent = $parents["$PathBuilder"]
            $PathPart = $pathparts["$PathBuilder"]
            $AppManifestPath = "$PathPart" + "/" + $AppManifestPath
            $PathBuilder = $Parent
        } while ($null -ne $PathBuilder)

        $AppManifestPath = "https://cdn.winget.microsoft.com/cache/" + $AppManifestPath
        $null = $OutputObject.Add((New-Object PSObject -Property ([ordered]@{
                        RowId        = $App.rowid
                        Id           = $App.id
                        Name         = $App.name;
                        Moniker      = $App.moniker;
                        Version      = $App.version;
                        ManifestPath = $AppManifestPath;
                    })))
    }

    return $OutputObject
}

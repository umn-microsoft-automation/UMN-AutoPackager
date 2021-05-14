$Public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue )

# Global Config Path
$GlobalConfigPath = "$($env:ProgramData)\UMN\AutoPackager\GlobalConfig.json"
Export-ModuleMember -Variable GlobalConfigPath

foreach ($Import in @($Public + $Private)) {
    try {
        . $Import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

if (Test-Path -Path $GlobalConfigPath) {
    $GlobalConfig = Get-UMNGlobalConfig -Path $GlobalConfigPath
    
    Export-ModuleMember -Variable GlobalConfig
}
else {
    Write-Error -Message "Could not find a global config at $GlobalConfigPath.`nRun Set-UMNGlobalConfig using the `$GlobalConfigPath variable."
}

# Export only the powershell functions that are public
Export-ModuleMember -Function $Public.BaseName

# Export the cmdlets from the dll.  There might be a better way of handling this aside from *, needs further investigation.
Export-ModuleMember -Cmdlet *

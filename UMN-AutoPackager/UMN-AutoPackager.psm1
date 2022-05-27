$ProgressPreference = 'SilentlyContinue'

$Public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue )

if (Test-Path -Path $PSScriptRoot\bin\UMN-AutoPackager.dll) {
    Add-Type -Path $PSScriptRoot\bin\UMN-AutoPackager.dll
}
else {
    throw "Cannot find $PSScriptRoot\bin\UMN-AutoPackager.dll"
}

# Global Config Path
$GlobalConfigDir = "$($env:ProgramData)\UMN\UMN-AutoPackager"
$GlobalConfigPath = "$GlobalConfigDir\GlobalConfig.json"

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
    Write-Verbose -Message "Imported GlobalConfig $GlobalConfig"
}
else {
    Write-Error -Message "Could not find a global config at $GlobalConfigPath.`nRun Set-UMNGlobalConfig using the `$GlobalConfigPath variable."
}

$WinGetPackages = Get-WinGetAllPackages -ForceUpdate

Write-Verbose -Message "Imported WinGetPackages $WinGetPackages"

Export-ModuleMember -Variable GlobalConfig, GlobalConfigPath, WinGetPackages

# Export only the powershell functions that are public
Export-ModuleMember -Function $Public.BaseName

# Export the cmdlets from the dll.  There might be a better way of handling this aside from *, needs further investigation.
Export-ModuleMember -Cmdlet *

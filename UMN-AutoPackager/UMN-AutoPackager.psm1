$Public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue )

foreach ($Import in @($Public + $Private)) {
    try {
        . $Import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

# Export only the powershell functions that are public
Export-ModuleMember -Function $Public.BaseName

# Export the cmdlets from the dll.  There might be a better way of handling this aside from *, needs further investigation.
Export-ModuleMember -Cmdlet *
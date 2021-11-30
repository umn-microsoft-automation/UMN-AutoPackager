param(
    [Parameter(Mandatory = $true)]
    $GlobalConfig,

    [Parameter(Mandatory = $true)]
    $PackageConfig
)

# Code to get the current version

$CurrentVersion = $PackageConfig.CurrentVersion
$NewVersion = "The version detected online"

if (Compare-Version -ReferenceVersion $CurrentVersion -DifferenceVersion $NewVersion) {
    return [hashtable]@{
        update  = $true
        version = $NewVersion
    }
}
else {
    return [hashtable]@{
        update  = $false
        version = $null
    }
}

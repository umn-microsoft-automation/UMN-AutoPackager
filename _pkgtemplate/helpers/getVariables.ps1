param($PackageConfig)

$PackageVariableTable = [hashtable]@{
    "{example}"  = "example"
    "{example2}" = $PackageConfig.Publisher
}

$PackageVariableTable

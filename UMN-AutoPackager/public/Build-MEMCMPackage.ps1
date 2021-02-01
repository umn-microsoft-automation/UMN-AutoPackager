# Creates an MEMCM package based on the standard inputs from the package definition file
# Build-MEMCMPackage -Path .\GlobalConfig.json -Name PackageConfig
# Reads the globalconfig.json using get-UMNGlobalConfig for details on the various sites information. Retrieves the specified Pacakge Config Name using get-newpackagefile. Retrieves values of packagefile using Get-PackageDefition.
# Foreach Site creates an application based on the values in the package config storing the content in the site's specified ApplicationContentPath.
# Do we want this to accept multiple packageconfig names? Yes but build out a working function first
# Do we want to expect from pipeline? Yes but first build out a working function first
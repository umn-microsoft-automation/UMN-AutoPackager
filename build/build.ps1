param(
    $task = 'Default'
)

# Grab nuget bits, install modules, set build variables, start build.

# Make sure package provider is installed (required for Docker support)
#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Pester is already installed, need to skip this check.
Install-Module -Name Pester -Force -SkipPublisherCheck

Install-Module -Name psake, PSDeploy, BuildHelpers -Force
Import-Module -Name psake, BuildHelpers

(Get-ChildItem -Recurse).FullName | Write-Warning

Set-BuildEnvironment

Invoke-PSake -BuildFile build\psake.ps1 -TaskList $Task -NoLogo

exit ( [int]( -not $psake.build_success ) )

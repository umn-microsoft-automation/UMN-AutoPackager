param(
    [switch]$PackageApp,
    [switch]$CreateCollections,
    [switch]$DeployApp
)
$Module = "UMN-AutoPackager"

Push-Location $PSScriptRoot

# Clear Output
Get-ChildItem -Path "$PSScriptRoot\..\output\$Module" | Remove-Item -Force -Recurse -Confirm:$false

# Build Module to Output
dotnet publish $PSScriptRoot\..\src -o $PSScriptRoot\..\output\$Module\bin
Copy-Item "$PSScriptRoot\..\$Module\*" "$PSScriptRoot\..\output\$Module" -Recurse -Force

$ModulePSD1 = Get-Content -Path "$PSScriptRoot\..\output\$Module\$Module.psd1"

$UpdatedModule = $ModulePSD1.Replace("{version}", "0.0.1").Replace("'{prerelease}'", "''")

Set-Content -Path "$PSScriptRoot\..\output\$Module\$Module.psd1" -Value $UpdatedModule

$ArgList = @(
    "-NoExit -Command ipmo .\UMN-AutoPackager.psd1; Invoke-AutoPackager -GlobalConfig `$GlobalConfig -InformationAction Continue"
)

if ($PackageApp) {
    $ArgList[0] = $ArgList[0] + " -PackageApp"
}

if ($CreateCollections) {
    $ArgList[0] = $ArgList[0] + " -CreateCollections"
}

if ($DeployApp) {
    $ArgList[0] = $ArgList[0] + " -DeployApp"
}

Start-Process -FilePath "pwsh.exe" -WorkingDirectory "$PSScriptRoot\..\output\$Module" -ArgumentList $ArgList

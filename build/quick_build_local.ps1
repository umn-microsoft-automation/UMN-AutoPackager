$Module = "UMN-AutoPackager"

Push-Location $PSScriptRoot

# Clear Output
Get-ChildItem -Path "$PSScriptRoot\..\output\$Module" | Remove-Item -Force -Recurse -Confirm:$false

# Build Module to Output
dotnet build $PSScriptRoot\..\src -o $PSScriptRoot\..\output\$Module\bin
Copy-Item "$PSScriptRoot\..\$Module\*" "$PSScriptRoot\..\output\$Module" -Recurse -Force

Start-Process -FilePath "pwsh.exe" -WorkingDirectory "$PSScriptRoot\..\output\$Module"

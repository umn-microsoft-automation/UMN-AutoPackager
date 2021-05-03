$Module = "UMN-AutoPackager"

Push-Location $PSScriptRoot
dotnet build $PSScriptRoot\..\src -o $PSScriptRoot\..\output\$Module\bin
Copy-Item "$PSScriptRoot\..\$Module\*" "$PSScriptRoot\..\output\$Module" -Recurse -Force

Start-Process -FilePath "pwsh.exe" -WorkingDirectory "$PSScriptRoot\..\output\$Module"
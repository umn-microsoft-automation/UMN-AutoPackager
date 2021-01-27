function Get-Config {
    [CmdletBinding()]
    param (
        [string]$Path
    )
    begin {
    }
    process {
        $json = Get-Content $Path -Raw
        $config = ConvertFrom-Json -InputObject $json
        Write-Output $config
        }
    end {
    }
}
$test = Get-Config -path C:\Users\thoen008\Desktop\GlobalConfig.json
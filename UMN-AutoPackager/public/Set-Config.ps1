# Sets global configurations for the auto packager in a standard location. This will need to be determined when building get/set config functions.
# Possible global values in JSON. Where the recipes are stored? UNC Path, Settings needed for ConfigMgr (or other tools like JAMF)? SiteCode, Site name, Service Account for access
# Set-Config -Path .\config.json -Object ConfigMgr -Name SiteCode  -Value "UMN"
# Set-Config -Path .\config.json -Name Company  -Value "University of Minnesota"
# (Get-CMSite).SiteCode | Set-Config -Path .\config.json -Object ConfigMgr  -Name SiteCode
# $json = Get-Content C:\users\thoen008\Desktop\GlobalConfig.json -Raw
# $obj = ConvertFrom-Json -InputObject $json
function Set-Config {
    [CmdletBinding()]
    param (
        [string]$Path,
        [string]$Key,
        [string]$Value
    )
    begin {
    }
    process {
        $json = Get-Content $Path -Raw
        $config = ConvertFrom-Json -InputObject $json
        $Keys = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        foreach ($k in $Keys) {
            if ($config.$k.gettype().Name -eq 'String') {
                Write-Output "This $k is a string."
                if ($k -eq $Key) {
                    Write-output "Found $k setting new value. "
                    $config.$k = $Value
                    Write-Output $config
                }
            }
            else{
                $Type = "Not String"
                Write-Output "Not String"
            }
            if ($Type -eq "Not String") {
               Write-Output "Type is not string and is Array"
               if ($k -eq $Key) {
                   Write-Output "Found $k adding additional value."
                   [System.collections.ArrayList]$new = $config.$k
                   $new.add("$value")
                   $config.$k = $new
                   Write-Output $config
               }
            }
            else{
                Write-Output "This is not a Array"
            }
        }
    }
    end {
    }
}
Set-Config -Path C:\Users\thoen008\Desktop\GlobalConfig.json -Key "RecipeLocations" -Value "C:\MyProgram"
<# $locations = New-Object 'System.Collections.Generic.list[string]'
$locations.add("C:\Temp")
$locations.add("\\files.somewhere\")
[PSCustomObject]@{
    CompanyName = "MyCompany"
    LastModified = (Get-Date).ToString()
    ConfigMgrSite = "site.something.com"
    ConfigMgrSiteCode = "COM"
    RecipeLocations = $locations
} | convertto-json | Set-Content C:\Users\thoen008\Desktop\GlobalConfig.json #>

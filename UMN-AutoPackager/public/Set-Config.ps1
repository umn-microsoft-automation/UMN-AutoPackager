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
        [string]$Name,
        [string]$Value
    )
    begin {
    }
    process {
        $json = Get-Content $Path -Raw
        $config = ConvertFrom-Json -InputObject $json
        $Names = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        foreach ($name in $Names) {
            if ($config.$name -eq "PSCustomObject") {
                $NewNames = $Config.$Name | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                foreach ($newname in $NewNames) {
                    # check against the $name and update the value with the new one
                }
            }
            elseif ($config.$name -eq "String") {
                # Check against the $name and update the value with the new one
            }
        }
    }
    end {
    }
}

<# [PSCustomObject]@{
    CompanyName = "MyCompany"
    LastModified = (Get-Date).ToString()
    ConfigMgr = @{Site = "site.something.com"
                 SiteCode = "COM"}
    RecipeLocations = @{Location1 = "C:\Temp"
                     Location2 = "\\files.somewhere\"}
} | convertto-json | Set-Content C:\Users\thoen008\Desktop\GlobalConfig.json #>

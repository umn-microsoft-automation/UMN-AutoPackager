# Pulls a json config file from a standard location. Gets global configurations for the auto packager out of the json config file. This will need to be determined when building get/set config functions.
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
        $Names = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        foreach ($name in $Names) {
            if ($config.$name -eq "PSCustomObject") {
                $NewNames = $Config.$Name | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                foreach ($newname in $NewNames) {
                    # Output the name and value(s)
                }
            }
            elseif ($config.$name -eq "String") {
                # Output the value
            }
        }
    }
    end {
    }
}
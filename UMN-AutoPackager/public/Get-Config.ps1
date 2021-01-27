function Get-Config {
    <#
    .SYNOPSIS
        Gets all the global configurations and value for each from a JSON file used the auto packager.
    .DESCRIPTION
        This command retrieves from a json file the values of various global configurations used as part of the AutoPackager. It requires a the full path and name of the JSON file.
    .EXAMPLE
        Get-Config -Path .\config.json
        Gets the values of the config.json file
    .PARAMETER Path
        The full path and file name of the JSON file to be updated
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
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
}#Get-Config
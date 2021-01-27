function Set-Config {
    <#
    .SYNOPSIS
        Sets a value for the global configuration JSON file for the auto packager.
    .DESCRIPTION
        This command sets in a json file a value for one of various global configurations used as part of the AutoPackager. It requires a the full path and name of the JSON file, the key to set, and the value to set it to.
    .EXAMPLE
        Set-Config -Path .\config.json -Key CompanyName  -Value "University of Minnesota"
        Sets the value of CompanyName to University of Minnesota for the config.json file
    .PARAMETER Path
        The full path and file name of the JSON file to be updated
    .PARAMETER Key
        The key that you want to update in the Global Configuation JSON file
    .PARAMETER Value
        The value you want to set the key to
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand) Updating $key with $value"
    }
    process {
        $json = Get-Content $Path -Raw
        $config = ConvertFrom-Json -InputObject $json
        $Keys = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        foreach ($k in $Keys) {
            Write-Verbose -Message "Querying $k"
            if ($config.$k.gettype().Name -eq 'String') {
                Write-Verbose "$k is a string"
                if ($k -eq $Key) {
                    Write-Verbose "Found match $k setting new value"
                    $config.$k = $Value
                    $config.LastModified = (Get-Date).ToString()
                    $config | convertto-json | Set-Content $path
                    Write-Verbose -Message "$key is updated with $value"
                }
            }
            if ($config.$k.gettype().Name -eq "Object[]") {
               Write-Verbose "$k is Array"
               if ($k -eq $Key) {
                   Write-Verbose "Found match for $k"
                   if ($config.$k -contains $value) {
                       Write-Verbose -Message "Already contains $value"
                   }
                   else {
                    [System.collections.ArrayList]$new = $config.$k
                    $new.add("$value") > $null
                    $config.$k = $new
                    $config.LastModified = (Get-Date).ToString()
                    $config | convertto-json | Set-Content $path
                    Write-Verbose -Message "$key is updated with $value"
                   }
               }
            }
        } #foreach $key
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Set-Config


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
        [Parameter(Mandatory=$True, HelpMessage = "The full path and file name of the JSON file to be updated")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory=$True, HelpMessage = "The key that you want to update in the Global Configuation JSON file")]
        [ValidateNotNullOrEmpty()]
        [string]$Key,
        [Parameter(Mandatory=$True, HelpMessage = "The value you want to set the key to")]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand) Updating $key with $value"
    }
    process {
        $config = Get-GlobalConfig -Path $Path
        $Keys = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        if ($Keys -contains $Key) {
            Write-Verbose -Message "$Key is a valid Key."
            foreach ($k in $Keys) {
                Write-Verbose -Message "Querying $k"
                if ($config.$k.gettype().Name -eq 'String') {
                    Write-Verbose "$k is a string"
                    if ($k -eq $Key) {
                        Write-Verbose "Found match $k setting new value"
                        $config.$k = $Value
                        $config.LastModified = (Get-Date).ToString()
                        try {
                        $config | convertto-json -ErrorAction Stop | Set-Content $path -ErrorAction Stop
                        Write-Verbose -Message "$key is updated with $value"
                        }
                        catch {
                           Write-Warning -Message "Failed to update JSON file. $($_Exception.message)"
                        }
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
                        try {
                            $config | convertto-json | Set-Content $path
                        Write-Verbose -Message "$key is updated with $value"
                        }
                        catch {
                           Write-Warning -Message "Failed to update JSON file. $($_Exception.message)"
                        }
                       }
                   }
                }
            } #foreach $key
        }
        else {
            Write-Warning -Message "$Key is not a valid Key."
        }
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Set-Config
function Get-UMNGlobalConfig {
    <#
    .SYNOPSIS
        Gets all the global configurations and value for each from a JSON file used by the auto packager.
    .DESCRIPTION
        This command retrieves from a json file the values of various global configurations used as part of the AutoPackager. It requires a the full path and name of the JSON file.
    .EXAMPLE
        Get-UMNGlobalConfig -Path .\config.json
        Gets the values of the config.json file
    .PARAMETER Path
        The full path and file name of the JSON file to get the config from
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, HelpMessage = "The full path and file name of the JSON file to get the config from")]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand)"
    }
    process {
        $json = Get-Content -Path $Path -Raw
        $config = ConvertFrom-Json -InputObject $json
        Write-Output -InputObject $config
        }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Get-Config
function Set-UMNGlobalConfig {
    <#
    .SYNOPSIS
        Sets a value(s) for the global configuration JSON file for the auto packager.
    .DESCRIPTION
        This command sets in a json file a value for one of various global configurations used as part of the AutoPackager. It requires a the full path and name of the JSON file, the key to set, and the value to set it to.
    .EXAMPLE
        Set-UMNGlobalConfig -Path .\config.json -Key CompanyName  -Value "University of Minnesota"
        Sets the value of CompanyName to University of Minnesota for the config.json file
    .EXAMPLE
        Set-UMNGlobalConfig -Path .\config.json -SiteServer "my.config.site"  -SiteCode "COM" -DownloadLocationPath "C:\\Temp" -ApplicatoinContentPath "\\appstorage.somewhere\"
        Sets the values for a ConfigMgr site to be added to the config.json file
    .PARAMETER Path
        The full path and file name of the JSON file to be updated
    .PARAMETER Key
        The key that you want to update in the Global Configuation JSON file
    .PARAMETER Value
        The value you want to set the key to
    .PARAMETER SiteServer
        The ConfigMgr site server address
    .PARAMETER SiteCode
        The site code for this instance of ConfigMgr
    .PARAMETER DownloadLocationPath
        The full path where downloaded data will be temporarily stored
    .PARAMETER ApplicationContentPath
        The full path for where ConfigMgr applcation content will be stored"
    #>
    [CmdletBinding(DefaultParameterSetName="Main")]
    param (
        [Parameter(ParameterSetName="Main",Mandatory=$True, HelpMessage = "The full path and file name of the JSON file to be updated")]
        [Parameter(ParameterSetName="ConfigMgr")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(ParameterSetName="Main",Mandatory=$True, HelpMessage = "The key that you want to update in the Global Configuation JSON file")]
        [ValidateNotNullOrEmpty()]
        [string]$Key,
        [Parameter(ParameterSetName="Main",Mandatory=$True, HelpMessage = "The value you want to set the key to")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The ConfigMgr site server address")]
        [string]$SiteServer,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The site code for this instance of ConfigMgr")]
        [string]$SiteCode,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The full path where downloaded data will be temporarily stored")]
        [string]$DownloadLocationPath,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The full path for where ConfigMgr applcation content will be stored")]
        [string]$ApplicationContentPath
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand) Updating $key with $value"
    }
    process {
        $config = Get-UMNGlobalConfig -Path $Path
        $Keys = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        if ($Keys -contains $Key) {
            Write-Verbose -Message "$Key is a valid Key."
            foreach ($k in $Keys) {
                Write-Verbose -Message "Querying $k"
                if ($config.$k.gettype().Name -eq 'String') {
                    Write-Verbose -Message "$k is a string"
                    if ($k -eq $Key) {
                        Write-Verbose -Message "Found match $k setting new value"
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
                   Write-Verbose -Message "$k is Array"
                   if ($PSCmdlet.ParameterSetName -eq "Main") {
                       Write-Verbose -Message "Parameter set is Main"
                       # add a parameter check for Configmgr
                        if ($k -eq $Key) {
                            Write-Verbose -Message "Found match for $k"
                            if ($config.$k -contains $value) {
                                # Move these tests to the specific if statements
                                Write-Verbose -Message "Already contains $value"
                            }
                            elseif ($k -eq "RecipeLocations") {
                                # Maybe make a new Parameter set for recipelocations and add locationType
                                $config.$k += New-Object -TypeName PSObject -Property ([ordered]@{locationType="directory";locationUri=$Value})
                                $config.LastModified = (Get-Date).ToString()
                                try {
                                    $config | convertto-json | Set-Content -Path $path
                                Write-Verbose -Message "$key is updated with $value"
                                }
                                catch {
                                Write-Warning -Message "Failed to update JSON file. $($_Exception.message)"
                                }
                            }
                            else {
                                [System.collections.ArrayList]$new = $config.$k
                                $new.add("$value") > $null
                                $config.$k = $new
                                $config.LastModified = (Get-Date).ToString()
                                try {
                                    $config | convertto-json | Set-Content -Path $path
                                Write-Verbose -Message "$key is updated with $value"
                                }
                                catch {
                                Write-Warning -Message "Failed to update JSON file. $($_Exception.message)"
                                }
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
Set-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\GlobalConfig.json -Key "RecipeLocations" -Value "C:\temp2" -Verbose
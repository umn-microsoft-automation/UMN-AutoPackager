function Set-UMNGlobalConfig {
    <#
    .SYNOPSIS
        Sets a value(s) for the global configuration JSON file for the auto packager.
    .DESCRIPTION
        This command sets in a json file a value for one of various global configurations used as part of the AutoPackager. It requires a the full path and name of the JSON file, the key to set, and the value to set it to.
    .EXAMPLE
        Set-UMNGlobalConfig -Path .\GlobalConfig.json -Key CompanyName  -Value "University of Minnesota"
        Sets the value of CompanyName to University of Minnesota for the config.json file
    .EXAMPLE
        Set-UMNGlobalConfig -Path .\GlobalConfig.json -Key ConfigMgr -SiteServer "my.config.site"  -SiteCode "COM" -DownloadLocationPath "C:\Temp" -ApplicationContentPath "\\appstorage.somewhere\"
        Sets the values for a ConfigMgr site to be added to the config.json file
    .EXAMPLE
        Set-UMNGlobalConfig -Path .\GlobalConfig.json -Key RecipeLocations -Value "\\file.server\recipes" -LocationType "directory"
        Adds the location "\\files.server\recipes" and LocationType "directory" to the RecipeLocations key in the JSON specified
    .PARAMETER Path
        The full path and file name of the JSON file to be updated
    .PARAMETER Key
        The key that you want to update in the Global Configuation JSON file
    .PARAMETER Value
        The single value you want to set the key to
    .PARAMETER SiteServer
        The ConfigMgr site server address
    .PARAMETER SiteCode
        The site code for this instance of ConfigMgr
    .PARAMETER DownloadLocationPath
        The full path where downloaded data will be temporarily stored
    .PARAMETER ApplicationContentPath
        The full path for where ConfigMgr applcation content will be stored
    .PARAMETER LocationType
        The location type for where the recipes will be stored for the autopackager. Directory will be the most common.
    #>
    [CmdletBinding(DefaultParameterSetName="Main")]
    param (
        [Parameter(ParameterSetName="Main",Mandatory=$True, HelpMessage = "The full path and file name of the JSON file to be updated")]
        [Parameter(ParameterSetName="ConfigMgr")]
        [Parameter(ParameterSetName="RecipeLocations")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(ParameterSetName="Main",Mandatory=$True, HelpMessage = "The key that you want to update in the Global Configuation JSON file")]
        [Parameter(ParameterSetName="ConfigMgr")]
        [Parameter(ParameterSetName="RecipeLocations")]
        [ValidateNotNullOrEmpty()]
        [string]$Key,
        [Parameter(ParameterSetName="Main",Mandatory=$True, HelpMessage = "The value you want to set the key to")]
        [Parameter(ParameterSetName="RecipeLocations")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The ConfigMgr site server address")]
        [string]$SiteServer,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The site code for this instance of ConfigMgr")]
        [string]$SiteCode,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The full path where downloaded data will be temporarily stored")]
        [string]$DownloadLocationPath,
        [Parameter(ParameterSetName="ConfigMgr",Mandatory=$True, HelpMessage = "The full path for where ConfigMgr applcation content will be stored")]
        [string]$ApplicationContentPath,
        [Parameter(ParameterSetName="RecipeLocations",Mandatory=$True, HelpMessage = "The location type for where the recipes will be stored for the autopackager.")]
        [string]$LocationType
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand)"
    }
    process {
        $config = Get-UMNGlobalConfig -Path $Path
        $Keys = $config | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        if ($Keys -contains $Key) {
            Write-Verbose -Message "$Key is a valid Key."
            foreach ($k in $Keys) {
                Write-Verbose -Message "Querying $k"
                if ($config.$k.gettype().Name -eq 'String') {
                  # Write-Verbose -Message "$k is a string"
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
                }#String Type
                if ($config.$k.gettype().Name -eq "Object[]") {
                  # Write-Verbose -Message "$k is Array"
                   if ($PSCmdlet.ParameterSetName -eq "Main") {
                      # Write-Verbose -Message "Parameter set is Main"
                        if ($k -eq $Key) {
                            Write-Verbose -Message "Found match for $k"
                            if ($config.$k -contains $value) {
                                Write-Warning -Message "$Key already contains $value"
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
                   if ($PSCmdlet.ParameterSetName -eq "RecipeLocations") {
                       # Write-Verbose -Message "Parameter set is RecipeLocations"
                        if ($k -eq "RecipeLocations") {
                            if ($config.$k.locationUri -contains $value) {
                                Write-Warning -Message "$Key already contains $value"
                            }
                            else {
                                $config.$k += New-Object -TypeName PSObject -Property ([ordered]@{locationType=$LocationType;locationUri=$Value})
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
                    if ($PSCmdlet.ParameterSetName -eq "ConfigMgr") {
                        # Write-Verbose -Message "Parameter set is ConfigMgr"
                        if ($k -eq "ConfigMgr") {
                            if ($config.$k.Site -contains $SiteServer) {
                                Write-Warning -Message "ConfigMgr already contains a Site Server: $SiteServer"
                            }
                            else {
                                $config.$k += New-Object -TypeName PSObject -Property ([ordered]@{Site=$SiteServer;SiteCode=$SiteCode;DownloadLocationPath= $DownloadLocationPath;ApplicationContentPath=$ApplicationContentPath})
                                $config.LastModified = (Get-Date).ToString()
                                try {
                                    $config | convertto-json | Set-Content -Path $path
                                Write-Verbose -Message "$key is updated with $SiteServer information"
                                }
                                catch {
                                Write-Warning -Message "Failed to update JSON file. $($_Exception.message)"
                                }
                            }
                        }
                    }
                 }#Object{} Type
                 else {
                   # Write-Verbose -Message "Does not match $k"
                }
            }#foreach $key
        }
        else {
            Write-Warning -Message "$Key is not a valid Key"
        }
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Set-Config
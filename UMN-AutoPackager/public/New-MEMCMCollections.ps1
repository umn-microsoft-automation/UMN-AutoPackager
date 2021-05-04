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
        [Parameter(Mandatory = $True, HelpMessage = "The full path and file name of the JSON file to get the config from")]
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
}#Get-UMNGlobalConfig
# Creates a collection(s) based on the Config settings. Need the Limiting Collection to base this on.
function New-MEMCMCollections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Input the values of the GlobalConfig.json.")]
        [psobject]$GlobalConfig,
        [Parameter(Mandatory = $true,
            HelpMessage = "Input the values of the various packagedefinition.json files.")]
        [psobject[]]$PackageDefinition,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand)"
        Import-Module -Name "$($env:SystemDrive)\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\ConfigurationManager.psd1"
    }
    process {
        foreach ($ConfigMgrObject in ($GlobalConfig.ConfigMgr)) {
            Write-Verbose -Message "Processing $ConfigMgrObject Site..."
            $SiteCode = $ConfigMgrObject.SiteCode
            try {
                if (-not (Test-Path -Path $SiteCode)) {
                    $ConfigMgrDrive = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ConfigMgrObject.Site -Credential $Credential
                }
            }
            catch {
                Write-Error $Error[0]
                Write-Warning -Message "Error: $($_.Exception.Message)"
            }
            Push-Location
            Set-Location -Path "$SiteCode`:\"
            foreach ($PkgObject in $PackageDefinition) {
                Write-Verbose -Message "Processing the package definition $($pkgObject.publisher) $($pkgObject.productname)"
                foreach ($collection in $PkgObject.CollectionTargets) {
                    if (($collection.type -eq "MEMCM-Collection") -and (-not (Get-CMCollection -Name $collection.Name))) {
                        # Collection does not exist, building the collection.
                        Write-Verbose -Message "Building collection $($collection.name) for ConfigMgr"
                        $CollectionArguments = @{
                            Name                   = $collection.Name
                            LimitingCollectionName = $collection.LimitingCollectionName
                            RefreshType            = $collection.RefreshType
                            RefreshSchedule        = ""
                        }
                        # RefreshType is Periodic or Both. Build a schedule and create the collection.
                        if ($CollectionArguments.RefreshType -eq "Periodic" -or $CollectionArguments.RefreshType -eq "Both") {
                            Write-Verbose -Message "Collection is using a Periodic schedule"
                            $startdate = Get-Date -month $collection.month -day $collection.day -year $collection.year -hour $collection.hour -minute $collection.minute
                            if ($collection.RecurInterval -eq "Days" -or $collection.RecurInterval -eq "Hours" -or $collection.RecurInterval -eq "Minutes") {
                                Write-Verbose -Message "Periodic is using days, hours, or minutes"
                                $sched = New-CMSchedule -Start $startdate -RecurInterval $collection.RecurInterval -Recurcount $collection.RecurCount
                                $CollectionArguments.set_item("RefreshSchedule", $sched)
                            }
                            elseif ($collection.RecurInterval -eq "Month") {
                                Write-Verbose -Message "Periodic using month"
                                if ($collection.LastDayofMonth -eq $true) {
                                    Write-Verbose -Message "Periodic is using LastDayOfMonth"
                                    $sched = New-CMSchedule -Start $startdate -LastDayOfMonth
                                    $CollectionArguments.set_item("RefreshSchedule", $sched)
                                }
                                elseif ($collection.WeekOrder) {
                                    Write-Verbose -Message "Periodic is using WeekOrder"
                                    $sched = New-CMSchedule -Start $startdate -DayOfWeek $collection.DayOfWeek -WeekOrder $collection.WeekOrder -RecurCount $collection.RecurCount
                                    $CollectionArguments.set_item("RefreshSchedule", $sched)
                                }
                                elseif ($collection.DayOfMonth) {
                                    Write-Verbose -Message "Periodic is using Day of Month"
                                    $sched = New-CMSchedule -Start $startdate -DayOfMonth $collection.DayOfMonth -RecurCount $collection.RecurCount
                                    $CollectionArguments.set_item("RefreshSchedule", $sched)
                                }
                            }
                            elseif ($collection.RecurInterval -eq "Week") {
                                Write-Verbose -Message "Periodic is using week"
                                $sched = New-CMSchedule -Start $startdate -DayOfWeek $collection.DayOfWeek -RecurCount $collection.RecurCount
                                $CollectionArguments.set_item("RefreshSchedule", $sched)
                            }
                            # Create the periodic collection
                            Write-Verbose -Message "Creating the collection: $($CollectionArguments.Name)"
                            try {
                                New-CMDeviceCollection @CollectionArguments
                            }
                            catch {
                                Write-Error $Error[0]
                                Write-Warning -Message "Error: $($_.Exception.Message)"
                            }
                        }
                        else {
                            # Create the non-periodic collection
                            Write-Verbose -Message "Not periodic creating the collection: $($CollectionArguments.Name)"
                            $CollectionArguments.Remove('RefreshSchedule')
                            try {
                                New-CMDeviceCollection @CollectionArguments
                            }
                            catch {
                                Write-Error $Error[0]
                                Write-Warning -Message "Error: $($_.Exception.Message)"
                            }
                        }
                    }
                    else {
                        Write-Verbose -Message "$($collection.Name) exists already or is not a MEMCM-Collection type."
                    }
                }#foreach $CollectionTargets
            }#foreach $PackageDefinition
            Pop-Location
            $ConfigMgrDrive | Remove-PSDrive
        }#foreach $ConfigMgrObject
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#New-MEMCMCollections
New-MEMCMCollections -GlobalConfig (Get-UMNGlobalConfig C:\users\thoen008\Desktop\GlobalConfig.json) -PackageDefinition (Get-UMNGlobalConfig C:\users\thoen008\Desktop\PackageConfig.json) -Credential oitthoen008 -Verbose
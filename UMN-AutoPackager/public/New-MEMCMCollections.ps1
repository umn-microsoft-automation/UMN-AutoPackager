function New-MEMCMCollections {
    <#
    .SYNOPSIS
    Creates new collections in Configuration Manager based on the values of the UMNAutopackager json files.
    .DESCRIPTION
    This command creates new collection(s) for each site based on the values of the GlobalConfig and PackageConfig json values. It leverages various powershell commands provided with ConfigMgr.
    .PARAMETER GlobalConfig
    Input the global configuration json file using the Get-GlobalConfig command
    .PARAMETER PackageDefinition
    Input the package definition json file using the Get-GlobalConfig command
    .PARAMETER Credential
    Input the credentials object or the user name which will prompt for credentials. If not called will attempt to use the credentials of the account that is running the script.
    .EXAMPLE
    New-MEMCMCollections -GlobalConfig (Get-UMNGlobalConfig -Path C:\UMNAutopackager\GlobalConfig.json) -PackageDefinition (Get-UMNGlobalConfig -Path C:\UMNAutopackager\PackageConfig.json) -Credential MyUserName
    Runs the function prompting for the credentials of MyUserName.
    .EXAMPLE
    New-MEMCMCollections -GlobalConfig $globaljson -PackageDefinition $pkgjson -Credential $creds
    Runs the function using the credentials stored in the $creds variable.
    #>
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
        foreach ($ConfigMgrObject in ($GlobalConfig.packagingTargets)) {
            Write-Verbose -Message "Processing $($ConfigMgrObject.site) Site..."
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
                if ($PkgObject.overridePackagingTargets -eq $True) {
                    Write-Verbose -Message "Processing the package definition in package config: $($pkgObject.publisher) $($pkgObject.productname)"
                    foreach ($collection in $PkgObject.packagingTargets.collectionTargets) {
                        if (($collection.type -eq "MEMCM-Collection") -and (-not (Get-CMCollection -Name $collection.Name))) {
                            Write-Verbose -Message "Building collection $($collection.name) for ConfigMgr"
                            $CollectionArguments = @{
                                Name                   = $collection.Name
                                LimitingCollectionName = $collection.limitingCollectionName
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
                    }#foreach override true: $CollectionTargets
                }
                elseif ($PkgObject.overridePackagingTargets -eq $false) {
                    Write-Verbose -Message "Processing the package definition in global config: $($pkgObject.publisher) $($pkgObject.productname)"
                    foreach ($collection in $ConfigMgrObject.CollectionTargets) {
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
                    }#foreach override false: $CollectionTargets
                }
            }#foreach $PackageDefinition
            Pop-Location
            $ConfigMgrDrive | Remove-PSDrive
        }#foreach $ConfigMgrObject
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#New-MEMCMCollections
function New-MEMCMCollections {
    <#
    .SYNOPSIS
        Creates new collections in Configuration Manager based on the values of the UMNAutopackager json files.
    .DESCRIPTION
        This command creates new collection(s) for each site based on the values of the GlobalConfig and PackageConfig json values. It leverages various powershell commands provided with ConfigMgr.
    .PARAMETER GlobalConfig
        Input the global configuration json file using the Get-GlobalConfig command
    .PARAMETER SiteTarget
        This is the PackagingTargets section of either the GlobalConfig or PackageConfig, whichever has the site info.
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
        $GlobalConfig,

        $SiteTarget,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    begin {
        Write-Verbose -Message "Starting $($myinvocation.mycommand)"
        Import-Module -Name $GlobalConfig.MEMCMModulePath.LocalPath
    }
    process {
        Write-Verbose -Message "Processing $($SiteTarget.Site) Site..."
        $SiteCode = $SiteTarget.SiteCode

        try {
            if (-not (Test-Path -Path $SiteCode)) {
                $ConfigMgrDrive = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteTarget.Site -Credential $Credential
            }
        }
        catch {
            Write-Error $Error[0]
            Write-Warning -Message "Error: $($_.Exception.Message)"
        }

        Push-Location
        Set-Location -Path "$SiteCode`:\"
        foreach ($Collection in $SiteTarget.CollectionTargets) {
            if (($Collection.Type -eq "MEMCM-Collection") -and (-not (Get-CMCollection -Name $Collection.Name))) {
                Write-Verbose -Message "Building MEMCM collection $($Collection.Name)"
                $CollectionArguments = @{
                    Name                   = $Collection.name
                    LimitingCollectionname = $Collection.LimitingCollectionName
                    RefreshType            = $Collection.RefreshType
                    CollectionType         = "Device"
                    RefreshSchedule        = ""
                }

                # RefreshType is Periodic or Both.  Build a schedule and create the collection.
                if ($CollectionArguments.RefreshType -eq "Periodic" -or $CollectionArguments.RefreshType -eq "Both") {
                    Write-Verbose -Message "Collection is using a Periodic or Both schedule"
                    $StartDate = Get-Date -Month $Collection.Month -Day $Collection.Day -Year $Collection.Year -Hour $Collection.Hour -Minute $Collection.Minute
                    if ($Collection.RecurInterval -eq "Days" -or $Collection.RecurInterval -eq "Hours" -or $Collection.RucurInterval -eq "Minutes") {
                        Write-Verbose -Message "Periodic is using days, hours or minutes"
                        $Sched = New-CMSchedule -Start $StartDate -RecurInterval $Collection.RecurInterval -RecurCount $Collection.RecurCount
                        $CollectionArguments.set_item("RefreshSchedule", $Sched)
                    }
                    elseif ($Collection.RecurInterval -eq "Month") {
                        Write-Verbose -Message "Periodic using month"
                        if ($Collection.LastDayOfMonth -eq $true) {
                            Write-Verbose -Message "Periodic is using LastDayOfMonth"
                            $Sched = New-CMSchedule -Start $StartDate -LastDayOfMonth
                            $CollectionArguments.set_item("RefreshSchedule", $Sched)
                        }
                        elseif ($Collection.WeekOrder) {
                            Write-Verbose -Message "Periodic is using WeekOrder"
                            $Sched = New-CMSchedule -Start $StartDate -DayOfWeek $Collection.DayOfWeek -WeekOrder $Collection.WeekOrder -RecurCount $Collection.RecurCount
                            $CollectionArguments.set_item("RefreshSchedule", $Sched)
                        }
                        elseif ($Collection.DayOfMonth) {
                            Write-Verbose -Message "Periodic is using Day of Month"
                            $Sched = New-CMSchedule -Start $StartDate -DayOfMonth $Collection.DayOfMonth -RecurCount $Collection.RecurCount
                            $CollectionArguments.set_item("RefreshSchedule", $Sched)
                        }
                        else {
                            Write-Verbose -Message "No periodic matches found"
                        }

                        # Create the periodic collection
                        Write-Verbose -Message "Creating the collection: $($Collection.Name)"
                        try {
                            New-CMCollection @CollectionArguments
                        }
                        catch {
                            Write-Error $Error[0]
                            Write-Warning -Message "Error: $($_.Exception.Message)"
                        }
                    }
                }
                else {
                    # Create the non-periodic collection
                    Write-Verbose -Message "Not periodic creating the collection $($Collection.Name)"
                    $CollectionArguments.Remove("RefreshSchedule")
                    try {
                        New-CMCollection @CollectionArguments
                    }
                    catch {
                        Write-Error $Error[0]
                        Write-Warning -Message "Error: $($_.Exception.Message)"
                    }
                }
            }
            else {
                Write-Verbose -Message "$($Collection.Name) exists already or is not a MEMCM-Collection type."
            } 
        }#foreach CollectionTargets
        Pop-Location
        $ConfigMgrDrive | Remove-PSDrive
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#New-MEMCMCollections

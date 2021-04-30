# Create standard MEMCM collections based off global configuration
# Create-MEMCMCollections -Path .\GlobalConfig.json -Name PackageConfig
# Creates a collection(s) based on the Global Config settings. Need the Limiting Collection to base this on.
# Where does the naming convention come from? This should be unique so we can use it for the deploy function. Maybe it adds the collection name(s) to the package config?
# Let's start simple with a single collection based on some information from the PacakgeConfig.
# Maybe we use a switch to define the various ways to deploy. Single, Three Collection Rollout, Phased Deployment Collection. Or maybe it makes a query
# Options to change the standard settings for collection evaluation or to make it incremental.
# Keep in mind user deployment versus device?
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
                    if ($collection.type -eq "MEMCM-Collection") {
                        Write-Verbose -Message "Building collection $($collection.name) for ConfigMgr"
                        # build in a check to see if the collection name exists
                        $CollectionArguments = @{
                            Name = $collection.Name
                            LimitingCollectionName = $collection.LimitingCollectionName
                            # RefreshType must be None, Manual, Periodic, Continuous, Both
                            RefreshType = $collection.RefreshType
                            RefreshSchedule = ""
                        }
                        # Check if RefreshType is Periodic. If it is build a schedule based on the values in the json.
                        if ($CollectionArguments.RefreshType -eq "Periodic" -or $CollectionArguments.RefreshType -eq "Both") {
                            Write-Verbose -Message "Collection is using a Periodic schedule"
                            $startdate = Get-Date -month $collection.month -day $collection.day -year $collection.year -hour $collection.hour -minute $collection.minute
                            $sched = New-CMSchedule -Start $startdate -DurationInterval $collection.DurecationInverval -RecurInterval $collection.RecurInterval
                            $CollectionArguments.set_item("RefreshSchedule",$sched)
                            Write-Output $CollectionArguments
                        }
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
}
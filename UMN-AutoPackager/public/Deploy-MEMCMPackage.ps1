function Deploy-MEMCMPackage {
    <#
    .SYNOPSIS
    Creates deployments in Configuration Manager based on the values of the UMNAutopackager json files.
    .DESCRIPTION
    This command creates new deployment(s) for each site based on the values of the GlobalConfig and PackageConfig json values. It leverages various powershell commands provided with ConfigMgr.
    .PARAMETER GlobalConfig
    Input the global configuration json file using the Get-GlobalConfig command
    .PARAMETER PackageDefinition
    Input the package definition json file using the Get-GlobalConfig command
    .PARAMETER Credential
    Input the credentials object or the user name which will prompt for credentials. If not called will attempt to use the credentials of the account that is running the script.
    .EXAMPLE
    Deploy-MEMCMPackage -GlobalConfig (Get-UMNGlobalConfig -Path C:\UMNAutopackager\GlobalConfig.json) -PackageDefinition (Get-UMNGlobalConfig -Path C:\UMNAutopackager\PackageConfig.json) -Credential MyUserName
    Runs the function prompting for the credentials of MyUserName.
    .EXAMPLE
    Deploy-MEMCMPackage -GlobalConfig $globaljson -PackageDefinition $pkgjson -Credential $creds
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
        if ($PackageDefinition.overridePackagingTargets -eq $True) {
            Write-Verbose -Message "Override is true using the PackageDefinition settings"
            $packageTargets = $PackageDefinition.packagingTargets
        }
        else {
            $packageTargets = $GlobalConfig.packagingTargets
            Write-Verbose -Message "Override is false using the GlobalDefinition settings"
        }
        foreach ($ConfigMgrObject in $packageTargets) {
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
            Write-Verbose -Message "Processing the package definition for $($PackageDefinition.publisher) $($PackageDefinition.productname)"
            if ($ConfigMgrObject.type -eq "MEMCM-Application") {
                if (Get-CMApplication -Name $PackageDefinition.packagingTargets.name) {
                    Write-Verbose -Message "Application $($ConfigMgrObject.name) exists"
                    foreach ($collection in $ConfigMgrObject.collectionTargets) {
                        Write-Verbose -Message "Checking for deployment settings on Collection Target: $($collection.name)"
                        if ($collection.deploymentSettings) {
                            Write-Verbose -Message "Checking if the collection $($collection.name) exists"
                            if (Get-CMCollection -Name $collection.Name) {
                                Write-Verbose -Message "Checking if the collection has any deployments"
                                if (Get-CMApplicationDeployment -CollectionName $collection.name) {
                                    Write-Verbose -Message "$($collection.name) contains deployments"
                                    $deployments = Get-CMApplicationDeployment -CollectionName "$($collection.name)"
                                    foreach ($deploy in $deployments) {
                                        if ($deploy.ApplicationName -match $PackageDefinition.publisher -and $PackageDefinition.ApplicationName -match $ConfigMgrObject.productName) {
                                            Write-Verbose -Message "$($deploy.ApplicationName) matches the publisher and product name of an existing deployment, removing deployment"
                                            try {
                                                Remove-CMApplicationDeployment -Name "$($deploy.ApplicationName)" -CollectionName "$($collection.name)" -Force -ErrorAction Stop
                                            }
                                            catch {
                                                Write-Error $Error[0]
                                                Write-Warning -Message "Error: $($_.Exception.Message)"
                                            }
                                        }
                                        else {
                                            Write-Verbose -Message "No matching deployment found"
                                        }
                                    }
                                }
                                else {
                                    Write-Verbose -Message "The collection: $($collection.name) does not have an existing deployment"
                                }
                                # Get the application name based on which config file is being used
                                # if true just grab it since it will be part of the foreach loop
                                # if false loop through the packagingtargets in packagedefintion and match against site and sitecode
                                if ($PackageDefinition.overridePackagingTargets -eq $True) {
                                    $AppName = $ConfigMgrObject.Name
                                }
                                else {
                                    foreach ($target in $PackageDefinition.packagingTargets) {
                                        if (($target.site -eq $ConfigMgrObject.site) -and (($target.siteCode -eq $ConfigMgrObject.siteCode))) {
                                            $AppName = $target.name
                                        }
                                    }
                                }
                                Write-Output $AppName
                                Write-Verbose -Message "Building deployment..."
                                $DeploymentArguments = @{
                                    Name                               = $AppName
                                    CollectionName                     = $collection.Name
                                    AllowRepairApp                     = $collection.deploymentSettings.allowRepairApp
                                    DeployAction                       = $collection.deploymentSettings.DeployAction
                                    DeployPurpose                      = $collection.deploymentSettings.DeployPurpose
                                    OverrideServiceWindow              = $collection.deploymentSettings.OverrideServiceWindow
                                    PreDeploy                          = $collection.deploymentSettings.PreDeploy
                                    RebootOutsideServiceWindow         = $collection.deploymentSettings.RebootOutsideServiceWindow
                                    ReplaceToastNotificationWithDialog = $collection.deploymentSettings.ReplaceToastNotificationWithDialog
                                    SendWakeupPacket                   = $collection.deploymentSettings.SendWakeupPacket
                                    TimeBaseOn                         = $collection.deploymentSettings.TimeBaseOn
                                    UserNotification                   = $collection.deploymentSettings.userNotification
                                    AvailableDateTime                  = ""
                                    DeadlineDateTime                   = ""
                                    ErrorAction                        = "Stop"
                                }
                                # Setting Date Times for available
                                if ($collection.deploymentSettings.availStart) {
                                    Write-Verbose -Message "availStart: $($collection.deploymentSettings.availStart)"
                                    $availtime = (Get-Date -Hour $collection.deploymentSettings.availHour -Minute $collection.deploymentSettings.availMinute).AddDays($collection.DeploymentSettings.availstart)
                                    $DeploymentArguments.set_item("AvailableDateTime" , $availtime)
                                }
                                else {
                                    Write-Verbose -Message "No availStart setting as current date and time"
                                    $DeploymentArguments.set_item("AvailableDateTime" , (Get-Date))
                                }
                                # Setting Date Times for deadline
                                if ($collection.deploymentSettings.deadlineStart) {
                                    Write-Verbose -Message "deadlineStart: $($collection.deploymentSettings.deadlineStart)"
                                    $deadlinetime = (Get-Date -Hour $collection.deploymentSettings.deadlineHour -Minute $collection.deploymentSettings.deadlineMinute).AddDays($collection.DeploymentSettings.deadlineStart)
                                    $DeploymentArguments.set_item("DeadlineDateTime" , $deadlinetime)
                                }
                                else {
                                    Write-Verbose -Message "No deadlineStart"
                                }
                                # Removing null or empty values from the hashtable
                                $list = New-Object System.Collections.ArrayList
                                foreach ($DepA in $DeploymentArguments.Keys) {
                                    if ([string]::IsNullOrWhiteSpace($DeploymentArguments.$DepA)) {
                                        $null = $list.Add($DepA)
                                    }
                                }
                                foreach ($item in $list) {
                                    $DeploymentArguments.Remove($item)
                                }
                                try {
                                    Write-Verbose -Message "Creating deployment of Application: $($PackageDefinition.packagingTargets.Name) for collection: $($collection.name)"
                                    New-CMApplicationDeployment @DeploymentArguments
                                }
                                catch {
                                    Write-Error $Error[0]
                                    Write-Warning -Message "Error: $($_.Exception.Message)"
                                }
                            }
                            else {
                                Write-Verbose -Message "$($collection.Name) does not exist or is not a MEMCM-Collection type."
                            }
                        }
                        else {
                            Write-Verbose -Message "$($collection.Name) has no deploymentSettings in JSON"
                        }
                    }#foreach $collections
                }
            }
            Pop-Location
            $ConfigMgrDrive | Remove-PSDrive
        }#foreach $ConfigMgrObject
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Deploy-MEMCMPackage
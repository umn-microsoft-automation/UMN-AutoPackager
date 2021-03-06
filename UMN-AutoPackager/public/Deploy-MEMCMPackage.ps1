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
        foreach ($ConfigMgrObject in ($GlobalConfig.ConfigMgr)) {
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
                Write-Verbose -Message "Processing the package definition for $($pkgObject.publisher) $($pkgObject.productname)"
                $Keys = $PkgObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                # Building out the Application Name based on the pattern if used otherwise using the specific name in the field
                $AppName = $PkgObject.packagingTargets.Name
                if ($AppName -match '}-') {
                    $BuildName = $AppName -split '-' -replace '[{}]', ''
                    foreach ($item in $BuildName) {
                        if ($Keys -contains $item) {
                            $n = $PkgObject.$item
                            $NewAppName += "$n "
                        }
                    }
                    $NewAppName = $NewAppName -replace (' ', "-")
                    $NewAppName = $NewAppName -replace ".$"
                }
                else {
                    $NewAppName = $AppName
                }
                # Checking if a baseapp value exists for the naming convention
                $baseAppName = $ConfigMgrObject.baseAppName
                if (-not [string]::IsNullOrEmpty($baseAppName)) {
                    $NewAppName = $NewAppName.Insert(0, "$baseAppName-")
                }
                Write-Verbose -Message "Application name is $NewAppName"
                # Check if the application exists if it does continue with building deployments
                if (Get-CMApplication -Name $NewAppName) {
                    foreach ($collection in $PkgObject.CollectionTargets) {
                        Write-Verbose -Message "Checking for deployment settings on Collection Target: $($collection.name)"
                        if ($collection.deploymentSetting) {
                            Write-Verbose -Message "Checking it is a MEMCM-Collection and the $($collection.name) exist"
                            if (($collection.type -eq "MEMCM-Collection") -and (Get-CMCollection -Name $collection.Name)) {
                                Write-Verbose -Message "Checking if the collection has any deployments"
                                if (Get-CMApplicationDeployment -CollectionName $collection.name) {
                                    Write-Verbose -Message "$($collection.name) contains deployments"
                                    $deployments = Get-CMApplicationDeployment -CollectionName $collection.name
                                    # If deployment(s) exist for each check if the deployment name contains the publisher and product name
                                    foreach ($deploy in $deployments) {
                                        if ($deploy.ApplicationName -match $PkgObject.publisher -and $deploy.ApplicationName -match $pkgObject.productName) {
                                            Write-Verbose -Message "$($deploy.ApplicationName) matches the publisher and product name of an existing deployment, removing deployment"
                                            try {
                                                Remove-CMApplicationDeployment -Name $deploy.ApplicationName -CollectionName $collection.name -Force
                                            }
                                            catch {
                                                Write-Error $Error[0]
                                                Write-Warning -Message "Error: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                }
                                Write-Verbose -Message "Building deployment..."
                                $DeploymentArguments = @{
                                    Name                               = $NewAppName
                                    CollectionName                     = $collection.Name
                                    AllowRepairApp                     = $collection.deploymentSetting.allowRepairApp
                                    DeployAction                       = $collection.deploymentSetting.DeployAction
                                    DeployPurpose                      = $collection.deploymentSetting.DeployPurpose
                                    OverrideServiceWindow              = $collection.deploymentSetting.OverrideServiceWindow
                                    PreDeploy                          = $collection.deploymentSetting.PreDeploy
                                    RebootOutsideServiceWindow         = $collection.deploymentSetting.RebootOutsideServiceWindow
                                    ReplaceToastNotificationWithDialog = $collection.deploymentSetting.ReplaceToastNotificationWithDialog
                                    SendWakeupPacket                   = $collection.deploymentSetting.SendWakeupPacket
                                    TimeBaseOn                         = $collection.deploymentSetting.TimeBaseOn
                                    UserNotification                   = $collection.deploymentSetting.userNotification
                                    AvailableDateTime                  = ""
                                    DeadlineDateTime                   = ""
                                }
                                # Setting Date Times for available
                                if ($collection.deploymentSetting.availStart) {
                                    Write-Verbose -Message "availStart: $($collection.deploymentSetting.availStart)"
                                    $availtime = (Get-Date -Hour $collection.deploymentSetting.availHour -Minute $collection.deploymentSetting.availMinute).AddDays($collection.DeploymentSetting.availstart)
                                    $DeploymentArguments.set_item("AvailableDateTime" , $availtime)
                                }
                                else {
                                    Write-Verbose -Message "No availStart setting as current date and time"
                                    $DeploymentArguments.set_item("AvailableDateTime" , (Get-Date))
                                }
                                # Setting Date Times for deadline
                                if ($collection.deploymentSetting.deadlineStart) {
                                    Write-Verbose -Message "deadlineStart: $($collection.deploymentSetting.deadlineStart)"
                                    $deadlinetime = (Get-Date -Hour $collection.deploymentSetting.deadlineHour -Minute $collection.deploymentSetting.deadlineMinute).AddDays($collection.DeploymentSetting.deadlineStart)
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
                                    Write-Verbose -Message "Creating deployment of Application: $NewAppName for collection: $($collection.name)"
                                    New-CMApplicationDeployment @DeploymentArguments
                                }
                                catch {
                                    Write-Error $Error[0]
                                    Write-Warning -Message "Error: $($_.Exception.Message)"
                                }
                                # Creates the time as UTC regardless of TimeBaseOn switch being set to LocalTime setting the date time
                                if ($collection.deploymentSetting.timeBaseOn -eq "LocalTime" -and $collection.deploymentSetting.deadlineStart) {
                                    Write-Verbose -Message "Time based on LocalTime and deadline start has a value"
                                    Set-CMApplicationDeployment -ApplicationName $DeploymentArguments.Name -CollectionName $deploymentArguments.CollectionName -DeadlineDatetime $DeploymentArguments.DeadlineDateTime -AvailableDateTime $DeploymentArguments.AvailableDateTime
                                }
                                elseif ($collection.deploymentSetting.timeBaseOn -eq "LocalTime" -and (-not $collection.deploymentSetting.deadlineStart)) {
                                    Write-Verbose -Message "Time based on LocalTime and no deadline start value"
                                    Set-CMApplicationDeployment -ApplicationName $DeploymentArguments.Name -CollectionName $deploymentArguments.CollectionName -AvailableDateTime $DeploymentArguments.AvailableDateTime
                                }
                            }
                            else {
                                Write-Verbose -Message "$($collection.Name) does not exist or is not a MEMCM-Collection type."
                            }
                        }
                    }#foreach $CollectionTargets
                }
            }#foreach $PackageDefinition
            Pop-Location
            $ConfigMgrDrive | Remove-PSDrive
        }#foreach $ConfigMgrObject
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}#Deploy-MEMCMPackage
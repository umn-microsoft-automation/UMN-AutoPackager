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
# Check for existing deployment (get-CMApplicationDeployment -Name -CollectionName). Delete them (Remove-CMApplicationDeployment -Name -CollectionName)
# set up the deployment for collection (New-CMApplicationDeployment)
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
                # Check if the application exists if it does continue with building deployments. Othewise move on.
                if (Get-CMApplication -Name $NewAppName) {
                    foreach ($collection in $PkgObject.CollectionTargets) {
                        if (($collection.type -eq "MEMCM-Collection") -and (Get-CMCollection -Name $collection.Name)) {
                            # Collection does exist, building the deployments
                            Write-Verbose -Message "Building deployments for ConfigMgr"
                            $DeploymentArguments = @{
                                Name = $NewAppName
                                CollectionName = $collection.Name
                                AllowRepairApp = $collection.deploymentSetting.allowRepairApp
                            }
                            # build the hashtable to splat with
                            # get-date is going to be needed
                            # Update the json with the values needed
                            # delete the old deployments if they exist and if the version deployed is older then the current one else do nothing
                            # Need to build logic for creating -DeadlineDateTime using Get-Date or -AvailableDateTime
                        }
                        else {
                            Write-Verbose -Message "$($collection.Name) does not exist or is not a MEMCM-Collection type."
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
Deploy-MEMCMPackage -GlobalConfig (Get-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\GlobalConfig.json) -PackageDefinition (Get-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\PackageConfig.json) -Credential oitthoen008 -verbose
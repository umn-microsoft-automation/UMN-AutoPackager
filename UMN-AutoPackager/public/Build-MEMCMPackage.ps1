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

# Creates an MEMCM package based on the standard inputs from the package definition file
# Build-MEMCMPackage -GlobalConfig globalconfigdefinitions -PackageDefinition arrayofpackagedefinitions
# Foreach Site creates an application based on the values in the package defintion array.
function Build-MEMCMPackage {
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
            # Credit this for using credentials https://duffney.io/addcredentialstopowershellfunctions/
            $SiteCode = $ConfigMgrObject.SiteCode
            try {
                if (-not (Test-Path -Path $SiteCode)) {
                    $ConfigMgrDrive = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ConfigMgrObject.Site -Credential $Credential
                }
            }
            catch {
                Write-Error $Error[0]
            }
            Push-Location
            Set-Location -Path "$SiteCode`:\"
            foreach ($PkgObject in $PackageDefinition) {
                if ($PkgObject.PackagingTargets.Type -eq "MEMCM-Application") {
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
                    # Building the localized application name
                    $LocalAppName = $PkgObject.packagingTargets.localizedApplicationName
                    if ($LocalAppName -match '} ') {
                        $LocalBuildName = $LocalAppName -split ' ' -replace '[{}]', ''
                        foreach ($localitem in $LocalBuildName) {
                            if ($Keys -contains $localitem) {
                                $n = $PkgObject.$localitem
                                $NewLocalAppName += "$n "
                            }
                        }
                    }
                    else {
                        Write-verbose -Message "No pattern using value of packagingTargets.localizedApplicationName"
                        $NewLocalAppName = $LocalAppName
                    }
                    Write-Verbose -Message "Local Application name is $NewLocalAppName"
                    # Building hashtable with all the values to use in the New-CMApplication function
                    $ApplicationArguments = @{
                        Name                 = $NewAppName
                        Description          = $PkgObject.Description
                        Publisher            = $PkgObject.Publisher
                        SoftwareVersion      = $PkgObject.currentVersion
                        ReleaseDate          = $PkgObject.packagingTargets.datePublished
                        AddOwner             = $PkgObject.owner
                        AutoInstall          = $PkgObject.packagingTargets.allowTSUsage
                        IconLocationFile     = $PkgObject.packagingTargets.IconLocationFile
                        # Need to fix keywords
                        Keywords             = $PkgObject.packagingTargets.Keywords
                        Linktext             = $PkgObject.packagingTargets.userDocumentationText
                        LocalizedDescription = $PkgObject.packagingTargets.localizedDescription
                        LocalizedName        = $NewLocalAppName
                        PrivacyURL           = $PkgObject.packagingTargets.privacyLink
                        SupportContact       = $PkgObject.supportContact
                        UserDocumentation    = $PkgObject.packagingTargets.userDocumentationLink
                    }
                    # Removing null or empty values from the hashtable
                    $list = New-Object System.Collections.ArrayList
                    foreach ($appA in $ApplicationArguments.Keys) {
                        if ([string]::IsNullOrWhiteSpace($ApplicationArguments.$appA)) {
                            $null = $list.Add($appA)
                        }
                    }
                    foreach ($item in $list) {
                        $ApplicationArguments.Remove($item)
                    }
                    # Creating a new ConfigMgr application
                    New-CMApplication @ApplicationArguments
                    # Building hashtable with all values to us in the DeploymentType creation functions
                    foreach ($depType in $PkgObject.packagingTargets.deploymentTypes) {
                        $DepName = $deptype.Name
                        $DeploymentTypeArguments = @{
                            AddDetectionClause        = ""
                            AddLanguage               = $depType.Language
                            ApplicationName           = $NewAppName
                            CacheContent              = $deptype.cacheContent
                            Comment                   = $depType.adminComments
                            ContentFallback           = $deptype.contentFallback
                            ContentLocation           = $depType.ContentLocation
                            DeploymentTypeName        = $NewAppName + " $DepName"
                            EnableBranchCache         = $deptype.branchCache
                            EstimatedRuntimeMins      = $deptype.estimatedRuntime
                            Force32Bit                = $deptype.runAs32Bit
                            InstallationBehaviorType  = $deptype.installBehavior
                            InstallCommand            = $deptype.installCMD
                            LogonRequirementType      = $depType.logonRequired
                            MaximumRuntimeMins        = $depType.maxRuntime
                            RebootBehavior            = $depType.rebootBehavior
                            ScriptLanguage            = $depType.scriptLanguage
                            ScriptText                = $deptype.ScriptText
                            SlowNetworkDeploymentMode = $depType.onSlowNetwork
                            UninstallProgram          = $depType.uninstallCMD
                            UserInteractionmode       = $deptype.userInteraction
                        }
                        # Removing null or empty values from the hashtable
                        $DepTypelist = New-Object System.Collections.ArrayList
                        foreach ($DTArgue in $DeploymentTypeArguments.Keys) {
                            if ([string]::IsNullOrWhiteSpace($DeploymentTypeArguments.$DTArgue)) {
                                $null = $DepTypelist.Add($DTArgue)
                            }
                        }
                        foreach ($item in $DepTypelist) {
                            $DeploymentTypeArguments.Remove($item)
                        }
                        # Building hashtable with all the values to use with New or Set-CMDetectionClause functions
                        foreach ($detectionMethod in $depType.detectionMethods) {
                            $DetectionClauseArguments = @{
                                DirectoryName      = $detectionMethod.DirectoryName
                                Existence          = $detectionMethod.Existence
                                ExpectedValue      = $detectionMethod.ExpectedValue
                                ExpressionOperator = $detectionMethod.ExpressionOperator
                                FileName           = $detectionMethod.FileName
                                Hive               = $detectionMethod.Hive
                                Is64Bit            = $detectionMethod.Is64Bit
                                KeyName            = $detectionMethod.KeyName
                                Path               = $detectionMethod.Path
                                ProductCode        = $detectionMethod.ProductCode
                                PropertyType       = $detectionMethod.PropertyType
                                Value              = $detectionMethod.Value
                                ValueName          = $detectionMethod.ValueName
                            }
                            # Removing null or empty values from the hashtable
                            $DetClauselist = New-Object System.Collections.ArrayList
                            foreach ($DetClause in $DetectionClauseArguments.Keys) {
                                if ([string]::IsNullOrWhiteSpace($DetectionClauseArguments.$DetClause)) {
                                    $null = $DetClauselist.Add($DetClause)
                                }
                            }
                            foreach ($item in $DetClauselist) {
                                $DetectionClauseArguments.Remove($item)
                            }
                            # Check the application deployment types, run the proper command to create the DetectionClause variable, add to the hashtable, and create the deployment type
                            if ($null -eq $(Get-CMDeploymentType -DeploymentTypeName $DeploymentTypeArguments.DeploymentTypeName -ApplicationName $DeploymentTypeArguments.ApplicationName)) {
                                Write-Verbose -Message "Deployment Type not found in $($DeploymentTypeArguments.ApplicationName)"
                                if ($detectionMethod.type -eq "RegistryKey") {
                                    $clause = New-CMDetectionClauseRegistryKey @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "RegistryKeyValue" ) {
                                    $clause = New-CMDetectionClauseRegistryKeyValue @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "Directory") {
                                    $clause = New-CMDetectionClauseDirectory @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "File") {
                                    $clause = New-CMDetectionClauseFile @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "WindowsInstaller") {
                                    $clause = New-CMDetectionClauseWindowsInstaller @DetectionClauseArguments
                                }
                                else {
                                    Write-Verbose -Message "Not a known type of detection clause"
                                }
                                $DeploymentTypeArguments.set_item("AddDetectionClause", $clause)
                                # Creating a new deployment type to the application
                                if ($depType.installerType -eq "Script") {
                                    Write-Verbose -Message "Adding Script Deployment Type."
                                    Add-CMScriptDeploymentType @DeploymentTypeArguments
                                }
                                elseif ($depType.installerType -eq "Msi") {
                                    Write-Verbose -Message "Adding MSI Deployment Type."
                                    Add-CMMsiDeploymentType @DeploymentTypeArguments
                                }
                            }
                            else{
                                Write-Verbose -Message "Deployment Type found in $($DeploymentTypeArguments.ApplicationName)"
                                if ($detectionMethod.type -eq "RegistryKey") {
                                    $clause = New-CMDetectionClauseRegistryKey @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "RegistryKeyValue" ) {
                                    $clause = New-CMDetectionClauseRegistryKeyValue @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "Directory") {
                                    $clause = New-CMDetectionClauseDirectory @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "File") {
                                    $clause = New-CMDetectionClauseFile @DetectionClauseArguments
                                }
                                elseif ($detectionMethod.type -eq "WindowsInstaller") {
                                    $clause = New-CMDetectionClauseWindowsInstaller @DetectionClauseArguments
                                }
                                else {
                                    Write-Verbose -Message "Not a known type of detection clause"
                                }
                                $DeploymentTypeArguments.set_item("AddDetectionClause", $clause)
                                # Add additional detection clauses to an existing deployment type
                                if ($depType.installerType -eq "Script") {
                                    Write-Verbose -Message "Setting Script Deployment Type - Deployment Type Name Exists"
                                    Set-CMScriptDeploymentType -ApplicationName $DeploymentTypeArguments.ApplicationName -DeploymentTypeName $DeploymentTypeArguments.DeploymentTypeName -AddDetectionClause $clause
                                }
                                elseif ($depType.installerType -eq "Msi") {
                                    Write-Verbose -Message "Adding MSI Deployment Type - Deployment Type Name Exists"
                                    Set-CMMsiDeploymentType @DeploymentTypeArguments
                                }
                            }
                        }
                    }
                    # Application content is distributed
                    if ($PkgObject.DistributionPointName) {
                        Write-Verbose -Message "Distributing content to a set of DP names"
                        Start-CMContentDistribution -ApplicationName $NewAppName -DistributionPointName $PkgObject.DistributionPointName
                    }
                    if ($PkgObject.DistributionPointGroupName) {
                        Write-Verbose -Message "Distributing content to a set of DP groups"
                        Start-CMContentDistribution -ApplicationName $NewAppName -DistributionPointGroupName $pkgObject.DistributionPointGroupName
                    }
                }
            }
            Pop-Location
            $ConfigMgrDrive | Remove-PSDrive
        }
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}
Build-MEMCMPackage -GlobalConfig (Get-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\GlobalConfig.json) -PackageDefinition (Get-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\PackageConfig.json) -Credential oitthoen008 -verbose
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
                if(-not (Test-Path -Path $SiteCode)) {
                   $ConfigMgrDrive = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ConfigMgrObject.Site -Credential $Credential
                }
            } catch {
                Write-Error $Error[0]
            }
            Push-Location
            Set-Location -Path "$SiteCode`:\"
            foreach ($PkgObject in $PackageDefinition) {
                if ($PkgObject.PackagingTargets.Type -eq "MEMCM-Application") {
                    # Build out the varibles needed for each one below using the packageconfig or globalconfig. Add any needed values to the config.
                    $Keys = $PkgObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                    # Building out the Application Name based on the pattern if used otherwise using the specific name in the field
                    $AppName = $PkgObject.packagingTargets.Name
                    if ($AppName -match '}-') {
                        Write-Verbose -Message "$AppName is a pattern."
                        $BuildName = $AppName -split '-' -replace '[{}]',''
                        foreach ($item in $BuildName) {
                            # Write-Verbose -Message "$item is being processed"
                            if ($Keys -contains $item) {
                                # Write-Verbose -Message "Found match for $item"
                                $n = $PkgObject.$item
                                $NewAppName += "$n "
                                # Write-Verbose -Message "Setting name to $NewAppName"
                            }
                        }
                        $NewAppName = $NewAppName -replace(' ',"-")
                        $NewAppName = $NewAppName -replace ".$"
                    }
                    else {
                        Write-verbose -Message "No pattern using value of packagingTargets.Name"
                        $NewAppName = $AppName
                    }
                    $baseAppName = $ConfigMgrObject.baseAppName
                    if (-not [string]::IsNullOrEmpty($baseAppName)) {
                        Write-Verbose -Message "Baseapp name found using: $baseAppName"
                        $NewAppName = $NewAppName.Insert(0,"$baseAppName-")
                    }
                    Write-Verbose -Message "Application name is $NewAppName"
                    $LocalAppName = $PkgObject.packagingTargets.localizedApplicationName
                    if ($LocalAppName -match '} ') {
                        Write-Verbose -Message "$LocalAppName is a pattern."
                        $LocalBuildName = $LocalAppName -split ' ' -replace '[{}]',''
                        foreach ($localitem in $LocalBuildName) {
                            # Write-Verbose -Message "$localitem is being processed"
                            if ($Keys -contains $localitem) {
                                # Write-Verbose -Message "Found match for $localitem"
                                $n = $PkgObject.$localitem
                                $NewLocalAppName += "$n "
                                # Write-Verbose -Message "Setting name to $NewLocalAppName"
                            }
                        }
                    }
                    else {
                        Write-verbose -Message "No pattern using value of packagingTargets.localizedApplicationName"
                        $NewLocalAppName = $LocalAppName
                    }
                    Write-Verbose -Message "Local Application name is $NewLocalAppName"
                    $ApplicationArguments = @{
                        Name = $NewAppName
                        Description = $PkgObject.Description
                        Publisher = $PkgObject.Publisher
                        SoftwareVersion = $PkgObject.currentVersion
                        ReleaseDate = $PkgObject.packagingTargets.datePublished
                    # Add this to the PackageConfig
                        AddOwner = $PkgObject.owner
                        AutoInstall = $PkgObject.packagingTargets.allowTSUsage
                        IconLocationFile = $PkgObject.packagingTargets.IconLocationFile
                    # Need to fix keywords
                        Keywords = $PkgObject.packagingTargets.Keywords
                        Linktext = $PkgObject.packagingTargets.userDocumentationText
                        LocalizedDescription = $PkgObject.packagingTargets.localizedDescription
                        LocalizedName = $NewLocalAppName
                        PrivacyURL = $PkgObject.packagingTargets.privacyLink
                    # Add this to the pkgconfig
                        SupportContact = $PkgObject.supportContact
                        UserDocumentation = $PkgObject.packagingTargets.userDocumentationLink
                    }
                    # Removing null or empty values from the hashtable
                    $list = New-Object System.Collections.ArrayList
                    foreach ($appA in $ApplicationArguments.Keys) {
                        # Write-Verbose -Message "Processing $appA"
                        if (-not $ApplicationArguments.$appA){
                            Write-Verbose -Message "$appA value is empty/null marking for removal."
                            $null = $list.Add($appA)
                        }
                    }
                    foreach ($item in $list) {
                        $ApplicationArguments.Remove($item)
                    }
                    # Building ConfigMgr application
        # Remove Whatifs once ready to merge with master
                    New-CMApplication -whatif @ApplicationArguments
        # InstallationBehaviorType must be one of 3 values (Not sure if we can enforce this maybe a try catch). InstallForSystem, InstallForSystemIfResourceIsDeviceOtherwiseInstallForUser,InstallForUser
        # UserInteractionMode must be one of 4 values. Normal, Minimized, Maximized, Hidden
        # AddLanguage specifices an array of languages. Not sure we want to deal with that right now. Accepts LCID language codes. https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c
        # LogonRequirementType must be one of 3 values. OnlyWhenNoUserLoggedOn, OnlyWhenUserLoggedOn, WhetherOrNotUserLoggedOn
        # SlowNetworkDeploymentMode must be one of 2 values. DoNothing, Download
        # RebootBehavior must be one of 4 BaseOnExitCode, NoAction, ProgramReboot, ForceReboot
        # ScriptLanguage is required for a Script Deployment Type. Accepts Powershell, VBScript,Javascript
        # ForceScriptDetection32Bit Needed?
        # RepairCommand Needed?
        # ScriptFile detect for deployment. Future improvement.
        # UnisntallContentLocation future improvement. Can be different then the contentlocation. Nice for solidworks and other large install media that doesn't need that media.
                    foreach ($depType in $PkgObject.packagingTargets.deploymentTypes) {
                        $DepName = $deptype.Name
                        $DeploymentTypeArguments = @{
                            # AddDetectionClause = Figure this out. See notes below. Also need to deal with group detection clauses.
                            # AddRequirement = Figure this out. Maybe this is a future improvement. Accepts array of requirement objects.
                            AddLanguage = $depType.Language
                            ApplicationName = $NewAppName
                            CacheClient = $deptype.cacheContent
                            Comment = $depType.adminComments
                            ContentFallback = $deptype.contentFallback
                            ContentLocation = $depType.ContentLocation
                            DeploymentTypeName = $NewAppName + " $DepName"
                            EnableBranchCache = $deptype.branchCache
                            EsitmatedRuntimeMins = $deptype.esitmatedRuntime
                            Force32Bit = $deptype.runAs32Bit
                            InstallationBehaviorType = $deptype.installBehavior
                            InstallCommand = $deptype.installCMD
                            LogonRequirementType = $depType.logonRequired
                            MaximumRuntimeMins = $depType.maxRuntime
                            # ProductCode = Figure this out. It states it will over write any other detection.
                            RebootBehavior = $depType.rebootBehavior
                            ScriptLanguage = $depType.scriptLanguage
                            SlowNetworkDeploymentMode = $depType.onSlowNetwork
                            UninstallProgram = $depType.uninstallCMD
                            UserInteractionmode = $deptype.userInteraction
                        }
                        Write-Output $DeploymentTypeArguments
                        # Removing null or empty values from the hashtable
                        $DepTypelist = New-Object System.Collections.ArrayList
                        foreach ($DTArgue in $DeploymentTypeArguments.Keys) {
                            # Write-Verbose -Message "Processing $DTArgue"
                            if (-not $DeploymentTypeArguments.$DTArgue){
                                Write-Verbose -Message "$DTArgue value is empty/null marking for removal."
                                $null = $DepTypelist.Add($DTArgue)
                            }
                        }
                        foreach ($item in $DepTypelist) {
                            $DeploymentTypeArguments.Remove($item)
                        }
                        Write-Output $DeploymentTypeArguments
                        # This command is deprecated. Need to use one of the new ones. Add-CMDeploymentType @DeploymentTypeArguments -whatif
                        # Add-CMMsiDeploymentType, Add-CMScriptDeploymentType There are others but these seem the most common. https://docs.microsoft.com/en-us/powershell/module/configurationmanager/add-cmdeploymenttype?view=sccm-ps
                        foreach ($detectionMethod in $PkgObject.packagingTargets.deploymentTypes.detectionMethods){
                         # Check for ProductCode I suspect this needs to be dealt with seperate. Maybe not since there is a function called windowsinstaller
                         # Build an array with all the detection methods and use that array in the call for -AddDetectionClause
                        }
                        if ($depType.installerType -eq "Script") {
                            Add-CMScriptDeploymentType -WhatIf @DeploymentTypeArguments
                        }
                        elseif ($depType.installerType -eq "Msi") {
                            Add-CMMsiDeploymentType -Whatif @DeploymentTypeArguments
                        }
                    }
        # Need to build out the Detection clause using the New-CMDetectionClause functions. https://docs.microsoft.com/en-us/powershell/module/configurationmanager/add-cmscriptdeploymenttype?view=sccm-ps
        # The detection clause will need to be dumped into a variable for use in the Add-CM deployment type function call.
                    $ContentDistributionArguments = @{
                        ApplicationName = $ApplicationName
                        DistributionPointGroupName = $DPGroupName
                    }
                    # Start-CMContentDistribution @ContentDistributionArguments -whatif
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
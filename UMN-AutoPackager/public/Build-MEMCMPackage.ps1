function Build-MEMCMPackage {
    <#
    .SYNOPSIS
        Create an application in Configuration Manager based on the properties of the UMNAutopackager json files.
    .DESCRIPTION
        This command creates an application for each site based on the values of the GlobalConfig and PackageConfig json values. It leverages various powershell commands provided with ConfigMgr.
    .PARAMETER GlobalConfig
        Input the global configuration json file using the Get-GlobalConfig command
    .PARAMETER PackageConfig
        Input the package definition json file using the Get-GlobalConfig command
    .PARAMETER Credential
        Input the credentials object or the user name which will prompt for credentials. If not called will attempt to use the credentials of the account that is running the script.
    .PARAMETER SiteTarget
        This is the PackagingTargets section of either the GlobalConfig or PackageConfig, whichever has the site info.
    .EXAMPLE
        Build-MEMCMPackage -GlobalConfig (Get-UMNGlobalConfig -Path C:\UMNAutopackager\GlobalConfig.json) -PackageConfig (Get-UMNGlobalConfig -Path C:\UMNAutopackager\PackageConfig.json) -Credential MyUserName
        Runs the function prompting for the credentials of MyUserName.
    .EXAMPLE
        Build-MEMCMPackage -GlobalConfig $globaljson -PackageConfig $pkgjson -Credential $creds
        Runs the function using the credentials stored in the $creds variable.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Input the values of the GlobalConfig.json.")]
        [psobject]$GlobalConfig,

        [Parameter(Mandatory = $true,

            HelpMessage = "Input the values of the various PackageConfig.json files.")]
        [psobject[]]$PackageConfig,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        $SiteTarget
    )
    begin {
        Write-Information -MessageData "Command = $($myinvocation.mycommand)" -Tags Meta
        Write-Information -MessageData "PSVersion = $($PSVersionTable.PSVersion)" -Tags Meta
        Write-Information -MessageData "User = $env:userdomain\$env:username" -tags Meta
        Write-Information -MessageData "Computer = $env:computername" -tags Meta
        Write-Information -MessageData "PSHost = $($host.name)" -Tags Meta
        Write-Information -MessageData "Date = $(Get-Date)" -tags Meta
        Write-Verbose -Message "Starting $($myinvocation.mycommand)"
        Import-Module -Name "$($env:SystemDrive)\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\ConfigurationManager.psd1"
    }
    process {
        Write-Verbose -Message "Processing $($SiteTarget.site) Site..."
        $SiteCode = $SiteTarget.SiteCode
        try {
            if (-not (Test-Path -Path $SiteCode)) {
                $ConfigMgrDrive = New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteTarget.Site -Credential $Credential
            }
        }
        catch {
            Write-Error $_
            Write-Warning -Message "Error: $($_.Exception.Message)"
        }
        Push-Location
        Set-Location -Path "$SiteCode`:\"
        foreach ($PkgObject in $PackageConfig) {
            # Replace Pre/Post App Name Variables
            #$PackgingTargetVariables = [hashtable]@{
            #    "{preAppName}"  = $PkgObject.PreAppName
            #    "{postAppName}" = $PkgObject.PostAppName
            #}

            #$PkgObject.ReplaceVariables($PackgingTargetVariables)
                
            Write-Verbose -Message "Processing the package definition for $($pkgObject.publisher) $($pkgObject.productname)"
            if ($PkgObject.PackagingTargets.Type -eq "MEMCM-Application") {
                # Building hashtable with all the values to use in the New-CMApplication function
                $ApplicationArguments = @{
                    Name                 = $PkgObject.packagingTargets.Name
                    Description          = $PkgObject.Description
                    Publisher            = $PkgObject.Publisher
                    SoftwareVersion      = $PkgObject.currentVersion
                    ReleaseDate          = $PkgObject.packagingTargets.datePublished
                    AddOwner             = $PkgObject.packagingTargets.owner
                    AutoInstall          = $PkgObject.packagingTargets.allowTSUsage
                    IconLocationFile     = $PkgObject.packagingTargets.iconFilename
                    Keywords             = $PkgObject.packagingTargets.Keywords
                    Linktext             = $PkgObject.packagingTargets.userDocumentationText
                    LocalizedDescription = $PkgObject.packagingTargets.localizedDescription
                    LocalizedName        = $PkgObject.packagingTargets.localizedApplicationName
                    PrivacyURL           = $PkgObject.packagingTargets.privacyLink
                    SupportContact       = $PkgObject.packagingTargets.supportContact
                    UserDocumentation    = $PkgObject.packagingTargets.userDocumentationLink
                    ErrorAction          = "Stop"
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
                try {
                    Write-Verbose -Message "Creating a new ConfigMgr application: $NewAppName"
                    New-CMApplication @ApplicationArguments
                }
                catch {
                    Write-Error $_
                    Write-Warning -Message "Error: $($_.Exception.Message)"
                }
                # Building hashtable with all values to us in the DeploymentType creation functions
                foreach ($depType in $PkgObject.packagingTargets.deploymentTypes) {
                    # $DepName = $deptype.Name
                    $DeploymentTypeArguments = @{
                        AddDetectionClause        = ""
                        AddLanguage               = $depType.Language
                        ApplicationName           = $PkgObject.packagingTargets.Name
                        CacheContent              = $deptype.cacheContent
                        Comment                   = $depType.adminComments
                        ContentFallback           = $deptype.contentFallback
                        ContentLocation           = $depType.ContentLocation
                        DeploymentTypeName        = $PkgObject.packagingTargets.Name + " $($depType.Name)"
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
                        UninstallCommand          = $depType.uninstallCMD
                        UserInteractionmode       = $deptype.userInteraction
                        ErrorAction               = "Stop"
                    }
                    Write-Verbose -Message "Processing the DeploymentType: $($DeploymentTypeArguments.DeploymentTypeName)"
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
                        Write-Verbose -Message "Processing the detection method: $($detectionMethod.type)"
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
                            ErrorAction        = "Stop"
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
                                try {
                                    Add-CMScriptDeploymentType @DeploymentTypeArguments
                                }
                                catch {
                                    Write-Error $_
                                    Write-Warning -Message "Error: $($_.Exception.Message)"
                                }
                            }
                            elseif ($depType.installerType -eq "Msi") {
                                Write-Verbose -Message "Adding MSI Deployment Type."
                                try {
                                    Add-CMMsiDeploymentType @DeploymentTypeArguments
                                }
                                catch {
                                    Write-Error $_
                                    Write-Warning -Message "Error: $($_.Exception.Message)"
                                }
                            }
                        }
                        else {
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
                                try {
                                    Set-CMScriptDeploymentType @DeploymentTypeArguments
                                }
                                catch {
                                    Write-Error $_
                                    Write-Warning -Message "Error: $($_.Exception.Message)"
                                }
                            }
                            elseif ($depType.installerType -eq "Msi") {
                                Write-Verbose -Message "Adding MSI Deployment Type - Deployment Type Name Exists"
                                try {
                                    Set-CMMsiDeploymentType @DeploymentTypeArguments
                                }
                                catch {
                                    Write-Error $_
                                    Write-Warning -Message "Error: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }#foreach $depType
                # Distributing the Application content
                if ($PkgObject.packagingTargets.deploymentPoints.dpNames -and $pkgObject.overridePackagingTargets -eq $true) {
                    Write-Verbose -Message "Distributing content to a set of DP names from PackageConfig"
                    try {
                        Start-CMContentDistribution -ApplicationName $PkgObject.packagingTargets.Name -DistributionPointName $PkgObject.packagingTargets.deploymentPoints.dpNames -ErrorAction Stop
                    }
                    catch {
                        Write-Error $_
                        Write-Warning -Message "Error: $($_.Exception.Message)"
                    }
                }
                elseif ($SiteTarget.deploymentPoints.dpNames) {
                    Write-Verbose -Message "Distributing content to a set of DP names from GlobalConfig"
                    try {
                        Start-CMContentDistribution -ApplicationName $PkgObject.packagingTargets.Name -DistributionPointName $SiteTarget.deploymentPoints.dpNames -ErrorAction Stop
                    }
                    catch {
                        Write-Error $_
                        Write-Warning -Message "Error: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Verbose -Message "No DP Names listed"
                }
                if ($PkgObject.packagingTargets.deploymentPoints.dpNames -and $pkgObject.overridePackagingTargets -eq $true) {
                    Write-Verbose -Message "Distributing content to a set of DP groups from PackageConfig"
                    try {
                        Start-CMContentDistribution -ApplicationName $PkgObject.packagingTargets.Name -DistributionPointGroupName $pkgObject.packagingTargets.deploymentPoints.dpGroupNames -ErrorAction Stop
                    }
                    catch {
                        Write-Error $_
                        Write-Warning -Message "Error: $($_.Exception.Message)"
                    }
                }
                elseif ($SiteTarget.deploymentPoints.dpGroupNames) {
                    Write-Verbose -Message "Distributing content to a set of DP groups from GlobalConfig"
                    try {
                        Start-CMContentDistribution -ApplicationName $PkgObject.packagingTargets.Name -DistributionPointGroupName $SiteTarget.deploymentPoints.dpGroupNames -ErrorAction Stop
                    }
                    catch {
                        Write-Error $_
                        Write-Warning -Message "Error: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Verbose -Message "No DP Group Names listed"
                }
            }
        }#foreach $PkgObject
        Pop-Location
        $ConfigMgrDrive | Remove-PSDrive
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}

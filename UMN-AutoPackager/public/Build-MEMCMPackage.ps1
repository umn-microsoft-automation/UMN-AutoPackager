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
                                Write-Verbose -Message "Setting name to $NewLocalAppName"
                            }
                        }
                    }
                    else {
                        Write-verbose -Message "No pattern using value of packagingTargets.localizedApplicationName"
                        $NewLocalAppName = $LocalAppName
                    }
                    Write-Verbose -Message "Local Application name is $NewLocalAppName"
                    # Maybe I should build the hash table regardless of null then foreach through the table and remove any null values to get around the argument is null issue
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
                        $value = $appA.value
                        # Write-Verbose -Message "Processing $appA with value $value"
                        if (-not $ApplicationArguments.$appA){
                            Write-Verbose -Message "$appA value is empty/null marking for removal."
                            $null = $list.Add($appA)
                        }
                    }
                    foreach ($item in $list) {
                        $ApplicationArguments.Remove($item)
                    }
                    New-CMApplication -whatif @ApplicationArguments
                    $DeploymentTypeArguments = @{
                        ApplicationName = $ApplicationName
                        DeploymentTypeName = $ApplicationName
                        InstallationFileLocation = $ApplicationPath
                        ForceforUnknownPublisher = $true
                        MsiInstaller = $true
                        InstallationBehaviorType = "InstallForSystem"
                        InstallationProgram = $InstallationProgram
                        OnSlowNetworkMode = "DoNothing"
                    }
                    # Add-CMDeploymentType @DeploymentTypeArguments -whatif
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
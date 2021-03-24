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
        foreach ($object in ($GlobalConfig.ConfigMgr)) {
            Write-Verbose -Message "Processing $object Site..."
            # Credit this for using credentials https://duffney.io/addcredentialstopowershellfunctions/
            try {
                if(-not (Test-Path -Path $object.sitecode)) {
                   $SiteDrive = New-PSDrive -Name $object.sitecode -PSProvider CMSite -Root $object.Site -Credential $Credential
                   Write-Verbose -Message "Working on $SiteDrive"
                }
            } catch {
                Write-Error $Error[0]
            }
            $Loco = Get-Location
            Write-Verbose -Message "Pushing location $Loco"
            Push-Location
            # Need to fix the Set-location stuff doesn't seem to be working
            Set-Location $SiteDrive
            foreach ($object in $PackageDefinition) {
                Write-Verbose -Message "Processing package defintion $object"
                if ($object.PackagingTargets.Type -eq "MEMCM-Application") {
                    # Build out the varibles needed for each one below using the packageconfig or globalconfig. Add any needed values to the config.
                    $ApplicationArguments = @{
                        Name = $ApplicationName
                        Description = $ApplicationDescription
                        Publisher = $ApplicationPublisher
                        SoftwareVersion = $ApplicationSoftwareVersion
                        ReleaseDate = $ReleaseDate
                        LocalizedApplicationName = $ApplicationName
                    }
                    # New-CMApplication @ApplicationArguments -whatif
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
        }
    }
    end {
        Write-Verbose -Message "Ending $($myinvocation.mycommand)"
    }
}
Build-MEMCMPackage -GlobalConfig (Get-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\GlobalConfig.json) -PackageDefinition (Get-UMNGlobalConfig -Path C:\Users\thoen008\Desktop\PackageConfig.json) -Credential oitthoen008 -verbose
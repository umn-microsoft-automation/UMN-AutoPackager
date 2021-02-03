# Creates an MEMCM package based on the standard inputs from the package definition file
# Build-MEMCMPackage -GlobalConfig $arrayofglobalconfigdefinitions -PackageDefinition $arrayofpackagedefinitions
# Reads the globalconfig.json using get-UMNGlobalConfig for details on the various sites information. Retrieves values of package definition array that was created using Get-PackageDefition.
# Foreach Site creates an application based on the values in the package defintion array.
function Build-MEMCMPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Input of the values of the GlobalConfig.json. Typically done using Get-UMNGlobalConfig.")]
        [string]$GlobalConfig,
        [Parameter(Mandatory = $true,
            HelpMessage = "Input(s) of the values of the package defintion values. Typically done using Get-PackageDefinition.")]
        [string[]]$PackageDefinition
    )
    begin {
    }
    process {
        $ApplicationArguments = @{
            Name = $ApplicationName
            Description = $ApplicationDescription
            Publisher = $ApplicationPublisher
            SoftwareVersion = $ApplicationSoftwareVersion
            ReleaseDate = (Get-Date)
            LocalizedApplicationName = $ApplicationName
        }
        New-CMApplication @ApplicationArguments
        # Create DeploymentType
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
        Add-CMDeploymentType @DeploymentTypeArguments
        # Distribute content to DPG
        $ContentDistributionArguments = @{
            ApplicationName = $ApplicationName
            DistributionPointGroupName = $DPGroupName
        }
        Start-CMContentDistribution @ContentDistributionArguments
    }
    end {
    }
}
function Invoke-AutoPackager {
    <#
    .SYNOPSIS
        Invokes the main logic thread of the autopacckager.
    .DESCRIPTION
        Runs through all the given recipes and builds them.
    .PARAMETER GlobalConfig
        This is the loaded GlobalConfiguration JSON file.
    .PARAMETER PackageApp
        This is a flag that when set will package the application.
    .PARAMETER DeployApp
        This is a flag that when set will deploy the application.
    .PARAMETER CreateCollections
        This is a flag that when set will create the collections.
    .EXAMPLE
        Invoke-AutoPackager -GlobalConfig $GlobalConfig -PackageApp -CreateCollections -DeployApp -InformationAction Continue
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$GlobalConfig,

        [Parameter(Mandatory = $false)]
        [switch]$PackageApp = $false,

        [Parameter(Mandatory = $false)]
        [switch]$DeployApp = $false,

        [Parameter(Mandatory = $false)]
        [switch]$CreateCollections = $false
    )

    foreach ($RecipeLocation in $GlobalConfig.RecipeLocations) {
        Write-Information -MessageData "Started working on $($RecipeLocation.LocationUri.AbsolutePath)"

        if ($RecipeLocation.LocationType -eq "directory") {
            # Get all recipe directories
            $RecipeDirs = Get-ChildItem -Path $($RecipeLocation.LocationUri.AbsolutePath) -Directory

            # If directory empty, write error
            if ($RecipeDirs.Count -lt 1) {
                Write-Error -Message "No recipes were found in $($RecipeLocation.LocationUri.AbsolutePath)"
            }
            else {
                # Loop through recipes and execute
                foreach ($Recipe in $RecipeDirs) {
                    if (-not (Confirm-RecipeFilesExist -RecipeDirPath $Recipe.FullName -RecipeName $Recipe.Name)) {
                        Write-Error -Message "Missing file(s), skipping $($Recipe.Name)"
                    }
                    else {
                        $PackageConfigPath = "$($Recipe.FullName)\$($Recipe.Name).json"
                        $VariableHelperPath = "$($Recipe.FullName)\helpers\getVariables.ps1"
                        $DetectVersionPath = "$($Recipe.FullName)\detectVersion.ps1"
                        $DeployAppPath = "$($Recipe.FullName)\packageApp.ps1"


                        # Load json
                        $PackageConfig = Get-UMNPackageConfig -Path $PackageConfigPath

                        [hashtable]$PackageVariables = . $VariableHelperPath -PackageConfig $PackageConfig
                        Write-Debug -Message "Package Variable Count: $($PackageVariables.Count)"

                        # Set up new package and global config variables based on the variable replacements defined in the package variables
                        # Need to copy then update because of how update works.
                        $UpdatedPackageConfig = $PackageConfig
                        $UpdatedGlobalConfig = $GlobalConfig
                        $UpdatedPackageConfig.ReplaceVariables($PackageVariables)
                        $UpdatedGlobalConfig.ReplaceVariables($PackageVariables)

                        if ($UpdatedPackageConfig.OverridePackagingTargets) {
                            $SiteTargets = $UpdatedPackageConfig.PackagingTargets
                        }
                        else {
                            $SiteTargets = $UpdatedGlobalConfig.PackagingTargets
                        }

                        foreach ($SiteTarget in $SiteTargets) {
                            if (-not ($null -eq $SiteTarget.ApplicationContentPath.LocalPath)) {
                                $GlobalVariables = [hashtable]@{
                                    "{applicationContentPath}" = $SiteTarget.ApplicationContentPath.LocalPath
                                }
                            }
                            else {
                                throw "ApplicationContentPath is not set in the global configuration or the package configuration.`nThis is a key value."
                            }

                            if (-not ($null -eq $SiteTarget.preAppName)) {
                                $GlobalVariables["{preAppName}"] = $SiteTarget.preAppName
                            }

                            if (-not ($null -eq $SiteTarget.postAppName)) {
                                $GlobalVariables["{postAppName}"] = $SiteTarget.postAppName
                            }

                            # Check for newer version
                            $VersionCheck = . $DetectVersionPath -GlobalConfig $UpdatedGlobalConfig -PackageConfig $UpdatedPackageConfig -SiteTarget $SiteTarget

                            # Update Version in variables and in the config
                            $UpdatedPackageConfig.CurrentVersion = $VersionCheck.Version
                            $UpdatedPackageConfig.ReplaceVariable("{currentVersion}", $VersionCheck.Version)

                            Write-Debug -Message "Version Check: $($VersionCheck.ToString())"

                            $UpdatedPackageConfig.ReplaceVariables($GlobalVariables)

                            if ($PackageApp) {
                                if ($VersionCheck.update) {
                                    Write-Information -MessageData "New version found for $($Recipe.Name)"
                                    . $DeployAppPath -GlobalConfig $UpdatedGlobalConfig -PackageConfig $UpdatedPackageConfig -SiteTarget $SiteTarget
                                }
                                else {
                                    Write-Information -MessageData "No new version for $($Recipe.Name)"
                                }
                            }
                            if ($SiteTarget.Type -eq "MEMCM-Application") {
                                # Create Collections
                                if ($CreateCollections) {
                                    New-MEMCMCollections -GlobalConfig $GlobalConfig -SiteTarget $SiteTarget
                                }

                                if ($DeployApp) {
                                    Deploy-MEMCMPackage -GlobalConfig $UpdatedGlobalConfig -PackageConfig $UpdatedPackageConfig -SiteTarget $SiteTarget -Verbose
                                }
                            }
                        }

                        # # Check for newer version
                        # $DetectVersionPath = "$($Recipe.FullName)\detectVersion.ps1"

                        # if (Test-Path -Path $DetectVersionPath) {
                        #     $VersionCheck = . $DetectVersionPath -GlobalConfig $UpdatedGlobalConfig -PackageConfig $UpdatedPackageConfig -InformationAction $InformationPreference
                        #     Write-Information -MessageData "$($VersionCheck.ToString())"
                        #     if ($VersionCheck.update) {
                        #         Write-Information -MessageData "Found new version for $($Recipe.Name)"
                        #         if ($PackageApp) {
                        #             Write-Information -MessageData "Building package for $($Recipe.Name)"
                        #             #. "$($Recipe.FullName)\packageApp.ps1" -GlobalConfig $UpdatedGlobalConfig -PackageConfig $UpdatedPackageConfig
                        #         }

                        #         if ($DeployApp) {
                        #             Write-Information -MessageData "Deploying package for $($Recipe.Name)"
                        #             #."$($Recipe.FullName)\deployApp.ps1" -GlobalConfig $UpdatedGlobalConfig -PackageConfig $UpdatedPackageConfig
                        #         }
                        #     }
                        # }
                        # else {
                        #     Write-Information -MessageData "No new version for $($Recipe.Name)"
                        # }
                    }
                }
            }
        }
    }
}

# PSake makes vvariables declared here available in other scriptblocks
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $env:BHProjectPath
    $ModuleRoot = $env:BHModulePath
    $ModuleName = $env:BHProjectName

    if (-not $ProjectRoot) {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
    }

    $Timestamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$Timestamp.xml"
    $CodeCoverageFile = "CodeCoverage_PS$PSVersion`_$Timestamp.xml"
    $Lines = '------------------------------------------------------------------------'
    $BuildDir = "/BuildOutput"

    [hashtable]$Verbose = @{}
    if ($env:BHCommitMessage -match "!verbose") {
        $Verbose = @{ 'Verbose' = $true }
    }
}

Task Default -Depends Build

Task Init {
    $Lines
    Set-Location -Path $ProjectRoot
    "Build System Details:"
    Get-Item env:BH*
    "`n"
}

Task Test -Depends Init {
    $Lines
    "`n`tSTATUS: Testing with Powershell $PSVersion"

    # Testing links on GitHub requires tls >= 1.2
    $SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Warning -Message "Project Root: $ProjectRoot"
    Write-Warning -Message "Module Root: $ModuleRoot"
    Write-Warning -Message "Module Name: $ModuleName"

    if ($env:BHCommitMessage -notmatch "!skipcodecoverage") {
        $CodeToCheck = Get-ChildItem $ModuleRoot -Include *.ps1, *.psm1 -Recurse
        $CodeCoverageParams = @{
            "CodeCoverageOutputFile" = "$ProjectRoot\build\$CodeCoverageFile"
            "CodeCoverage"           = $CodeToCheck
        }
    }
    else {
        $CodeCoverageParams = @{}
    }

    Import-Module $ModuleRoot

    # Gather test results. Store them in a variable and file.
    $TestResults = Invoke-Pester -Path "$ProjectRoot\tests" -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\build\$TestFile" @CodeCoverageParams @Verbose
    [Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

    # In Appveyor? Upload test results
    if ($env:BHBuildSystem -eq 'AppVeyor') {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env.APPVEYOR_JOB_ID)",
            "$ProjectRoot\build\$TestFile"
        )
    }

    # Put code for Azure Pipelines in here
    if ($env:BHBuildSystem -eq 'Azure Pipelines') {
        $AzureBuild = $True
    }

    # Put code for Unknown systems here
    if ($env:BHBuildSystem -eq 'Unknown') {

    }

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment.
    if ($TestResults.FailedCount -gt 0) {
        Write-Error -Message "Failed '$($TestResults.FailedCount)' tests, build failed."
    }

    "`n"
}

Task Build -Depends Test {
    $Lines
    Set-ModuleFunctions

    if (-not (Test-Path -Path $env:BHBuildOutput)) {
        New-Item $env:BHBuildOutput -Force -ItemType Directory
    }

    if ($AzureBuild) {
        $AzureDevOpsCredentialPair = "$($env:PROJECT_PUBUSER):$($env:PROJECT_PUBKEY)"

        $EncodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($AzureDevOpsCredentialPair))
        $Headers = @{
            "Authorization" = "Basic $EncodedCredentials"
        }
    }
    

    try {
        if ($AzureBuild) {
            # Setup devops package stuffs later
        }
        else {
            # Set azure devops version to 0 so it's ignored.
            [System.Version]$AzureDevOpsVersion = "0.0.0"
        }
    }
    catch {
        Write-Warning -Message "Issue with Azure DevOps Version Detection"
        [System.Version]$AzureDevOpsVersion = "0.0.0"
    }

    Write-Warning -Message "BuildDir = $BuildDir"

    if (-not (Test-Path -Path $BuildDir)) {
        New-Item -Path "$BuildDir" -ItemType Directory -Force
    }

    if (Get-Command -Name "Register-PSRepository" -ErrorAction SilentlyContinue) {
        Register-PSRepository -name "LocalPSRepo" -SourceLocation $BuildDir -PublishLocation $BuildDir -InstallationPolicy Trusted
    }
    else {
        nuget.exe sources Add -Name "LocalPSRepo" -Source "$BuildDir"
    }

    try {
        [System.Version]$GalleryVersion = Get-NextNugetPackageVersion -Name $env:BHProjectName -ErrorAction Stop
    }
    catch {
        Write-Warning -Message "Failed to update gallery version for '$env:BHProjectName': $_.`nContinuing with existing version"
        [System.Version]$GalleryVersion = "0.0.0"
    }

    try {
        [System.Version]$GitHubVersion = Get-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -ErrorAction Stop
    }
    catch {
        Write-Warning -Message "Failed to update GitHub version for '$env:BHProjectName': $_`nContinuing with existing version"
        [System.Version]$GitHubVersion = "0.0.0"
    }

    try {
        [System.Version]$LocalPSRepoVersion = Find-Module -Name $env:BHProjectName | Select-Object -ExpandProperty Version
    }
    catch {
        Write-Warning -Message "Failed to pull local repo version."
        [System.Version]$LocalPSRepoVersion = "0.0.0"
    }

    Write-Host -Object "---"
    Write-Host -Object "GalleryVersion = $($GalleryVersion.ToString())"
    Write-Host -Object "AzureDevOpsVersion = $($AzureDevOpsVersion.ToString())"
    Write-Host -Object "GitHubVersion = $($GitHubVersion.ToString())"
    Write-Host -Object "---"

    if (($LocalPSRepoVersion -ge $GitHubVersion) -and ($LocalPSRepoVersion -ge $AzureDevOpsVersion) -and ($LocalPSRepoVersion -ge $GalleryVersion)) {
        $NewVersion = New-Object -TypeName System.Version ($LocalPSRepoVersion.Major, $LocalPSRepoVersion.Minor, ($LocalPSRepoVersion.Build + 1))
    }
    elseif (($GalleryVersion -ge $GitHubVersion) -and ($GalleryVersion -ge $AzureDevOpsVersion)) {
        $NewVersion = New-Object System.Version ($GalleryVersion.Major, $GalleryVersion.Minor, ($GalleryVersion.Build + 1))
    }
    elseif ($GitHubVersion -ge $AzureDevOpsVersion) {
        $NewVersion = New-Object System.Version ($GitHubVersion.Major, $GitHubVersion.Minor, $GitHubVersion.Build)
    }
    else {
        $NewVersion = New-Object System.Version ($AzureDevOpsVersion.Major, $AzureDevOpsVersion.Minor, ($AzureDevOpsVersion.Build + 1))
    }

    Write-Warning -Message "NewVersion = $($NewVersion.ToString())"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName "ModuleVersion" -Value $NewVersion -ErrorAction Stop

    Publish-Module -Path $env:BHModulePath -Repository "LocalPSRepo" -NuGetApiKey "AzureDevOps" -Force -Verbose

    $Lines
}

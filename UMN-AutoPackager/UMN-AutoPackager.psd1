@{
    RootModule        = 'UMN-AutoPackager.psm1'
    NestedModules     = @('bin\UMN-AutoPackager.dll')
    ModuleVersion     = '0.0.1'
    GUID              = '9dff7a8a-115f-42be-8dd2-6b946dc9d9e4'
    Author            = 'Jeff Bolduan, Matt Thoen, Greg Slavik'
    CompanyName       = 'University of Minnesota'
    Copyright         = '(c) 2021 University of Minnesota.  All rights reserved.'
    Description       = 'Auto packager to detect newer version and build applications in MEMCM and Intune.'
    PowerShellVersion = '7.0'
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        Tags         = @('Automation', 'MEMCM', 'SCCM', 'Intune', 'UMN')
        LicenseUri   = 'https://github.com/umn-microsoft-automation/UMN-AutoPackager/blob/main/LICENSE'
        ProjectUri   = 'https://github.com/umn-microsoft-automation/UMN-AutoPackager/'
        # IconUri = ''
        ReleaseNotes = 'https://github.com/umn-microsoft-automation/UMN-AutoPackager/releases/latest'
    }
}

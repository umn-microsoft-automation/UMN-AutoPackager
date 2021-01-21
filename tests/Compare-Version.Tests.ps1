$TestConfig = @{
    "TestModuleName" = "UMN-AutoPackager"
}

try {
    if($ModuleRoot) {
        Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force -Verbose
    } else {
        if(Test-Path -Path ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force -Verbose
        } elseif(Test-Path .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force -Verbose
        }
    }

    InModuleScope -ModuleName $TestConfig.TestModuleName {
        Describe "Compare-Version" {
            It "[SemVer] Should return true if the reference version is larger than the difference version." {
                Compare-Version -ReferenceVersion "2.0.0" -DifferenceVersion "1.0.0" | Should -BeTrue
                Compare-Version -ReferenceVersion "2.0.0-beta1" -DifferenceVersion "2.0.0-alpha1" | Should -BeTrue
                Compare-Version -ReferenceVersion "36" -DifferenceVersion "20" | Should -BeTrue
            }

            It "[System.Version] Should return true if the reference version is larger than the difference version." {
                Compare-Version -ReferenceVersion "2.0.0.0" -DifferenceVersion "1.0.0.0" | Should -BeTrue
            }
        }
    }
} catch {
    $Error[0]
}
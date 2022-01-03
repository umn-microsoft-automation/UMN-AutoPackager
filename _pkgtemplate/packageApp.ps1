param(
    $GlobalConfig,

    $PackageConfig,

    $SiteTarget
)

# Put any code required ahead of the package creation here.

Build-MEMCMPackage -GlobalConfig $GlobalConfig -PackageConfig $PackageConfig -SiteTarget $SiteTarget

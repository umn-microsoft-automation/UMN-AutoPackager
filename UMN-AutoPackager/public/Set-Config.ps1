# Sets global configurations for the auto packager in a standard location. This will need to be determined when building get/set config functions.
# Possible global values in JSON. Where the recipes are stored? UNC Path, Settings needed for ConfigMgr (or other tools like JAMF)? SiteCode, Site name, Service Account for access
# Set-Config -Path .\config.json -Object ConfigMgr -Name SiteCode  -Value "UMN"
# Set-Config -Path .\config.json -Name Company  -Value "University of Minnesota"
# (Get-CMSite).SiteCode | Set-Config -Path .\config.json -Object ConfigMgr  -Name SiteCode
# Creates standard deployments (may require definition in the global configuration) in MEMCM
# Deploy-MEMCMPackage -Path GlobalConfig.json -Name PackageConfig
# Creates a deployment(s) based on the data in the PackageConfig and GlobalConfig.
# Needs to find the collection based on information in the packageconfig and globalconfig.
# Needs to know what kind of deployment is selected. Maybe this is another reason to add it to the package config?
# Need to know other deployment information maybe there is standard settings pulled out of the GlobalConfig or packageconfig.
# How many days before deadline? Yes No Deadline? unique per application or global setting
# Is this available or required? Maybe we assume all these will be required.
# User experience setting? Alerts? Global Config or unique per application
# Default Content distribution? Global Config
# If we start using stuff besides single collection single deployment we will need to accomadate that.

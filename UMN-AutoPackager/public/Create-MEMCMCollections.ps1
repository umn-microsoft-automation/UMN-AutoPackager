# Create standard MEMCM collections based off global configuration
# Create-MEMCMCollections -Path .\GlobalConfig.json -Name PackageConfig
# Creates a collection(s) based on the Global Config settings. Need the Limiting Collection to base this on.
# Where does the naming convention come from? This should be unique so we can use it for the deploy function. Maybe it adds the collection name(s) to the package config?
# Let's start simple with a single collection based on some information from the PacakgeConfig.
# Maybe we use a switch to define the various ways to deploy. Single, Three Collection Rollout, Phased Deployment Collection. Or maybe it makes a query
# Options to change the standard settings for collection evaluation or to make it incremental.
# Keep in mind user deployment versus device?
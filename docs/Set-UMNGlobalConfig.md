---
external help file: UMN-AutoPackager-help.xml
Module Name: UMN-AutoPackager
online version:
schema: 2.0.0
---

# Set-UMNGlobalConfig

## SYNOPSIS
Sets a value(s) for the global configuration JSON file for the auto packager.

## SYNTAX

### Main (Default)
```
Set-UMNGlobalConfig -Path <String> -Key <String> -Value <String> [<CommonParameters>]
```

### RecipeLocations
```
Set-UMNGlobalConfig [-Path <String>] [-Key <String>] [-Value <String>] -LocationType <String>
 [<CommonParameters>]
```

### ConfigMgr
```
Set-UMNGlobalConfig [-Path <String>] [-Key <String>] -SiteServer <String> -SiteCode <String>
 -DownloadLocationPath <String> -ApplicationContentPath <String> [<CommonParameters>]
```

## DESCRIPTION
This command sets in a json file a value for one of various global configurations used as part of the AutoPackager.
It requires a the full path and name of the JSON file, the key to set, and the value to set it to.

## EXAMPLES

### EXAMPLE 1
```
Set-UMNGlobalConfig -Path .\GlobalConfig.json -Key CompanyName  -Value "University of Minnesota"
Sets the value of CompanyName to University of Minnesota for the config.json file
```

### EXAMPLE 2
```
Set-UMNGlobalConfig -Path .\GlobalConfig.json -Key ConfigMgr -SiteServer "my.config.site"  -SiteCode "COM" -DownloadLocationPath "C:\\Temp" -ApplicationContentPath "\\appstorage.somewhere\"
Sets the values for a ConfigMgr site to be added to the config.json file
```

### EXAMPLE 3
```
Set-UMNGlobalConfig -Path .\GlobalConfig.json -Key RecipeLocations -Value "\\file.server\recipes" -LocationType "directory"
Adds the location "\\files.server\recipes" and LocationType "directory" to the RecipeLocations key in the JSON specified
```

## PARAMETERS

### -Path
The full path and file name of the JSON file to be updated

```yaml
Type: String
Parameter Sets: Main
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: RecipeLocations, ConfigMgr
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key
The key that you want to update in the Global Configuation JSON file

```yaml
Type: String
Parameter Sets: Main
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: RecipeLocations, ConfigMgr
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The single value you want to set the key to

```yaml
Type: String
Parameter Sets: Main
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: RecipeLocations
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteServer
The ConfigMgr site server address

```yaml
Type: String
Parameter Sets: ConfigMgr
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteCode
The site code for this instance of ConfigMgr

```yaml
Type: String
Parameter Sets: ConfigMgr
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DownloadLocationPath
The full path where downloaded data will be temporarily stored

```yaml
Type: String
Parameter Sets: ConfigMgr
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationContentPath
The full path for where ConfigMgr applcation content will be stored

```yaml
Type: String
Parameter Sets: ConfigMgr
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocationType
The location type for where the recipes will be stored for the autopackager.
Directory will be the most common.

```yaml
Type: String
Parameter Sets: RecipeLocations
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

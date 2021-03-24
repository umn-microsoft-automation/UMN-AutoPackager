---
external help file: UMN-AutoPackager-help.xml
Module Name: UMN-AutoPackager
online version:
schema: 2.0.0
---

# Get-UMNGlobalConfig

## SYNOPSIS
Gets all the global configurations and value for each from a JSON file used by the auto packager.

## SYNTAX

```
Get-UMNGlobalConfig [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
This command retrieves from a json file the values of various global configurations used as part of the AutoPackager.
It requires a the full path and name of the JSON file.

## EXAMPLES

### EXAMPLE 1
```
Get-UMNGlobalConfig -Path .\config.json
Gets the values of the config.json file
```

## PARAMETERS

### -Path
The full path and file name of the JSON file to get the config from

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

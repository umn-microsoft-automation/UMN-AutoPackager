---
external help file: UMN-AutoPackager-help.xml
Module Name: UMN-AutoPackager
online version:
schema: 2.0.0
---

# Get-NewPackageFile

## SYNOPSIS
Cmdlet that saves a file from a file path, UNC, or URI and saves it to the specified location.

## SYNTAX

```
Get-NewPackageFile [-Source] <String> [-Destination] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Get-NewPackageFile is a function that when provided with a Source file path, UNC, or URI (as a string) and a Destination path or
UNC (as a string) will copy or download the Source file to the Destination.
Characters of a space (" ") or an escaped space ("%20")
are replaced with an underscore ("_") when saved to the Destination.
Returns object information of the saved file.

## EXAMPLES

### EXAMPLE 1
```
Get-NewPackageFile -Source "C:\Test\File1.txt" -Destination "D:\Temp\File2.txt"
```

### EXAMPLE 2
```
Get-NewPackageFile -Source "C:\Test\File1.txt" -Destination "D:\Temp\"
```

### EXAMPLE 3
```
Get-NewPackageFile -Source "C:\Test\File1.txt" -Destination "\\fileserver\Temp\File1.txt"
```

### EXAMPLE 4
```
Get-NewPackageFile -Source "\\fileserver\Test\File1.txt" -Destination "D:\Temp\File1.txt"
```

### EXAMPLE 5
```
Get-NewPackageFile -Source "\\fileserver1\Test\File1.txt" -Destination "\\fileserver2\Temp\File1.txt"
```

### EXAMPLE 6
```
Get-NewPackageFile -Source "https://webserver.xyz/Test/File1.txt" -Destination "C:\Temp\File1.txt"
```

### EXAMPLE 7
```
Get-NewPackageFile -Source "https://webserver.xyz/Test/File1.txt" -Destination "\\fileserver\Temp\File1.txt"
```

## PARAMETERS

### -Source
A string that must be a file path, UNC, or URI of the file to be saved to the Destination location.
Wildcards are not permitted.

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

### -Destination
A string that must be a file path or UNC where the Source file will be saved.
Wildcards are not permitted.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
## OUTPUTS

### System.IO.FileInfo
### Get-NewPackageFile returns information on the file saved in the location specified in the Destination parameter.
## NOTES
If the Destination parameter is only a file path and does not include a filename, the filename obtained from the Source parameter
is used during the copy.
Requires use of the "Get-RedirectedUri" function.

## RELATED LINKS

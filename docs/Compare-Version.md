---
external help file: UMN-AutoPackager-help.xml
Module Name: UMN-AutoPackager
online version:
schema: 2.0.0
---

# Compare-Version

## SYNOPSIS
Takes a reference object and a difference object and determines if the reference object is greater than the difference object.

## SYNTAX

```
Compare-Version [-ReferenceVersion] <String> [-DifferenceVersion] <String> [<CommonParameters>]
```

## DESCRIPTION
Takes a reference object and a difference object and determines if the reference object is greater than the difference object.

Example: (reference) 1.0 \> 0.1 (difference) would return true

## EXAMPLES

### EXAMPLE 1
```
Compare-Version -ReferenceVersion "1.0.0.0" -DifferenceVersion "2.0.0.0" would return $false
```

### EXAMPLE 2
```
Compare-Version -ReferenceVersion "2.0.0-beta1" -DifferenceVersion "2.0.0-alpha12" would return $true
```

## PARAMETERS

### -ReferenceVersion
Version as a string which is on the left side of the greater than equation.

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

### -DifferenceVersion
Version as a string which is on the right side of the greater than equation.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

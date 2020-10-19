# ConvertTo-RawDataDepartmentObject

## SYNOPSIS
Converts the departments objects to a raw data department object

## SYNTAX

```
ConvertTo-RawDataDepartmentObject [-Departments] <PSObject> [<CommonParameters>]
```

## DESCRIPTION
Converts the departments objects to a raw data department object that can be imported into HelloID

## PARAMETERS

### -Departments
The list of Departments from ADP Workforce

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## OUTPUTS

### System.Object[]

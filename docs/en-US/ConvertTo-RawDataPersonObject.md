# ConvertTo-RawDataPersonObject

## SYNOPSIS
Converts the ADP Worker object to a raw data object

## SYNTAX

```
ConvertTo-RawDataPersonObject [-Workers] <PSObject> [<CommonParameters>]
```

## DESCRIPTION
Converts the ADP Worker object to a \[RawDataPersonObject\] that can be imported into HelloID

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Workers
The list of Workers from ADP Workforce

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

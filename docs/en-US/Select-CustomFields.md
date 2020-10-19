# Select-CustomFields

## SYNOPSIS
Flattens the \[worker.customFieldGroup\] array object

## SYNTAX

```
Select-CustomFields [-CustomFields] <PSObject> [<CommonParameters>]
```

## DESCRIPTION
Flattens the \[worker.customFieldGroup\] array

## EXAMPLES

### EXAMPLE 1
```
$worker.customFieldGroup
```

stringFields
------------
{@{nameCode=; stringValue=Nikolai}, @{nameCode=; stringValue=}, @{nameCode=; stringValue=RTM}, @{nameCode=; stringValue=tiva}...}

PS C:\\\> Select-CustomFields -CustomFields $worker.customFieldGroup

partnerFamilyName1        : Nikolai
partnerFamilyName1Prefix  :
partnerInitials           : RTM
naamSamenstelling         : tiva
samengesteldeNaam         : NDS Burghout
loginName                 :
verwijzendWerknemernummer : P001
leefvormCode              :

Returns a PSCustomObject containing the customFields from the \[worker.customFieldGroup\] object

## PARAMETERS

### -CustomFields
The StringFields array containing the customFields for a worker or assignment

```yaml
Type: PSObject
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

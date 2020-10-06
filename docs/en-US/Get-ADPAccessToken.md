# Get-ADPAccessToken

## SYNOPSIS
Retrieves an AccessToken from the ADP API

## SYNTAX

```
Get-ADPAccessToken [-CientID] <String> [-ClientSecret] <SecureString> [-Certifcate] <X509Certificate>
 [<CommonParameters>]
```

## DESCRIPTION
The ADP Workforce API's uses OAuth for authentication\authorization.
Before data can be retrieved from the API's, an AccessToken has to obtained.
The AccessToken is used for all consecutive calls to the ADP Workforce API's

## EXAMPLES

### EXAMPLE 1
```
Get-ADPAccessToken -Client 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -Certifcate 'Customer_ADP_Dev.pfx'
```

{
    "access_token": "1",
    "token_type": "2",
    "expires_in": "2"
}

## PARAMETERS

### -CientID
The ClientID for the ADP Workforce environment.
This will be provided by ADP

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

### -ClientSecret
The ClientSecret for the ADP Workforce environment.
This will be provided by ADP

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certifcate
{{ Fill Certifcate Description }}

```yaml
Type: X509Certificate
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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

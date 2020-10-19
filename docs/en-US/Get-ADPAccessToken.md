# Get-ADPAccessToken

## SYNOPSIS
Retrieves an AccessToken from the ADP API using the standard \<Invoke-RestMethod\> cmdlet

## SYNTAX

```
Get-ADPAccessToken [-CientID] <String> [-ClientSecret] <SecureString> [-Certifcate] <String>
 [<CommonParameters>]
```

## DESCRIPTION
The ADP Workforce API's uses OAuth for authentication\authorization.
Before data can be retrieved from the API's, an AccessToken has to obtained. The AccessToken is used for all consecutive calls to the ADP Workforce API's. Tokens only have access to a certain API scope. Default the scope is set to: 'worker-demographics organization-departments'. Data outside this scope from other API's cannot be retrieved

## EXAMPLES

### EXAMPLE 1
```
Get-ADPAccessToken -ClientID 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -CertifcatePath 'Customer_ADP_Dev.pfx' -CertificatePassword 'CertificatePassword'
```

Retrieves an accesstoken that is authenticated for the 'worker-demographics' and 'organizational-departments' API's

## PARAMETERS

### -ClientID
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
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertifcatePath
The location to the the private key of the x.509 certificate on the server where the HelloID agent and provisioning agent are running. Make sure to use the private key for the certificate that's used to generate a ClientID and ClientSecret and for activating the required API's

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificatePassword
The password for the *.pfx certificate

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

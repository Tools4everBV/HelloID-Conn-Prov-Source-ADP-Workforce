# Get-ADPWorkers

## SYNOPSIS
Retrieves the Workers and WorkerAssignments from ADP Workforce

## SYNTAX

```
Get-ADPWorkers [[-BaseUrl] <String>] [[-ClientID] <String>] [[-ClientSecret] <String>]
 [[-CertificatePath] <String>] [[-CertificatePassword] <String>] [[-ProxyServer] <String>]
 [[-ImportFile] <Boolean>] [[-WorkerJson] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves the Workers and WorkerAssignments from ADP Workforce

## PARAMETERS

### -BaseUrl
The BaseUrl to the ADP Workforce environment.
For example: https://test-api.adp.com

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientID
The ClientID for the ADP Workforce environment.
This will be provided by ADP

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificatePath
The location to the the private key of the x.509 certificate on the server where the HelloID agent and provisioning agent are running
Make sure to use the private key for the certificate that's used to generate a ClientID and ClientSecret and for activating the required API's

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxyServer
The URL (or IP Address) to the ProxyServer in the network.
Leave empty if no ProxyServer is being used

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportFile
Use this in combination with the JSON file to test the import of the workers without making API calls to ADP Workforce

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkerJson
The location to the 'JSON file containing the workers' on the server where the HelloID agent and provisioning agent are running.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
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

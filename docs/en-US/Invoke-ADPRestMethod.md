# Invoke-ADPRestMethod

## SYNOPSIS
Sends and receives data to and from the ADP API's

## SYNTAX

```
Invoke-ADPRestMethod [-Uri] <String> [-Method] <String> [-AccessToken] <String> [[-ProxyServer] <String>]
 [[-SecurityProtocol] <SecurityProtocolType>] [<CommonParameters>]
```

## DESCRIPTION
Sends and receives data to and from the ADP API's

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Uri
The BaseUri to the ADP Workforce environment

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

### -Method
The CRUD operation for the request.
Valid HttpMethods inlcude: GET and POST

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

### -AccessToken
The AccessToken retrieved by the \<Get-ADPAccessToken\> function

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

### -ProxyServer
The URL (or IP Address) to the ProxyServer in the network.
Leave empty if no ProxyServer is being used

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

### -SecurityProtocol
The encprytion protocol used when sending data across the network.
The default is set to TLS1.2

```yaml
Type: SecurityProtocolType
Parameter Sets: (All)
Aliases:
Accepted values: SystemDefault, Ssl3, Tls, Tls11, Tls12, Tls13

Required: False
Position: 5
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

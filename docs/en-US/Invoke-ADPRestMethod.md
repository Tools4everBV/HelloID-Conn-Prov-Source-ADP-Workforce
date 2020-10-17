# Invoke-ADPRestMethod

## SYNOPSIS
Retrieves data from the ADP API's

## SYNTAX

```
Invoke-ADPRestMethod [-Uri] <String> [-Method] <String> [-AccessToken] <AllowNullAttribute>
 [[-ProxyServer] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves data from the ADP API's using the standard \<Invoke-RestMethod\> cmdlet

## EXAMPLES

### EXAMPLE 1
```
Invoke-ADPRestMethod -Uri 'https://test-api.adp.com/hr/v2/worker-demographics' -Method 'GET' -AccessToken '0000-0000-0000-0000'
```

Returns the raw JSON data containing all workers from ADP Workforce

## PARAMETERS

### -Uri
The BaseUri to the ADP Workforce environment.
For example: https://test-api.adp.com

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
Valid HttpMethods inlcude: GET and POST.
Note that the ADP API's needed for the connector will only support 'GET'

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
Type: AllowNullAttribute
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216)

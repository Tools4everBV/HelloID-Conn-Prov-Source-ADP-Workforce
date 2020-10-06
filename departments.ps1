#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Departments
# 
# Version: 1.0.0
#####################################################

#Region External functions
function Get-ADPDepartments {
    <#
    .SYNOPSIS
    Retrieves the department data from ADP Workforce

    .DESCRIPTION
    Retrieves the department data from ADP Workforce

    .PARAMETER CientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret
    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER Certificate
    The private key of the x.509 certificate that's used to generate a ClientID and ClientSecret and for activating the required API's.

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

    .PARAMETER SecurityProtocol
    The encprytion protocol used when sending data across the network. The default is set to TLS1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $CientID,

        [Parameter(Mandatory)]
        [SecureString]
        $ClientSecret,

        [Parameter(Mandatory)]
        [X509Certificate]
        $Certifcate,

        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ProxyServer,

        [System.Net.SecurityProtocolType]
        $SecurityProtocol
    )

    $baseUri = [System.Uri]'https://api.dex.adp.com'

    try {
        $accessToken = Get-ADPAccessToken -CientID $ClientID -ClientSecret $ClientSecret -Certifcate $Certifcate
    } catch [System.Net.WebException] {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($ex.Message)'")
    }

    try {
        $splatADPRestMethodParams = @{
            Uri = "$($baseUri)core/v1/departments"
            Method = 'GET'
            AccessToken = $accessToken
            ProxyServer = $ProxyServer
            SecurityProtocol = $SecurityProtocol
        }
        Invoke-ADPRestMethod @splatADPRestMethodParams | ConvertTo-RawDataDepartmentObject | ConvertTo-Json -Depth 100
    } catch [System.Net.WebException] {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $PSCmdlet.WriteError("Could not retrieve ADP Departments. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP Departments. Error: '$($ex.Message)'")
    }
}
#EndRegion

#Region Internal functions
function Get-ADPAccessToken {
    <#
    .SYNOPSIS
    Retrieves an AccessToken from the ADP API

    .DESCRIPTION
    The ADP Workforce API's uses OAuth for authentication\authorization. Before data can be retrieved from the API's, an AccessToken has to obtained. The AccessToken is used for all consecutive calls to the ADP Workforce API's

    .PARAMETER CientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret
    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER Certificate
    The private key of the x.509 certificate that's used to generate a ClientID and ClientSecret and for activating the required API's. 

    .EXAMPLE
    Get-ADPAccessToken -Client 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -Certifcate 'Customer_ADP_Dev.pfx'

    {
        "access_token": "1",
        "token_type": "2",
        "expires_in": "2"
    }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $CientID,

        [Parameter(Mandatory)]
        [SecureString]
        $ClientSecret,

        [Parameter(Mandatory)]
        [X509Certificate]
        $Certifcate
    )

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
    $clientSecretString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    
    $authorization = "$($CientID):$($clientSecretString)"
    $base64String = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))

    $headers = @{
        "Cache-Control" = "no-cache"
        "Authorization" = "Basic $base64String"
        "Content-Type" = "application/json"
        "grant_type" = "client_credentials&scope=api"
    }

    try {
        $splatRestMethodParameters = @{
            Uri = 'https://accounts.dex.adp.com/auth/oauth/v2/token'
            Method = 'POST'
            Headers = $headers
        }
        Invoke-RestMethod @splatRestMethodParameters
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function Invoke-ADPRestMethod {
    <#
    .SYNOPSIS
    Sends and receives data to and from the ADP API's

    .DESCRIPTION
    Sends and receives data to and from the ADP API's

    .PARAMETER Uri
    The BaseUri to the ADP Workforce environment

    .PARAMETER Method
    The CRUD operation for the request. Valid HttpMethods inlcude: GET and POST

    .PARAMETER AccessToken
    The AccessToken retrieved by the <Get-ADPAccessToken> function

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

    .PARAMETER SecurityProtocol
    The encprytion protocol used when sending data across the network. The default is set to TLS1.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $Uri,

        [Parameter(Mandatory)]
        [String]
        $Method,

        [Parameter(Mandatory)]
        [String]
        $AccessToken,

        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ProxyServer,

        [System.Net.SecurityProtocolType]
        $SecurityProtocol
    )

    $headers = @{
        "grant_type" = "client_credentials&scope=api"
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $AccessToken"
    }

    if ([string]::IsNullOrEmpty($ProxyServer)){
        $proxy = $null
    } else {
        $proxy = $ProxyServer
    }

    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::$SecurityProtocol

        $splatRestMethodParameters = @{
            Uri = $Uri
            Method = $Method
            Headers = $headers
            Proxy = $proxy
            UseBasicParsing = $true
        }
        Invoke-RestMethod @splatRestMethodParameters
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function ConvertTo-RawDataDepartmentObject {
    <#
    .SYNOPSIS
    Converts the departments objects to a raw data department object

    .DESCRIPTION
    Converts the departments objects to a raw data department object that can be imported into HelloID

    .PARAMETER Departments
    The list of departments from ADP Workforce
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        [PSObject]
        $Departments
    )
    process {
        [System.Collections.Generic.List[object]]$listDepartments = @()

        foreach ($department in $department.organizationDepartments) {
            $departmentObj = [PSCustomObject]@{
                ExternalId = $department.departmentCode
                DisplayName = $department.departmentCode
                ParentDepartmentCode = $department.parentDepartmentCode
                DepartmentCode = $department.departmentCode
                DepartmentDescription = $department.departmentDescription
                ActiveIndicator = $department.activeIndicator
                EffectiveDate = $department.effectiveDate
            }
            $listDepartments.Add($departmentObj)
        }
        $listDepartments
    }   
}
#EndRegion

#Region Script
<#
.SYNOPSIS
Retrieves the Departments from ADP Workforce

.DESCRIPTION
Retrieves the Departments from ADP Workforce

.PARAMETER CientID
The ClientID for the ADP Workforce environment. This will be provided by ADP

.PARAMETER ClientSecret
The ClientSecret for the ADP Workforce environment. This will be provided by ADP

.PARAMETER Certificate
The private key of the x.509 certificate that's used to generate a ClientID and ClientSecret and for activating the required API's.

.PARAMETER ProxyServer
The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

.PARAMETER SecurityProtocol
The encprytion protocol used when sending data across the network. The default is set to TLS1.2
#>
$SplatADPGetWorkers = @{
    ClientID = ''
    ClientSecret = ''
    Certificate = ''
    ProxyServer =  ''
    SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
Get-ADPDepartments @SplatADPGetWorkers
#EndRegion
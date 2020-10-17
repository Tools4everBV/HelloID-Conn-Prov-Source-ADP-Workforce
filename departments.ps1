#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Departments
# 
# Version: 1.0.2
#####################################################

#Region External functions
function Get-ADPDepartments {
    <#
    .SYNOPSIS
    Retrieves the Departments from ADP Workforce

    .DESCRIPTION
    Retrieves the Departments from ADP Workforce

    .PARAMETER ConfigurationSettings
    The ConfigurationSettings set on the System configuration tab within HelloID
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSObject]
        $ConfigurationSettings
    )

    try {
        if(!$($ConfigurationSettings.ImportFile)){
            $clientSecretBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($ConfigurationSettings.CLientSecret))
            $clientSecretString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($clientSecretBstr)
            $accessToken = Get-ADPAccessToken -CientID $($ConfigurationSettings.ClientID) -ClientSecret $clientSecretString -Certifcate $($ConfigurationSettings.Certificate) -ApiScope $($ConfigurationSettings.ApiScope)
        }
    } catch [System.Net.WebException] {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($ex.Message)'")
    }

    try {
        if ($($ConfigurationSettings.ImportFile)){
            Get-Content $($ConfigurationSettings.JsonFile) | ConvertFrom-Json | ConvertTo-RawDataDepartmentObject | ConvertTo-Json -Depth 100
        } else {
            $splatADPRestMethodParams = @{
                Uri = "$($ConfigurationSettings.BaseUrl)/core/v2/organization-departments"
                Method = 'GET'
                AccessToken = $accessToken
                ProxyServer = $ProxyServer
                SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            }
            Invoke-ADPRestMethod @splatADPRestMethodParams | ConvertTo-RawDataPersonObject | ConvertTo-Json -Depth 100
        }
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
    Retrieves an AccessToken from the ADP API using the standard <Invoke-RestMethod> cmdlet

    .DESCRIPTION
    The ADP Workforce API's uses OAuth for authentication\authorization.
    Before data can be retrieved from the API's, an AccessToken has to obtained. The AccessToken is used for all consecutive calls to the ADP Workforce API's

    .PARAMETER CientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret
    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER Certificate
    The location to the the private key of the x.509 certificate on the server where the HelloID agent and provisioning agent are running
    Make sure to use the private key for the certificate that's used to generate a ClientID and ClientSecret and for activating the required API's

    .PARAMETER ApiScope
    The name of the API you need access to. For instance, 'worker-demographics'. You can specficy more API's by separating them with a comma
    To get access to all available API's, set the scope to: 'api

    .EXAMPLE
    Get-ADPAccessToken -Client 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -Certifcate 'Customer_ADP_Dev.pfx' -ApiScope 'api'

    Retrieves an accesstoken that is authenticated for all API's.

    .EXAMPLE
    Get-ADPAccessToken -Client 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -Certifcate 'Customer_ADP_Dev.pfx' -ApiScope 'worker-demographics, organizational-departments'

    Retrieves an accesstoken that is authenticated for the worker-demographics' and 'organizational-departsments' API
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
        [String]
        $Certifcate,

        [Parameter(Mandatory)]
        [String]
        $ApiScope
    )

    $authorization = "$($CientID):$($ClientSecret)"
    $base64String = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))

    $headers = @{
        "Cache-Control" = "no-cache"
        "Authorization" = "Basic $base64String"
        "Content-Type" = "application/json"
        "grant_type" = "client_credentials&scope=$ApiScope"
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
    Retrieves data from the ADP API's

    .DESCRIPTION
    Retrieves data from the ADP API's using the standard <Invoke-RestMethod> cmdlet

    .PARAMETER Uri
    The BaseUri to the ADP Workforce environment. For example: https://test-api.adp.com

    .PARAMETER Method
    The CRUD operation for the request. Valid HttpMethods inlcude: GET and POST. Note that the ADP API's needed for the connector will only support 'GET'

    .PARAMETER AccessToken
    The AccessToken retrieved by the <Get-ADPAccessToken> function

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

    .EXAMPLE
    Invoke-ADPRestMethod -Uri 'https://test-api.adp.com/hr/v2/worker-demographics' -Method 'GET' -AccessToken '0000-0000-0000-0000'

    Returns the raw JSON data containing all workers from ADP Workforce
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
        [AllowNull]
        [AllowEmptyString]
        [String]
        $AccessToken,

        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ProxyServer
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
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

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
    Converts the departments objects to a [RawDataDepartmentObject] that can be imported into HelloID

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

        foreach ($department in $Departments.organizationDepartments) {
            for ($i = 0; $i -lt $department.auxilliaryFields.Length; $i++) {
                foreach ($auxField in $department.auxilliaryFields){
                    $auxFieldObj = [PSCustomObject]@{
                        FieldName = $auxField[$i].NameCode.codeValue
                        FieldCode = $auxField[$i].stringValue
                    }
                }
            }

            $departmentObj = [PSCustomObject]@{
                ExternalId = $department.departmentCode.codeValue
                DisplayName = $department.departmentCode.longName
                ParentDepartmentCode = $department.parentDepartmentCode.codeValue
                DepartmentDescription = $department.departmentDescription
                AssignedLocation = @{
                    StreetName = $department.assignedLocation.streetName
                    Number = $department.assignedLocation.buildingNumber
                    PostalCode = $department.assignedLocation.postalCode
                    CityName = $department.assignedLocation.cityName
                    Unit = $department.assignedLocation.unit
                }
                ActiveIndicator = $department.activeIndicator
                EffectiveDate = $department.effectiveDate
                AuxilliaryFields = $auxFieldObj
            }
            $listDepartments.Add($departmentObj)
        }
        $listDepartments
    }   
}
#EndRegion

#Region Script
$connectionSettings = ConvertFrom-Json $configuration
Get-ADPDepartments -Configuration $connectionSettings
#EndRegion

#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Departments
#
# Version: 1.0.5.1
#####################################################

#Region External functions
function Get-ADPDepartments {
    <#
    .SYNOPSIS
    Retrieves the Departments from ADP Workforce

    .DESCRIPTION
    Retrieves the Departments from ADP Workforce

    .PARAMETER BaseUrl
    The BaseUrl to the ADP Workforce environment. For example: https://api.eu.adp.com

    .PARAMETER ClientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret

    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER CertificatePath
    The location to the the private key of the x.509 certificate on the server where the HelloID agent and provisioning agent are running
    Make sure to use the private key for the certificate that's used to generate a ClientID and ClientSecret and for activating the required API's

    .PARAMETER CertificatePassword
    The password for the *.pfx certificate

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $BaseUrl,

        [Parameter(Mandatory)]
        [String]
        $ClientID,

        [Parameter(Mandatory)]
        [String]
        $ClientSecret,

        [Parameter(Mandatory)]
        [String]
        $CertificatePath,

        [Parameter(Mandatory)]
        [String]
        $CertificatePassword,
        
        [String]
        $ProxyServer
    )

    try {
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CertificatePath, $CertificatePassword)
        $accessToken = Get-ADPAccessToken -ClientID $ClientID -ClientSecret $ClientSecret -Certificate $certificate
    } catch [System.Net.WebException] {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($ex.Exception.Message)'")
    }

    try {
        $splatADPRestMethodParams = @{
            Url = "$BaseUrl/core/v1/organization-departments"
            Method = 'GET'
            AccessToken = $accessToken.access_token
            ProxyServer = $ProxyServer
            Certificate = $certificate
        }
        Invoke-ADPRestMethod @splatADPRestMethodParams | ConvertTo-RawDataDepartmentObject | ConvertTo-Json -Depth 100
    } catch [System.Net.WebException] {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $PSCmdlet.WriteError("Could not retrieve ADP Departments. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP Departments. Error: '$($ex.Exception.Message)'")
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
    Before data can be retrieved from the API's, an AccessToken has to obtained. The AccessToken is used for all consecutive calls to the ADP Workforce API's. 
    Tokens only have access to a certain API scope. Default the scope is set to: 'worker-demographics organization-departments'. 
    Data outside this scope from other API's cannot be retrieved

    .PARAMETER ClientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret
    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER Certificate
    The [X509Certificate] object containing the *.pfx

    .EXAMPLE
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new("the path to the *.pfx file", "Password for the *.pfx certificate")

    Get-ADPAccessToken -Client 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -Certifcate $certificate
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $ClientID,

        [Parameter(Mandatory)]
        [String]
        $ClientSecret,

        [X509Certificate]
        $Certificate
    )

    $headers = @{
        "content-type" = "application/x-www-form-urlencoded"
    }

    $body = @{
        client_id = $ClientID
        client_secret = $ClientSecret
        grant_type = "client_credentials"
    }

    try {
        $splatRestMethodParameters = @{
            Uri = 'https://accounts.eu.adp.com/auth/oauth/v2/token'
            Method = 'POST'
            Headers = $headers
            Body = $body
            Certificate = $certificate
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

    .PARAMETER Url
    The BaseUrl to the ADP Workforce environment. For example: https://test-api.adp.com

    .PARAMETER Method
    The CRUD operation for the request. Valid HttpMethods inlcude: GET and POST. Note that the ADP API's needed for the connector will only support 'GET'

    .PARAMETER AccessToken
    The AccessToken retrieved by the <Get-ADPAccessToken> function

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

    .PARAMETER Certificate
    The [X509Certificate] object containing the *.pfx

    .EXAMPLE
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new("the path to the *.pfx file", "Password for the *.pfx certificate")

    Invoke-ADPRestMethod -Uri 'https://test-api.adp.com/hr/v2/worker-demographics' -Method 'GET' -AccessToken '0000-0000-0000-0000' -Certifcate $certificate

    Returns the raw JSON data containing all workers from ADP Workforce
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $Url,

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

        [Parameter(Mandatory)]
        [X509Certificate]
        $Certificate
    )

    $headers = @{
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
            Uri = $Url
            Method = $Method
            Headers = $headers
            Proxy = $proxy
            UseBasicParsing = $true
            Certificate = $Certificate
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

    .OUTPUTS
    System.Object[]
    #>
    [OutputType([System.Object[]])]
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

            [System.Collections.Generic.List[object]]$auxFieldObjects = @()

            foreach ($auxField in $department.auxilliaryFields){
                                                
                        $auxFieldObj = [PSCustomObject]@{
                        FieldName = $auxField.NameCode.codeValue
                        FieldCode = $auxField.stringValue
                        }
                        
                        if($auxField.NameCode.codeValue -eq 'manager')
                        {
                            $managerId = $auxField.stringValue
                        }

                        $auxFieldObjects.Add($auxFieldObj)                    
                }

            $departmentObj = [PSCustomObject]@{
                ExternalId = $department.departmentCode.codeValue
                Name = $department.departmentCode.longName
                DisplayName = $department.departmentCode.longName
                ParentExternalId = $department.parentDepartmentCode.codeValue
                #ManagerExternalId = $auxFieldObjects[3].FieldCode
                ManagerExternalId = $managerId
            }
            $listDepartments.Add($departmentObj)
        }
        $listDepartments
    }
}
#EndRegion

#Region Script
$connectionSettings = ConvertFrom-Json $configuration
$splatGetADPDepartments = @{
    BaseUrl = $($connectionSettings.BaseUrl)
    ClientID = $($connectionSettings.ClientID)
    ClientSecret = $($connectionSettings.ClientSecret)
    CertificatePath = $($connectionSettings.CertificatePath)
    CertificatePassword = $($connectionSettings.CertificatePassword)
    ProxyServer = $($connectionSettings.ProxyServer)
}
Get-ADPDepartments @splatGetADPDepartments
#EndRegion

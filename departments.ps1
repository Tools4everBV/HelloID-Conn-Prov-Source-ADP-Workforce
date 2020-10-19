#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Departments
#
# Version: 1.0.4
#####################################################

#Region External functions
function Get-ADPDepartments {
    <#
    .SYNOPSIS
    Retrieves the Departments from ADP Workforce

    .DESCRIPTION
    Retrieves the Departments from ADP Workforce

    .PARAMETER BaseUrl
    The BaseUrl to the ADP Workforce environment. For example: https://test-api.adp.com

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

    .PARAMETER ImportFile
    Use this in combination with the JSON file to test the import of the workers without making API calls to ADP Workforce

    .PARAMETER DepartmentJson
    The location to the 'JSON file containing the departments' on the server where the HelloID agent and provisioning agent are running
    #>
    [CmdletBinding()]
    param (
        [String]
        $BaseUrl,

        [String]
        $ClientID,

        [String]
        $ClientSecret,

        [String]
        $CertificatePath,

        [String]
        $CertificatePassword,

        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ProxyServer,

        [Bool]
        $ImportFile,

        [String]
        $WorkerJson
    )

    try {
        if(!$($ConfigurationSettings.ImportFile)){
            $accessToken = Get-ADPAccessToken -CientID $($ConfigurationSettings.ClientID) -ClientSecret $($configuration.ClientSecret) -CertifcatePath $($ConfigurationSettings.CertificatePath) -CertificatePassword ($ConfigurationSettings.CertificatePassword)
        }
    } catch [System.Net.WebException] {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP AccessToken. Error: '$($ex.Exception.Message)'")
    }

    try {
        if ($($ConfigurationSettings.ImportFile)){
            Get-Content $($ConfigurationSettings.DepartmentJson) | ConvertFrom-Json | ConvertTo-RawDataDepartmentObject | ConvertTo-Json -Depth 100
        } else {
            $splatADPRestMethodParams = @{
                Uri = "$($ConfigurationSettings.BaseUrl)/core/v2/organization-departments"
                Method = 'GET'
                AccessToken = $accessToken
                ProxyServer = $($configurationSettings.ProxyServer)
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
    Before data can be retrieved from the API's, an AccessToken has to obtained. The AccessToken is used for all consecutive calls to the ADP Workforce API's. Tokens only have access to a certain API scope. Default the scope is set to: 'worker-demographics organization-departments'. Data outside this scope from other API's cannot be retrieved

    .PARAMETER CientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret
    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER CertificatePath
    The location to the the private key of the x.509 certificate on the server where the HelloID agent and provisioning agent are running
    Make sure to use the private key for the certificate that's used to generate a ClientID and ClientSecret and for activating the required API's

    .PARAMETER CertificatePassword
    The password for the *.pfx certificate

    .EXAMPLE
    Get-ADPAccessToken -Client 'ADP_Provided_ClientID' -ClientSecret 'ADP_Provided_Secret' -Certifcate 'Customer_ADP_Dev.pfx'

    Retrieves an accesstoken that is authenticated for the 'worker-demographics' and 'organizational-departments' API's
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $CientID,

        [Parameter(Mandatory)]
        [String]
        $ClientSecret,

        [Parameter(Mandatory)]
        [String]
        $CertificatePath,

        [Parameter(Mandatory)]
        [String]
        $CertificatePassword
    )

    $authorization = "$($CientID):$($ClientSecret)"
    $base64String = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))

    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($CertificatePath, $CertificatePassword)

    $headers = @{
        "Cache-Control" = "no-cache"
        "Authorization" = "Basic $base64String"
        "Content-Type" = "application/json"
        "grant_type" = "client_credentials&scope=worker-demographics organizational-departments"
    }

    try {
        $splatRestMethodParameters = @{
            Uri = 'https://accounts.dex.adp.com/auth/oauth/v2/token'
            Method = 'POST'
            Headers = $headers
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
$splatGetADPDepartments = @{
    BaseUrl = $($connectionSettings.BaseUrl)
    ClientID = $($connectionSettings.CientID)
    ClientSecret = $($connectionSettings.ClientSecret)
    CertificatePath = $($connectionSettings.CertificatePath)
    CertificatePassword = $($connectionSettings.CertificatePassword)
    ProxyServer = $($connectionSettings.ProxyServer)
    DepartmentJson = $($connectionSettings.DepartmentJson)
    ImportFile = $($connectionSettings.ImportFile)
}
Get-ADPWorkers @splatGetADPDepartments
#EndRegion

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$c = $configuration | ConvertFrom-Json

$baseUrl = $($c.BaseUrl)
$clientId = $($c.ClientID)
$ClientSecret = $($c.ClientSecret)
$certificatePath = $($c.CertificatePath)
$certificatePassword = $($c.CertificatePassword)
$proxyServer = $($c.ProxyServer)

#Region functions
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
        client_id     = $ClientID
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    try {
        $splatRestMethodParameters = @{
            Uri         = 'https://accounts.eu.adp.com/auth/oauth/v2/token'
            Method      = 'POST'
            Headers     = $headers
            Body        = $body
            Certificate = $certificate
        }
        Invoke-RestMethod @splatRestMethodParameters
    }
    catch {
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
        $Certificate,

        [parameter(Mandatory = $true)]
        [ref]
        $data
    )

    $headers = @{
        "Authorization" = "Bearer $AccessToken"        
    }

    if ([string]::IsNullOrEmpty($ProxyServer)) {
        $proxy = $null
    }
    else {
        $proxy = $ProxyServer
    }


    # Speficy the variables specific to certain endpoints
    # $contentField = The field in the respons content that contains the actual data
    # $paging = A boolean specifying to user paging or not
    switch ($Url) {
        "https://api.eu.adp.com/hr/v2/worker-demographics" {
            $contentField = "workers"
            $paging = $true
        }
        "https://api.eu.adp.com/core/v1/organization-departments" {
            $contentField = "organizationDepartments"
            $paging = $false
        }
    }

    try {
        # Currently only supported for the worker-demographics endpoint
        if ($true -eq $paging) {
            # Fetch the data in smaller chunks, otherwise the API of ADP will return an error 500 Internal Server Error or an error 503 Server / Service unavailable
            $take = 100
            $skip = 0   

            do {
                $result = $null
                $urlOffset = $Url + "?$" + "skip=$skip&$" + "top=$take"
                $skip += $take

                $splatRestMethodParameters = @{
                    Uri             = $urlOffset
                    Method          = $Method
                    Headers         = $headers
                    Proxy           = $proxy
                    UseBasicParsing = $true
                    Certificate     = $Certificate
                }

                $dataset = Invoke-RestMethod @splatRestMethodParameters -ContentType "application/json;charset=utf-8"
                $result = $dataset.$contentField
                if (-not [string]::IsNullOrEmpty($result)) {
                    $data.value.AddRange($result)
                }
            }until( [string]::IsNullOrEmpty($result))
        }
        else {
            $result = $null
            $splatRestMethodParameters = @{
                Uri             = $Url
                Method          = $Method
                Headers         = $headers
                Proxy           = $proxy
                UseBasicParsing = $true
                Certificate     = $Certificate
            }
            $dataset = Invoke-RestMethod @splatRestMethodParameters
            $result = $dataset.$contentField
            if (-not [string]::IsNullOrEmpty($result)) {
                $data.value.AddRange($result)
            }
        }
    }
    catch {
        $data.Value = $null
        Write-Warning "Error querying data from ADP. URI: $Url. Error: $($_.Exception.Message) - $($_.ScriptStackTrace)"
        Throw "A critical error occured. Please see the snapshot log for details..."
    }
}
#EndRegion

# Create Access Token
try {
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificatePath, $certificatePassword)
    $accessToken = Get-ADPAccessToken -ClientID $clientId -ClientSecret $clientSecret -Certificate $certificate
}
catch [System.Net.WebException] {
    $webEx = $PSItem
    $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
    throw "Could not retrieve ADP AccessToken. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'"
}
catch [System.Exception] {
    throw "Could not retrieve ADP AccessToken. Error: '$($_.Exception.Message)'"
}

# Query departments
try {
    Write-Verbose "Querying departments"

    $splatADPRestMethodParams = @{
        Url         = "$BaseUrl/core/v1/organization-departments"
        Method      = 'GET'
        AccessToken = $accessToken.access_token
        ProxyServer = $ProxyServer
        Certificate = $certificate
    }

    $departments = [System.Collections.ArrayList]::new()
    Invoke-ADPRestMethod @splatADPRestMethodParams ([ref]$departments)

    $departments | Add-Member -MemberType NoteProperty -Name "customFields" -Value $null -Force
    $departments | ForEach-Object {
        if ($null -ne $_.auxilliaryFields) {
            # Transform auxilliaryFields on departments
            $properties = @(
                foreach ($attribute in $_.auxilliaryFields) {
                    @{ Name = "$($attribute.nameCode.codeValue)"; Expression = { "$($attribute.stringValue)" }.GetNewClosure() }
                }
            )
            $departmentAuxilliaryFields = $_ | Select-Object -Property $properties
            $_.customFields = $departmentAuxilliaryFields
        }
    }

    Write-Information "Successfully queried departments. Result: $($departments.Count)"
}
catch [System.Net.WebException] {
    $errorObj = ($($_.ErrorDetails.Message) | ConvertFrom-Json).response
    throw "Could not retrieve ADP Departments. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'"
}
catch [System.Exception] {
    throw "Could not retrieve ADP Departments. Error: '$($_.Exception.Message)'"
}

try{
    # Enhance department object and export
    $departments | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "Name" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "ManagerExternalId" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "ParentExternalId" -Value $null -Force
    $departments | ForEach-Object {
        # Set required fields for HelloID
        $_.ExternalId = $_.departmentCode.codeValue
        $_.DisplayName = $_.departmentCode.longName
        $_.Name = $_.departmentCode.longName
        $_.ManagerExternalId = $_.customFields.manager
        $_.ParentExternalId = $_.parentDepartmentCode.codeValue

        # Sanitize and export the json
        $department = $_ | ConvertTo-Json -Depth 10
        $department = $department.Replace("._", "__")

        Write-Output $department
    }
}catch{
    throw $_
}
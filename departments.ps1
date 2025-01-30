#####################################################
# HelloID-Conn-Prov-Source-ADP-Workforce-Departments
#
# Version: 3.0.0
#####################################################

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($c.isDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$c = $configuration | ConvertFrom-Json

$baseUrl = $($c.BaseUrl)
$clientId = $($c.ClientID)
$clientSecret = $($c.ClientSecret)
$certificatePath = $($c.CertificatePath)
$certificateBase64 = $c.CertificateBase64
$certificatePassword = $($c.CertificatePassword)
$proxyServer = $($c.ProxyServer)

Write-Information "Start department import: Base URL '$baseUrl', Proxy server '$proxyServer', Client ID '$clientId'"

#region functions
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
            ScriptStackTrace      = $ErrorObject.ScriptStackTrace
            ErrorMessage          = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorMessage = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $httpErrorObj.ErrorMessage = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        }
        Write-Output $httpErrorObj
    }
}

function Get-ErrorMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $errorMessage = [PSCustomObject]@{
            VerboseErrorMessage = $null
            AuditErrorMessage   = $null
        }

        if ( $($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $httpErrorObject = Resolve-HTTPError -Error $ErrorObject

            $errorMessage.VerboseErrorMessage = $httpErrorObject.ErrorMessage

            $errorMessage.AuditErrorMessage = $httpErrorObject.ErrorMessage
        }

        # If error message empty, fall back on $ex.Exception.Message
        if ([String]::IsNullOrEmpty($errorMessage.VerboseErrorMessage)) {
            $errorMessage.VerboseErrorMessage = $ErrorObject.Exception.Message
        }
        if ([String]::IsNullOrEmpty($errorMessage.AuditErrorMessage)) {
            $errorMessage.AuditErrorMessage = $ErrorObject.Exception.Message
        }

        Write-Output $errorMessage
    }
}

function Get-ADPAccessToken {
    <#
.SYNOPSIS
Retrieves an AccessToken from the ADP API using the standard <Invoke-RestMethod> cmdlet

.DESCRIPTION
The ADP Workforce API's uses OAuth for authentication\authorization.
Before data can be retrieved from the API's, an AccessToken has to obtained. The AccessToken is used for all consecutive calls to the ADP Workforce API's. 
Tokens only have access to a certain API scope. Default the scope is set to: 'workers organization-departments'. 
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
        $clientSecret,

        [X509Certificate]
        $Certificate
    )

    $headers = @{
        "content-type" = "application/x-www-form-urlencoded"
    }

    $body = @{
        client_id     = $ClientID
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }

    try {
        $splatRestMethodParameters = @{
            Uri         = "$BaseUrl/auth/oauth/v2/token"
            Method      = 'POST'
            Headers     = $headers
            Body        = $body
            Certificate = $certificate
        }
        Invoke-RestMethod @splatRestMethodParameters -verbose:$false
    }
    catch {
        throw $PSItem
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

Invoke-ADPRestMethod -Uri 'https://test-api.adp.com/hr/v2/workers' -Method 'GET' -AccessToken '0000-0000-0000-0000' -Certifcate $certificate

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
    # $contentField = The field in the response content that contains the actual data
    # $paging = A boolean specifying to user paging or not
    switch ($Url) {
        "https://api.eu.adp.com/hr/v2/workers" {
            $contentField = "workers"
            $paging = $true
        }
        "https://api.eu.adp.com/core/v1/organization-departments" {
            $contentField = "organizationDepartments"
            $paging = $false
        }
    }

    try {
        # Currently only supported for the workers endpoint
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

                $datasetJson = Invoke-WebRequest @splatRestMethodParameters -verbose:$false

                if (-not[string]::IsNullOrEmpty($certificateBase64)) {    
                    $dataset = $datasetJson.content | ConvertFrom-Json
                }
                elseif (-not [string]::IsNullOrEmpty($certificatePath)) {
                    $datasetCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::UTF8.GetBytes($datasetJson.content))
                    $dataset = $datasetCorrected | ConvertFrom-Json
                }
                else {
                    Throw "No certificate configured"
                }

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
        
            $datasetJson = Invoke-WebRequest @splatRestMethodParameters -verbose:$false

            if (-not[string]::IsNullOrEmpty($certificateBase64)) {    
                $dataset = $datasetJson.content | ConvertFrom-Json
            }
            elseif (-not [string]::IsNullOrEmpty($certificatePath)) {
                $datasetCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::UTF8.GetBytes($datasetJson.content))
                $dataset = $datasetCorrected | ConvertFrom-Json
            }
            else {
                Throw "No certificate configured"
            }

            $result = $dataset.$contentField
            if (-not [string]::IsNullOrEmpty($result)) {
                $data.value.AddRange($result)
            }
        }
    }
    catch {
        $data.Value = $null
        $ex = $PSItem
        $errorMessage = Get-ErrorMessage -ErrorObject $ex

        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($($errorMessage.VerboseErrorMessage))"  
        throw "Could not query data from ADP. URI: $($splatRestMethodParameters.Uri). Error Message: $($errorMessage.AuditErrorMessage)"
    }
}
#endregion functions

# Create Access Token
try {
    if (-not[string]::IsNullOrEmpty($certificateBase64)) {
        # Use for cloud PowerShell flow
        $RAWCertificate = [system.convert]::FromBase64String($certificateBase64)
        $Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($RAWCertificate, $certificatePassword)
    }
    elseif (-not [string]::IsNullOrEmpty($certificatePath)) {
        # Use for local machine with certificate file
        $Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certificatePath, $certificatePassword)
    }
    else {
        Throw "No certificate configured"
    }
    $accessToken = Get-ADPAccessToken -ClientID $clientId -ClientSecret $clientSecret -Certificate $certificate
}
catch {
    $ex = $PSItem
    $errorMessage = Get-ErrorMessage -ErrorObject $ex

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($($errorMessage.VerboseErrorMessage))"  
    throw "Could not create ADP AccessToken. Error Message: $($errorMessage.AuditErrorMessage)"
}

# Query Departments
try {
    Write-Verbose "Querying Departments"

    $splatADPRestMethodParams = @{
        Url         = "$BaseUrl/core/v1/organization-departments"
        Method      = 'GET'
        AccessToken = $accessToken.access_token
        ProxyServer = $ProxyServer
        Certificate = $certificate
    }

    $departments = [System.Collections.ArrayList]::new()
    Invoke-ADPRestMethod @splatADPRestMethodParams ([ref]$departments)

    # Only use of active departments
    $departments = $departments | Where-Object { $_.activeIndicator -eq $true }
    # Sort on ExternalId (to make sure the order is always the same)
    $departments = $departments | Sort-Object -Property { $_.departmentCode.codeValue }

    $departments | Add-Member -MemberType NoteProperty -Name "customFields" -Value $null -Force
    $departments | ForEach-Object {
        if (($_.auxilliaryFields | Measure-Object).Count -ge 1) {
            # Transform auxilliaryFields on departments
            $customFieldObject = [PSCustomObject]@{}

            foreach ($attribute in $_.auxilliaryFields) {                
                # Add a property for each field in object
                $customFieldObject | Add-Member -MemberType NoteProperty -Name "$($attribute.ItemId)" -Value "$($attribute.stringValue)" -Force                
            }
            $_.customFields = $customFieldObject
            # Remove unneccesary fields from  object (to avoid unneccesary large objects and confusion when mapping)
            # Remove auxilliaryFields ,since the data is transformed into seperate object
            $_.PSObject.Properties.Remove('auxilliaryFields')
        }
    }

    Write-Information "Succesfully queried Departments. Result count: $($departments.count)"
}
catch {
    $ex = $PSItem
    $errorMessage = Get-ErrorMessage -ErrorObject $ex

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($($errorMessage.VerboseErrorMessage))"  
    throw "Could not query Departments. Error Message: $($errorMessage.AuditErrorMessage)"
}

try {
    Write-Verbose 'Enhancing and exporting department objects to HelloID'

    # Set counter to keep track of actual exported person objects
    $exportedDepartments = 0

    # Enhance department model with required properties
    $departments | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "Name" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "ManagerExternalId" -Value $null -Force
    $departments | Add-Member -MemberType NoteProperty -Name "ParentExternalId" -Value $null -Force
    
    $departments | ForEach-Object {
        # Create department object to log on which department the error occurs
        $departmentInProcess = $_

        # Set required fields for HelloID
        $_.ExternalId = $_.departmentCode.codeValue
        $_.DisplayName = $_.departmentCode.longName
        $_.ManagerExternalId = $_.customFields.afd_manager
        $_.ParentExternalId = $_.parentDepartmentCode.codeValue

        # Sanitize and export the json
        $department = $_ | ConvertTo-Json -Depth 10
        $department = $department.Replace("._", "__")

        Write-Output $department

        # Updated counter to keep track of actual exported department objects
        $exportedDepartments++
    }
    Write-Information "Succesfully enhanced and exported department objects to HelloID. Result count: $($exportedDepartments)"
    Write-Information "Department import completed"
}
catch {
    $ex = $PSItem
    $errorMessage = Get-ErrorMessage -ErrorObject $ex

    # If debug logging is toggled, log on which person and line the error occurs
    if ($c.isDebug -eq $true) {
        Write-Warning "Error occurred for person [$($personInProcess.ExternalId)]. Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($errorMessage.VerboseErrorMessage)"
    }
    
    throw "Could not enhance and export department objects to HelloID. Error Message: $($errorMessage.AuditErrorMessage)"
}

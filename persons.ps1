#####################################################
# HelloID-Conn-Prov-Source-ADP-Workforce
#
# Version: 2.0.1
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

Write-Information "Start person import: Base URL '$baseUrl', Proxy server '$proxyServer', Client ID '$clientId'"

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
    # $contentField = The field in the response content that contains the actual data
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

                $datasetJson = Invoke-WebRequest @splatRestMethodParameters -verbose:$false
                $datasetCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(28591).GetBytes($datasetJson.content))
                $dataset = $datasetCorrected | ConvertFrom-Json

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
            $datasetCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(28591).GetBytes($datasetJson.content))
            $dataset = $datasetCorrected | ConvertFrom-Json

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
    elseif (-not [string]::IsNullOrEmpty($certificatePathertificatePath)) {
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

# Query Persons
try {
    Write-Verbose "Querying Persons"

    $splatADPRestMethodParams = @{
        Url         = "$BaseUrl/hr/v2/worker-demographics" 
        Method      = 'GET'
        AccessToken = $accessToken.access_token
        ProxyServer = $ProxyServer
        Certificate = $certificate
    }

    $persons = [System.Collections.ArrayList]::new()
    Invoke-ADPRestMethod @splatADPRestMethodParams ([ref]$persons)

    # Sort on Medewerker (to make sure the order is always the same)
    $persons = $persons | Sort-Object -Property { $_.workerID.idValue }

    Write-Information "Succesfully queried Persons. Result count: $($persons.count)"
}
catch {
    $ex = $PSItem
    $errorMessage = Get-ErrorMessage -ErrorObject $ex

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($($errorMessage.VerboseErrorMessage))"  
    throw "Could not query Persons. Error Message: $($errorMessage.AuditErrorMessage)"
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

    # Sort on ExternalId (to make sure the order is always the same)
    $departments = $departments | Sort-Object -Property { $_.departmentCode.codeValue }

    $departments | Add-Member -MemberType NoteProperty -Name "customFields" -Value ([PSCustomObject]@{}) -Force
    $departments | ForEach-Object {
        if (($_.auxilliaryFields | Measure-Object).Count -ge 1) {
            # Transform auxilliaryFields on departments
            foreach ($attribute in $_.auxilliaryFields) {
                # Add a property for each field in object
                $_.customFields | Add-Member -MemberType NoteProperty -Name "$($attribute.nameCode.codeValue)" -Value "$($attribute.stringValue)" -Force
            }

            # Remove unneccesary fields from  object (to avoid unneccesary large objects and confusion when mapping)
            # Remove auxilliaryFields ,since the data is transformed into seperate object
            $_.PSObject.Properties.Remove('auxilliaryFields')
        }
    }

    # Group on ExternalId (to match to employments and positions)
    $departmentsGrouped = $departments | Group-Object -Property { $_.departmentCode.codeValue } -AsString -AsHashTable

    Write-Information "Succesfully queried Departments. Result count: $($departments.count)"
}
catch {
    $ex = $PSItem
    $errorMessage = Get-ErrorMessage -ErrorObject $ex

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($($errorMessage.VerboseErrorMessage))"  
    throw "Could not query Departments. Error Message: $($errorMessage.AuditErrorMessage)"
}

# $persons = $persons | Where-Object { $_.workerID.idValue -eq "000224" }
try {
    Write-Verbose 'Enhancing and exporting person objects to HelloID'

    # Set counter to keep track of actual exported person objects
    $exportedPersons = 0

    # Enhance person model with required properties
    $persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $null -Force

    # Enhance person model with additional properties
    $persons | Add-Member -MemberType NoteProperty -Name "BusinessEmail" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "BusinessLandLine" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "BusinessMobile" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "customFields" -Value ([PSCustomObject]@{}) -Force

    $persons | ForEach-Object {
        # Create person object to log on which person the error occurs
        $personInProcess = $_

        # Set required fields for HelloID
        $_.ExternalId = $_.workerID.idValue

        # Include ExternalId in DisplayName of HelloID Raw Data
        $_.DisplayName = $_.person.legalName.formattedName + " ($($_.ExternalId))"

        if (($_.businessCommunication | Measure-Object).Count -ge 1) {
            # The emails array (if not empty) always contains 1 item
            if (($_.businessCommunication.emails | Measure-Object).Count -ge 1) {
                $_.BusinessEmail = $_.businessCommunication.emails[0].emailUri
            }

            # The landlines array (if not empty) always contains 1 item
            if (($_.businessCommunication.landLines | Measure-Object).Count -ge 1) {
                $_.BusinessLandLine = $_.businessCommunication.landLines[0].formattedNumber
            }

            # The mobiles array (if not empty) always contains 1 item
            if (($worker.businessCommunication.mobiles | Measure-Object).Count -ge 1) {
                $_.BusinessMobile = $_.businessCommunication.mobiles[0].formattedNumber
            }

            # Remove unneccesary fields from  object (to avoid unneccesary large objects)
            # Remove businessCommunication, since the data is transformed into seperate properties
            $_.PSObject.Properties.Remove('businessCommunication')
        }

        # Transform CustomFields on person
        if (($_.customFieldGroup | Measure-Object).Count -ge 1) {
            if (($_.customFieldGroup.stringFields | Measure-Object).Count -ge 1) {
                foreach ($attribute in $_.customFieldGroup.stringFields) {
                    # Add a property for each field in object
                    $_.customFields | Add-Member -MemberType NoteProperty -Name "$($attribute.nameCode.codeValue)" -Value "$($attribute.stringValue)" -Force
                }
            }

            # Remove unneccesary fields from  object (to avoid unneccesary large objects)
            # Remove customFieldGroup, since the data is transformed into customFields property
            $_.PSObject.Properties.Remove('customFieldGroup')
        }

        $contractsList = [System.Collections.ArrayList]::new()

        # Enhance assignments for person
        if (($_.workAssignments | Measure-Object).Count -ge 1) {
            foreach ($assignment in $_.workAssignments) {
                # Set required fields for HelloID
                $assignmentExternalId = "$($_.workerID.idValue)" + "_$($assignment.itemID)"
                $assignment | Add-Member -MemberType NoteProperty -Name "externalId" -Value $assignmentExternalId -Force

                # Transform CustomFields on assigment
                $assignment | Add-Member -MemberType NoteProperty -Name "customFields" -Value ([PSCustomObject]@{}) -Force
                if (($assignment.customFieldGroup | Measure-Object).Count -ge 1) {
                    if (($assignment.customFieldGroup.stringFields | Measure-Object).Count -ge 1) {
                        foreach ($attribute in $assignment.customFieldGroup.stringFields) {
                            # Add a property for each field in object
                            $_.customFields | Add-Member -MemberType NoteProperty -Name "$($attribute.nameCode.codeValue)" -Value "$($attribute.stringValue)" -Force
                        }
                    }

                    # Remove unneccesary fields from  object (to avoid unneccesary large objects)
                    # Remove customFieldGroup, since the data is transformed into customFields property
                    $assignment.PSObject.Properties.Remove('customFieldGroup')
                }

                # Assignments may contain multiple managers (per assignment). There's no way to specify which manager is primary
                # We always select the first one in the array
                if (($assignment.reportsTo | Measure-Object).Count -ge 1) {
                    $manager = ($assignment.reportsTo | Sort-Object -Descending)[0]
                    $assignment | Add-Member -MemberType NoteProperty -Name "manager" -Value $manager -Force
                }

                if (($assignment.homeOrganizationalUnits | Measure-Object).Count -ge 1) {
                    # Assignments may contain multiple organizationalUnits (per assignment). There's no way to specify which department is primary
                    # We always select the last one in the array
                    $organizationalUnit = ($assignment.homeOrganizationalUnits | Sort-Object -Descending)[-1].nameCode

                    # Enhance assignments as department for extra information, such as: company
                    if (($organizationalUnit.codeValue | Measure-Object).Count -ge 1) {
                        $department = $departmentsGrouped["$($organizationalUnit.codeValue)"]
                        if (($department | Measure-Object).Count -ge 1) {
                            # It is possible there are multiple department with the same code, we always select the last on in the array
                            $organizationalUnit = ($department | Sort-Object -Descending)[-1]
                        }
                    }

                    $assignment | Add-Member -MemberType NoteProperty -Name "organizationalUnit" -Value $organizationalUnit -Force
                }

                if (($assignment.AssignmentCostCenters | Measure-Object).Count -ge 1) {
                    # Assignments may contain multiple CostCenters (per assignment). There's no way to specify which department is primary
                    # We always select the first one in the array
                    $costCenter = ($assignment.AssignmentCostCenters | Sort-Object -Descending)[0]
                    $assignment | Add-Member -MemberType NoteProperty -Name "costCenter" -Value $costCenter -Force
                }

                # Add employment only data to contracts (in case of employments without positions)
                [Void]$contractsList.Add($assignment)
            }

            # Remove unneccesary fields from  object (to avoid unneccesary large objects)
            # Remove workAssignments, since the data is transformed into the contractsList object
            $_.PSObject.Properties.Remove('workAssignments')
        }

        # Add Contracts to person
        if (($contractsList | Measure-Object).Count -ge 1) {
            ## This example can be used by the consultant if you want to filter out persons with an empty array as contract
            ## *** Please consult with the Tools4ever consultant before enabling this code. ***
            # if ($contractsList.Count -eq 0) {
            #     Write-Warning "Excluding person from export: $($_.Medewerker). Reason: Contracts is an empty array"
            #     return
            # }
            # else {
            $_.Contracts = $contractsList
            # }
        }
        ## This example can be used by the consultant if the date filters on the person/employment/positions do not line up and persons without a contract are added to HelloID
        ## *** Please consult with the Tools4ever consultant before enabling this code. ***    
        # else {
        #     Write-Warning "Excluding person from export: $($_.Medewerker). Reason: Person has no contract data"
        #     return
        # }

        # Sanitize and export the json
        $person = $_ | ConvertTo-Json -Depth 10 -Compress
        $person = $person.Replace("._", "__")

        Write-Output $person

        # Updated counter to keep track of actual exported person objects
        $exportedPersons++
    }
    Write-Information "Succesfully enhanced and exported person objects to HelloID. Result count: $($exportedPersons)"
    Write-Information "Person import completed"
}
catch {
    $ex = $PSItem
    $errorMessage = Get-ErrorMessage -ErrorObject $ex

    # If debug logging is toggled, log on which person and line the error occurs
    if ($c.isDebug -eq $true) {
        Write-Warning "Error occurred for person [$($personInProcess.ExternalId)]. Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($errorMessage.VerboseErrorMessage)"
    }
    
    throw "Could not enhance and export person objects to HelloID. Error Message: $($errorMessage.AuditErrorMessage)"
}
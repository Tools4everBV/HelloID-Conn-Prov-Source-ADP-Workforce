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

# Query persons
try {
    Write-Verbose "Querying persons"
    $splatADPRestMethodParams = @{
        Url         = "$BaseUrl/hr/v2/worker-demographics" 
        Method      = 'GET'
        AccessToken = $accessToken.access_token
        ProxyServer = $ProxyServer
        Certificate = $certificate
    }
    
    $persons = [System.Collections.ArrayList]::new()
    Invoke-ADPRestMethod @splatADPRestMethodParams ([ref]$persons)

    Write-Information "Successfully queried persons. Result: $($persons.Count)"
}
catch [System.Net.WebException] {
    $webEx = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($webEx)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $errorObj = ($reader.ReadToEnd() | ConvertFrom-Json).message
    throw "Could not retrieve ADP Workers. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'"
}
catch [System.Exception] {
    throw "Could not retrieve ADP Workers. Error: '$($_.Exception.Message)'"
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
    $departmentsGrouped = $departments | Group-Object -Property { $_.departmentCode.codeValue } -AsString -AsHashTable

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
    # Enhance person object and export
    $persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "BusinessEmail" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "BusinessLandLine" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "BusinessMobile" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "customFields" -Value $null -Force
    $persons | ForEach-Object {
        # Set required fields for HelloID
        $_.ExternalId = $_.workerID.idValue

        # If ExternalId is empty, skip record
        if ([string]::IsNullOrWhiteSpace($_.ExternalId)) {
            return
        }
        else {
            # Include ExternalId in DisplayName of HelloID Raw Data
            $_.DisplayName = $_.person.legalName.formattedName + " ($($_.ExternalId))" 

            if ($null -ne $_.businessCommunication) {
                # The emails array (if not empty) always contains 1 item
                if ($null -ne $_.businessCommunication.emails) {
                    $_.BusinessEmail = $_.businessCommunication.emails[0].emailUri
                }

                # The landlines array (if not empty) always contains 1 item
                if ($null -ne $_.businessCommunication.landLines) {
                    $_.BusinessLandLine = $_.businessCommunication.landLines[0].formattedNumber
                }

                # The mobiles array (if not empty) always contains 1 item
                if ($null -ne $worker.businessCommunication.mobiles) {
                    $_.BusinessMobile = $_.businessCommunication.mobiles[0].formattedNumber
                }
            }

            # Transform CustomFields on person
            if ($null -ne $_.customFieldGroup) {
                $properties = @(
                    foreach ($attribute in $_.customFieldGroup.stringFields) {
                        @{ Name = "$($attribute.nameCode.codeValue)"; Expression = { "$($attribute.stringValue)" }.GetNewClosure() }
                    }
                )
                $personCustomFields = $_.customFieldGroup | Select-Object -Property $properties

                $_.customFields = $personCustomFields
            }
            
            $contractsList = [System.Collections.ArrayList]::new()
            if ($null -ne $_.workAssignments) {
                foreach ($assignment in $_.workAssignments) {
                    # Set required fields for HelloID
                    $assignmentExternalId = "$($_.workerID.idValue)" + "_$($assignment.itemID)"
                    $assignment | Add-Member -MemberType NoteProperty -Name "externalId" -Value $assignmentExternalId -Force

                    # Transform CustomFields on assigment
                    if ($null -ne $assignment.customFieldGroup) {
                        $properties = @(
                            foreach ($attribute in $assignment.customFieldGroup.stringFields) {
                                @{ Name = "$($attribute.nameCode.codeValue)"; Expression = { "$($attribute.stringValue)" }.GetNewClosure() }
                            }
                        )
                        $assignmentCustomFields = $assignment.customFieldGroup | Select-Object -Property $properties
                        $assignment | Add-Member -MemberType NoteProperty -Name "customFields" -Value $assignmentCustomFields -Force
                    }

                    # Assignments may contain multiple managers (per assignment). There's no way to specify which manager is primary
                    # We always select the first one in the array
                    if ($null -ne $assignment.reportsTo) {
                        $manager = ($assignment.reportsTo | Sort-Object -Descending)[0]
                        $assignment | Add-Member -MemberType NoteProperty -Name "manager" -Value $manager -Force
                    }

                    if ($null -ne $assignment.homeOrganizationalUnits) {
                        # Assignments may contain multiple organizationalUnits (per assignment). There's no way to specify which department is primary
                        # We always select the last one in the array
                        $organizationalUnit = ($assignment.homeOrganizationalUnits | Sort-Object -Descending)[-1].nameCode

                        # Enhance assignments as department for extra information, such as: company
                        if ($null -ne $organizationalUnit.codeValue) {
                            $department = $departmentsGrouped["$($organizationalUnit.codeValue)"]
                            # It is possible there are multiple department with the same code, we always select the last on in the array
                            $organizationalUnit = ($department | Sort-Object -Descending)[-1]
                        }

                        $assignment | Add-Member -MemberType NoteProperty -Name "organizationalUnit" -Value $organizationalUnit -Force
                    }          

                    if ($null -ne $assignment.AssignmentCostCenters) {
                        # Assignments may contain multiple CostCenters (per assignment). There's no way to specify which department is primary
                        # We always select the first one in the array
                        $costCenter = ($assignment.AssignmentCostCenters | Sort-Object -Descending)[0]
                        $assignment | Add-Member -MemberType NoteProperty -Name "costCenter" -Value $costCenter -Force
                    }

                    # Remove unneccesary fields from assignment object (to avoid unneccesary large assignment objects)
                    # Remove customFieldGroup, since the data in here is stored in the custom field: customFields
                    if ($null -ne $assignment.customFieldGroup) {
                        $assignment.PSObject.Properties.Remove('customFieldGroup')
                    }

                    # Add employment only data to contracts (in case of employments without positions)
                    [Void]$contractsList.Add($assignment)
                }
            }
            else {
                Write-Warning "No assignment found for person: $($_.ExternalId)"  
            }
        }

        # Add Contracts to person
        if ($null -ne $contractsList) {
            $_.Contracts = $contractsList
        }
        else {
            ### This example can be used by the consultant if the date filters on the person/employment/positions do not line up and persons without a contract are added to HelloID
            ### *** Please consult with the Tools4ever consultant before enabling this code. ***
            # Write-Warning "Excluding person from export: $($_.Medewerker). Reason: Person has no contract data"
            # return
        }

        # Remove unneccesary fields from person object (to avoid unneccesary large person objects)
        # Remove businessCommunication, since the data in here is stored in custom fields
        if ($null -ne $_.businessCommunication) {
            $_.PSObject.Properties.Remove('businessCommunication')
        }
        # Remove customFieldGroup, since the data in here is stored in the custom field: customFields
        if ($null -ne $_.customFieldGroup) {
            $_.PSObject.Properties.Remove('customFieldGroup')
        }
        # Remove customFieldGroup, since the data in here is stored in the custom field: contracts
        if ($null -ne $_.workAssignments) {
            $_.PSObject.Properties.Remove('workAssignments')
        }

        # Sanitize and export the json
        $person = $_ | ConvertTo-Json -Depth 10
        $person = $person.Replace("._", "__")

        Write-Output $person
    }
}catch{
    throw $_
}
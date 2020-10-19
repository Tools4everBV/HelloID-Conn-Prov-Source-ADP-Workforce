#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Persons
#
# Version: 1.0.4
#####################################################

#Region External functions
function Get-ADPWorkers {
    <#
    .SYNOPSIS
    Retrieves the Workers and WorkerAssignments from ADP Workforce

    .DESCRIPTION
    Retrieves the Workers and WorkerAssignments from ADP Workforce

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

    .PARAMETER WorkerJson
    The location to the 'JSON file containing the workers' on the server where the HelloID agent and provisioning agent are running.
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
        if(!$ImportFile){
            $accessToken = Get-ADPAccessToken -CientID $ClientID -ClientSecret $ClientSecret -CertifcatePath $CertificatePath -CertificatePassword $CertificatePassword
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
        if ($ImportFile){
            Get-Content $WorkerJson | ConvertFrom-Json | ConvertTo-RawDataPersonObject | ConvertTo-Json -Depth 100
        } else {
            $splatADPRestMethodParams = @{
                Uri = "$BaseUrl/hr/v2/worker-demographics"
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
        $PSCmdlet.WriteError("Could not retrieve ADP Workers. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'")
    } catch [System.Exception] {
        $ex = $PSItem
        $PSCmdlet.WriteWarning("Could not retrieve ADP Workers. Error: '$($ex.Exception.Message)'")
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

    $authorization = "$($CientID):$($clientSecretString)"
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

function ConvertTo-RawDataPersonObject {
    <#
    .SYNOPSIS
    Converts the ADP Worker object to a raw data object

    .DESCRIPTION
    Converts the ADP Worker object to a [RawDataPersonObject] that can be imported into HelloID

    .PARAMETER Workers
    The list of Workers from ADP Workforce

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
        $Workers
    )
    process {
        [System.Collections.Generic.List[object]]$listWorkers = @()

        foreach ($worker in $workers.workers) {

            if ($null -ne $worker.customFieldGroup.stringFields){
                $customFieldsWorkerProperties = Select-CustomFields -CustomFields $worker.customFieldGroup
            }

            if ($null -ne $worker.businessCommunication){

                # The emails array (if not empty) always contains 1 item
                if ($null -ne $worker.businessCommunication.emails){
                    $EmailAddress = $worker.businessCommunication.emails[0].emailUri
                }

                # The landlines array (if not empty) always contains 1 item
                if ($null -ne $worker.businessCommunication.landLines){
                    $PhoneNumberFixed = $worker.businessCommunication.landLines[0].formattedNumber
                }

                # The mobiles array (if not empty) always contains 1 item
                if ($null -ne $worker.businessCommunication.mobiles){
                    $PhoneNumberMobile = $worker.businessCommunication.mobiles[0].formattedNumber
                }
            }

            $workerObj = [PSCustomObject]@{
                ExternalId = $worker.workerID.idValue
                DisplayName = $worker.person.legalName.formattedName
                AssocciateOID = $worker.associateOID
                WorkerID = $worker.workerID.idValue
                Status = $worker.workerStatus.statusCode
                Personal = @{
                    BirthDate = $worker.person.birthDate
                    BirthPlace = $worker.person.birthPlace.cityName
                    Name = @{
                        legalName = @{
                            FamilyName = $worker.person.legalName.familyName1
                            FamilyNamePrefix = $worker.person.legalName.familyName1Prefix
                            FormattedName = $worker.person.legalName.formattedName
                            GivenName = $worker.person.legalName.givenName
                            Initials = $worker.person.legalName.initials
                            NickName = $worker.person.legalName.nickName
                        }
                        PreferredSalutation = @{
                            Salutation = $worker.person.legalName.preferredSalutation
                        }
                    }
                }
                BusinessCommunication = @{
                    EmailAddress = $EmailAddress
                    LandLine = $PhoneNumberFixed
                    Mobile = $PhoneNumberMobile
                }
                Gender = $worker.person.genderCode.codeValue
                OriginalHireDate = $worker.WorkerDates.originalHireDate
                TerminationDate = $worker.WorkerDates.terminationDate
                RetirementDate = $worker.WorkerDates.retirementDate
                CustomFields = $customFieldsWorkerProperties
                Contracts = $contracts
            }

            if ($null -ne $worker.workAssignments){
                [System.Collections.Generic.List[object]]$contracts = @()

                foreach ($assignment in $worker.workAssignments){

                    # Assignments may contain multiple managers (per assignment). There's no way to specify which manager is primary
                    # We always select the first one in the array
                    if ($null -ne $assignment.reportsTo){
                        for ($i = 0; $i -lt $assignment.reportsTo.Length; $i++) {
                            $manager = @{
                                FormattedName = $assignment.reportsTo[0].reportsToWorkerName.formattedName
                                WorkerID = $assignment.reportsTo[0].workerID.idValue
                                AssociateOID = $assignment.reportsTo[0].associateOID
                                RelationShipCode = $assignment.reportsTo[0].reportsToRelationshipCode.longName
                            }
                        }
                    }

                    if ($null -ne $assignment.customFieldGroup){
                        $customFieldsAssignmentProperties = Select-CustomFields -CustomFields $assignment.customFieldGroup
                    }

                    if ($null -ne $assignment.homeOrganizationalUnits){
                        for ($i = 0; $i -lt $assignment.homeOrganizationalUnits.Length; $i++) {
                            $homeOrganizationalUnit = @{
                                Name = $assignment.homeOrganizationalUnits[$i].nameCode.longName
                                Code = $assignment.homeOrganizationalUnits[$i].nameCode.codeValue
                            }
                        }
                    }

                    $assignmentObj = [PSCustomObject]@{
                        PrimaryIndicator = $assignment.primaryIndicator
                        ActualStartDate = $assignment.actualStartDate
                        TerminationDate = $assignment.terminationDate
                        ExpectedTerminationDate = $assignment.expectedTerminationDate
                        WorkerTypeCode = $assignment.workerTypeCode
                        ManagementPosition = $assignment.managementPositionIndicator
                        PositionId = $assignment.positionID
                        PositionTitle = $assignment.PositionTitle
                        HomeOrganizationalUnit = $homeOrganizationalUnit
                        #HomeWorkLocation = $assignment.homeWorkLocation.nameCode #Object Empty
                        #AssignedWorkLocation = $assignment.assignedWorkLocations #Object Empty
                        ItemId = $assignment.itemID
                        PayrollGroupCode = $assignment.payrollGroupCode
                        PayrollFileNumber = $assignment.payrollFileNumber
                        JobCode = $assignment.jobCode.longName
                        StandardHours = $assignment.standardHours.hoursQuantity
                        StandardHoursQuantity = $assignment.standardHours.unitCode.longName
                        #AssignmentCostCenters = $assignment.assignmentCostCenters #Object Empty
                        ReportsTo = $manager
                        CustomFields = $customFieldsAssignmentProperties
                    }
                    $contracts.Add($assignmentObj)
                }
                $listWorkers.Add($workerObj)
            }
        }
        $listWorkers
    }
}

function Select-CustomFields {
    <#
    .SYNOPSIS
    Flattens the [worker.customFieldGroup] array object

    .DESCRIPTION
    Flattens the [worker.customFieldGroup] array

    .PARAMETER CustomFields
    The StringFields array containing the customFields for a worker or assignment

    .EXAMPLE
    PS C:\> $worker.customFieldGroup

    stringFields
    ------------
    {@{nameCode=; stringValue=Nikolai}, @{nameCode=; stringValue=}, @{nameCode=; stringValue=RTM}, @{nameCode=; stringValue=tiva}...}

    PS C:\> Select-CustomFields -CustomFields $worker.customFieldGroup

    partnerFamilyName1        : Nikolai
    partnerFamilyName1Prefix  :
    partnerInitials           : RTM
    naamSamenstelling         : tiva
    samengesteldeNaam         : NDS Burghout
    loginName                 :
    verwijzendWerknemernummer : P001
    leefvormCode              :

    Returns a PSCustomObject containing the customFields from the [worker.customFieldGroup] object
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSObject]
        $CustomFields
    )

    $properties = @(
        foreach ($attribute in $CustomFields.stringFields) {
            @{ Name = "$($attribute.nameCode.codeValue)"; Expression = { "$($attribute.stringValue)" }.GetNewClosure()}
        }
    )
    $CustomFields | Select-Object -Property $properties
}
#EndRegion

#Region Script
$connectionSettings = ConvertFrom-Json $configuration
$splatGetADPWorkers = @{
    BaseUrl = $($connectionSettings.BaseUrl)
    ClientID = $($connectionSettings.CientID)
    ClientSecret = $($connectionSettings.ClientSecret)
    CertificatePath = $($connectionSettings.CertificatePath)
    CertificatePassword = $($connectionSettings.CertificatePassword)
    ProxyServer = $($connectionSettings.ProxyServer)
    WorkerJson = $($connectionSettings.WorkerJson)
    ImportFile = $($connectionSettings.ImportFile)
}
Get-ADPWorkers @splatGetADPWorkers
#EndRegion

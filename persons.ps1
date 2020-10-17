#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Persons
# 
# Version: 1.0.2
#####################################################

#Region External functions
function Get-ADPWorkers {
    <#
    .SYNOPSIS
    Retrieves the Workers and WorkerAssignments from ADP Workforce

    .DESCRIPTION
    Retrieves the Workers and WorkerAssignments from ADP Workforce

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
            Get-Content $($ConfigurationSettings.JsonFile) | ConvertFrom-Json | ConvertTo-RawDataPersonObject | ConvertTo-Json -Depth 100
        } else {
            $splatADPRestMethodParams = @{
                Uri = "$($ConfigurationSettings.BaseUrl)/hr/v2/worker-demographics"
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
        $PSCmdlet.WriteWarning("Could not retrieve ADP Workers. Error: '$($ex.Message)'")
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

function ConvertTo-RawDataPersonObject {
    <#
    .SYNOPSIS
    Converts the ADP Worker object to a raw data object

    .DESCRIPTION
    Converts the ADP Worker object to a [RawDataPersonObject] that can be imported into HelloID

    .PARAMETER Workers
    The list of Workers from ADP Workforce
    #>
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
                for ($i = 0; $i -lt $worker.businessCommunication.emails.Length; $i++) {
                    $emails = @{
                        emailAddress = $worker.businessCommunication.emails[$i].emailUri
                    }
                }

                for ($i = 0; $i -lt $worker.businessCommunication.landLines.Length; $i++) {
                    $landLines = @{
                        Name = $worker.businessCommunication.landLines[$i].nameCode.shortName
                        FormattedNumer = $worker.businessCommunication.landLines[$i].formattedNumber
                    }
                }

                for ($i = 0; $i -lt $worker.businessCommunication.mobiles.Length; $i++) {
                    $mobiles = @{
                        Name = $worker.businessCommunication.mobiles[$i].nameCode.shortName
                        FormattedNumer = $worker.businessCommunication.mobiles[$i].formattedNumber
                    }
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
                    EmailAddress = $emails.emailAddress
                    LandLine = $landLines
                    Mobile = $mobiles
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

                    if ($null -ne $assignment.reportsTo){
                        for ($i = 0; $i -lt $assignment.reportsTo.Length; $i++) {
                            $manager = @{
                                FormattedName = $assignment.reportsTo[$i].reportsToWorkerName.formattedName
                                WorkerID = $assignment.reportsTo[$i].workerID.idValue
                                AssociateOID = $assignment.reportsTo[$i].associateOID
                                RelationShipCode = $assignment.reportsTo[$i].reportsToRelationshipCode.longName
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
        foreach ($Attribute in $CustomFields.stringFields) {
            @{ Name = "$($Attribute.nameCode.codeValue)"; Expression = { "$($Attribute.stringValue)" }.GetNewClosure()}
        }
    )
    $CustomFields | Select-Object -Property $properties
}
#EndRegion

#Region Script
$connectionSettings = ConvertFrom-Json $configuration
Get-ADPWorkers -Configuration $connectionSettings
#EndRegion

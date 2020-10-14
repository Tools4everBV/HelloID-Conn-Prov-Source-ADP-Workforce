#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Persons
# 
# Version: 1.0.1
#####################################################

#Region External functions
function Get-ADPWorkers {
    <#
    .SYNOPSIS
    Retrieves the Workers and WorkerAssignments from ADP Workforce

    .DESCRIPTION
    Retrieves the Workers and WorkerAssignments from ADP Workforce

    .PARAMETER ConfigurationSettings
    The ConfigurationSettings set on the System configuration tab
    #>
    [CmdletBinding()]
    param (
        [Object]
        $ConfigurationSettings
    )

    try {
        if(!$($ConfigurationSettings.ImportFile)){
            $clientSecretBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($($ConfigurationSettings.CLientSecret))
            $clientSecretString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($clientSecretBstr)
            $accessToken = Get-ADPAccessToken -CientID $($ConfigurationSettings.ClientID) -ClientSecret $clientSecretString -Certifcate $($ConfigurationSettings.Certificate)
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
        [String]
        $CientID,

        [SecureString]
        $ClientSecret,

        [X509Certificate]
        $Certifcate
    )

    $authorization = "$($CientID):$($ClientSecret)"
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
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $Uri,

        [Parameter(Mandatory)]
        [String]
        $Method,

        #[Parameter(Mandatory)]
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

function ConvertTo-RawDataPersonObject {
    <#
    .SYNOPSIS
    Converts the ADP Worker object to a raw data object

    .DESCRIPTION
    Converts the ADP Worker object to a raw data object that can be imported into HelloID

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
            [System.Collections.Generic.List[object]]$contracts = @()

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
                    BusinessCommunication = @{
                        Emails = $worker.businessCommunication.emails
                        LandLines = $worker.businessCommunication.landlines
                        Mobiles = $worker.businessCommunication.mobiles
                    }
                }
                OriginalHireDate = $worker.WorkerDates.originalHireDate
                TerminationDate = $worker.WorkerDates.terminationDate
                RetirementDate = $worker.WorkerDates.retirementDate
                Contracts = $contracts
            }

            if ($null -ne $worker.workAssignments){
                foreach ($assignment in $worker.workAssignments){   
                    $assignmentObj = [PSCustomObject]@{
                        PrimaryIndicator = $assignment.primaryIndicator
                        ActualStartDate = $assignment.actualStartDate
                        TerminationDate = $assignment.terminationDate
                        ExpectedTerminationDate = $assignment.expectedTerminationDate
                        WorkerTypeCode = $assignment.workerTypeCode
                        ManagementPosition = $assignment.managementPositionIndicator
                        PositionId = $assignment.positionID
                        PositionTitle = $assignment.PositionTitle
                        HomeOrganizationalUnit = $assignment.homeOrganizationalUnits
                        HomeWorkLocation = $assignment.homeWorkLocation.nameCode
                        AssignedWorkLocation = $assignment.assignedWorkLocations
                        ItemId = $assignment.itemID
                        PayrollGroupCode = $assignment.payrollGroupCode
                        PayrollFileNumber = $assignment.payrollFileNumber
                        JobCode = $assignment.jobCode.longName
                        StandardHours = $assignment.standardHours.hoursQuantity
                        StandardHoursQuantity = $assignment.standardHours.unitCode.longName
                        AssignmentCostCenters = $assignment.assignmentCostCenters
                        ReportsTo = $assignment.reportsTo
                        CustomFieldsGroup = $assignment.customFieldGroup
                    }
                    $contracts.Add($assignmentObj)
                }
                $listWorkers.Add($workerObj)
            }
        }
        $listWorkers
    }
}
#EndRegion

#Region Script
$connectionSettings = ConvertFrom-Json $configuration
Get-ADPWorkers -Configuration $connectionSettings
#EndRegion

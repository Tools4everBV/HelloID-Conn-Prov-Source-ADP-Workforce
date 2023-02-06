#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Persons
#
# Version: 1.0.5.4
#####################################################

#region External functions
function Get-ADPWorkers {
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
    
    } catch {
        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorMessage = Resolve-HTTPError -Error $ex
            Write-Verbose "Could not retrieve ADP Workforce employees. Error: $errorMessage"
        } else {
            Write-Verbose "Could not retrieve ADP Workforce employees. Error: $($ex.Exception.Message)"
        }
    }

    try {
        $page = 0
        while($true)
        {
            $skip = $page * 50
            $currentct = $skip + 50
            write-information "Getting next $currentct users"
            
            $splatADPRestMethodParams = @{
                Url         = "$BaseUrl/hr/v2/worker-demographics?`$top=50&`$skip=$skip"
                Method      = 'GET'
                AccessToken = $accessToken.access_token
                ProxyServer = $ProxyServer
                Certificate = $certificate
            }

            #Invoke-ADPRestMethod @splatADPRestMethodParams | ConvertTo-RawDataPersonObject | ConvertTo-Json -Depth 100

            $jsonCorrected = [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(28591).GetBytes((Invoke-ADPRestMethod @splatADPRestMethodParams).Content))
            $results = ($jsonCorrected | ConvertFrom-Json)
            
          #  ($jsonCorrected | ConvertFrom-Json) | ConvertTo-RawDataPersonObject | ConvertTo-Json -Depth 100
           

            foreach ($item in ($jsonCorrected | ConvertFrom-Json) )
            {
                ConvertTo-RawDataPersonObject $item | ConvertTo-Json -Depth 100
            }
            if($results.workers.count -lt 50)
            {
                break
            }
            else
            {
                $page++
            }
        }
        
    } catch {
        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorMessage = Resolve-HTTPError -Error $ex
            Write-Verbose "Could not retrieve ADP Workforce employees. Error: $errorMessage"
        } else {
            Write-Verbose "Could not retrieve ADP Workforce employees. Error: $($ex.Exception.Message)"
        }
    }
}
#endregion

#region Internal functions
function Get-ADPAccessToken {
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
            Uri         = "$BaseUrl/auth/oauth/v2/token"
            Method      = 'POST'
            Headers     = $headers
            Body        = $body
            Certificate = $certificate
        }
        Invoke-RestMethod @splatRestMethodParameters
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function Invoke-ADPRestMethod {
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
            Uri             = $Url
            Method          = $Method
            Headers         = $headers
            Proxy           = $proxy
            UseBasicParsing = $true
            Certificate     = $Certificate
            ContentType     = 'application/json;charset=utf-8'
        }
        Invoke-WebRequest @splatRestMethodParameters
        
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

			# only filled associateOID's
            if([string]::IsNullOrWhiteSpace($worker.associateOID)){
                continue
            } else {
                [System.Collections.Generic.List[object]]$contracts = @()

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

                    foreach ($assignment in $worker.workAssignments){

                        # Assignments may contain multiple managers (per assignment). There's no way to specify which manager is primary
                        # We always select the first one in the array
                        if ($null -ne $assignment.reportsTo){
                            for ($i = 0; $i -lt $assignment.reportsTo.Length; $i++) {
                                $manager = @{
                                    FormattedName = $assignment.reportsTo[2].reportsToWorkerName.formattedName
                                    WorkerID = $assignment.reportsTo[1].workerID.idValue
                                    AssociateOID = $assignment.reportsTo[3].associateOID
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

                        if ($null -ne $assignment.AssignmentCostCenters){
                            for ($i = 0; $i -lt $assignment.AssignmentCostCenters.Length; $i++) {
                                $assignmentCostCenter = @{
                                    costCenterPercentage = $assignment.AssignmentCostCenters[$i].costCenterPercentage
                                    costCenterID = $assignment.AssignmentCostCenters[$i].costCenterID
                                }
                            }
                        }

                        if ($null -ne $assignment.fullTimeEquivalenceRatio){
                            $assignmentWorkPercentage = $assignment.fullTimeEquivalenceRatio
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
                            JobCode = $assignment.jobCode.codeValue
                            JobTitle = $assignment.jobCode.longName
                            StandardHours = $assignment.standardHours.hoursQuantity
                            StandardHoursQuantity = $assignment.standardHours.unitCode.longName
                            AssignmentCostCenters = $assignmentCostCenter
                            WorkPercentage = $assignmentWorkPercentage
                            ReportsTo = $manager
                            CustomFields = $customFieldsAssignmentProperties
                        }
                        $contracts.Add($assignmentObj)
                    }
                    $listWorkers.Add($workerObj)
                }
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

function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )

    process {
        $HttpErrorObj = @{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $HttpErrorObj['ErrorMessage'] = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $stream = $ErrorObject.Exception.Response.GetResponseStream()
            $stream.Position = 0
            $streamReader = New-Object System.IO.StreamReader $Stream
            $errorResponse = $StreamReader.ReadToend()
            $HttpErrorObj['ErrorMessage'] = $errorResponse
        }
        Write-Output "'$($HttpErrorObj.ErrorMessage)', TargetObject: '$($HttpErrorObj.RequestUri), InvocationCommand: '$($HttpErrorObj.MyCommand)"
    }
}
#endregion

#region Script
$connectionSettings = ConvertFrom-Json $configuration
$splatGetADPWorkers = @{
    BaseUrl             = $($connectionSettings.BaseUrl)
    ClientID            = $($connectionSettings.ClientID)
    ClientSecret        = $($connectionSettings.ClientSecret)
    CertificatePath     = $($connectionSettings.CertificatePath)
    CertificatePassword = $($connectionSettings.CertificatePassword)
    ProxyServer         = $($connectionSettings.ProxyServer)
}
Get-ADPWorkers @splatGetADPWorkers
#endregion
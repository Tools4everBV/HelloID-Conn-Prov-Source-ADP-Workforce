#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Persons
#
# Version: 1.0.5.5
#####################################################

#region Config
$Config = $Configuration | ConvertFrom-Json

<#
$Config = @{
    BaseUrl             = ''
    ClientID            = ''
    ClientSecret        = ''
    CertificatePath     = ''
    PowerShellX509      = ''
    CertificatePassword = ''
    ProxyServer         = ''
    ImportFile          = ''
    WorkerJson          = ''
    DepartmentJson      = ''
}
#>

Write-Verbose -Verbose -Message "$(@(
    "Start person Import:"
    "Base URL: $($Config.BaseUrl)"
    "ClientID: $($Config.ClientID)"
    "Certificate option: $(if (-not [string]::IsNullOrEmpty($Config.PowerShellX509)){'Bytestream from HelloID'} else {'Retrieve certificate from local computer path'})"
    if ([string]::IsNullOrEmpty($Config.PowerShellX509)){"Certificate path: $($Config.CertificatePath)"}
    "Proxy Server: $( if (-not [string]::IsNullOrEmpty($Config.ProxyServer)){$Config.ProxyServer} else {$false})"
    "Import File: $($Config.ImportFile)"
    if ($Config.ImportFile) {"WorkerJson: $($Config.WorkerJson)"}
    if ($Config.ImportFile) {"DepartmentJson: $($Config.DepartmentJson)"}
) -join "`n")"

# Set TLS to accept TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = @(
    [Net.SecurityProtocolType]::Tls12
)

#endregion Config

#region Functions
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

    if ([string]::IsNullOrEmpty($ProxyServer)) {
        $proxy = $null
    }
    else {
        $proxy = $ProxyServer
    }

    try {
        $splatRestMethodParameters = @{
            Uri         = $Url
            Method      = $Method
            Headers     = $headers
            Proxy       = $proxy
            Certificate = $Certificate
            ContentType = 'application/json;charset=utf-8'
        }

        $WebRequest = Invoke-WebRequest @splatRestMethodParameters
        [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(28591).GetBytes($WebRequest.content)) | ConvertFrom-Json

    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
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
            @{ Name = "$($attribute.nameCode.codeValue)"; Expression = { "$($attribute.stringValue)" }.GetNewClosure() }
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
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $stream = $ErrorObject.Exception.Response.GetResponseStream()
            $stream.Position = 0
            $streamReader = New-Object System.IO.StreamReader $Stream
            $errorResponse = $StreamReader.ReadToend()
            $HttpErrorObj['ErrorMessage'] = $errorResponse
        }
        Write-Output "'$($HttpErrorObj.ErrorMessage)', TargetObject: '$($HttpErrorObj.RequestUri), InvocationCommand: '$($HttpErrorObj.MyCommand)"
    }
}
#endregion Functions

#region Script
if (-not [string]::IsNullOrEmpty($Config.PowerShellX509)) {
    #Use for cloud PowerShell flow
    $RAWCertificate = [system.convert]::FromBase64String($Config.PowerShellX509)
    $Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($RAWCertificate, $Config.CertificatePassword)
}
elseif (-not [string]::IsNullOrEmpty($Config.CertificatePath)) {
    #Use for local machine with certificate file
    $Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Config.CertificatePath, $Config.CertificatePassword)
}
else {
    Throw "No certificate configured"
}

try {
    $AccessToken = Get-ADPAccessToken -ClientID $Config.ClientID -ClientSecret $Config.ClientSecret -Certificate $certificate
}
catch {

    if ( $($_.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($_.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorMessage = Resolve-HTTPError -Error $_
        Write-Verbose "Could not retrieve ADP Workforce employees. Error: $errorMessage"
    }
    else {
        Write-Verbose "Could not retrieve ADP Workforce employees. Error: $($_.Exception.Message)"
    }
}

$WorkerCount = 0
$PersonCount = 0
Do {
    $splatADPRestMethodParams = @{
        Url         = "$($Config.BaseUrl.TrimEnd('/'))/hr/v2/worker-demographics?`$top=100&`$skip=$($WorkerCount)"
        Method      = 'GET'
        AccessToken = $AccessToken.access_token
        ProxyServer = $Config.ProxyServer
        Certificate = $Certificate
    }

    $ADPWorkers = Invoke-ADPRestMethod @splatADPRestMethodParams
    $WorkerCount += ($ADPWorkers.workers).count

    $ADPWorkers.workers | ForEach-Object {
        if ($_.workerStatus.statusCode.shortName -ne "Inactive") {
            [PSCustomObject]@{
                ExternalId            = $_.workerID.idValue
                DisplayName           = $_.person.legalName.formattedName
                AssocciateOID         = $_.associateOID
                WorkerID              = $_.workerID.idValue
                Status                = $_.workerStatus.statusCode
                Personal              = @{
                    BirthDate  = $_.person.birthDate
                    BirthPlace = $_.person.birthPlace.cityName
                    Name       = @{
                        legalName           = @{
                            FamilyName       = $_.person.legalName.familyName1
                            FamilyNamePrefix = $_.person.legalName.familyName1Prefix
                            FormattedName    = $_.person.legalName.formattedName
                            GivenName        = $_.person.legalName.givenName
                            Initials         = $_.person.legalName.initials
                            NickName         = $_.person.legalName.nickName
                        }
                        PreferredSalutation = @{
                            Salutation = $_.person.legalName.preferredSalutation
                        }
                    }
                }
                BusinessCommunication = @{
                    EmailAddress = if ($null -ne $_.businessCommunication.emails) { $_.businessCommunication.emails[0].emailUri } else { $null }
                    LandLine     = if ($null -ne $_.businessCommunication.landLines) { $_.businessCommunication.landLines[0].formattedNumber } else { $null }
                    Mobile       = if ($null -ne $_.businessCommunication.mobiles) { $_.businessCommunication.mobiles[0].formattedNumber } else { $null }
                }
                Gender                = $_.person.genderCode.codeValue
                OriginalHireDate      = $_.WorkerDates.originalHireDate
                TerminationDate       = $_.WorkerDates.terminationDate
                RetirementDate        = $_.WorkerDates.retirementDate
                CustomFields          = Select-CustomFields -CustomFields $_.customFieldGroup
                Contracts             = [System.Collections.Generic.List[object]]@( ForEach ($assignment in $_.workAssignments) {
                        [PSCustomObject]@{
                            PrimaryIndicator        = $assignment.primaryIndicator
                            ActualStartDate         = $assignment.actualStartDate
                            TerminationDate         = $assignment.terminationDate
                            ExpectedTerminationDate = $assignment.expectedTerminationDate
                            WorkerTypeCode          = $assignment.workerTypeCode
                            ManagementPosition      = $assignment.managementPositionIndicator
                            PositionId              = $assignment.positionID
                            PositionTitle           = $assignment.PositionTitle
                            HomeOrganizationalUnit  = for ($i = 0; $i -lt $assignment.homeOrganizationalUnits.Length; $i++) {
                                @{
                                    Name = $assignment.homeOrganizationalUnits[$i].nameCode.longName
                                    Code = $assignment.homeOrganizationalUnits[$i].nameCode.codeValue
                                }
                            }
                            #HomeWorkLocation = $assignment.homeWorkLocation.nameCode #Object Empty
                            #AssignedWorkLocation = $assignment.assignedWorkLocations #Object Empty
                            ItemId                  = $assignment.itemID
                            PayrollGroupCode        = $assignment.payrollGroupCode
                            PayrollFileNumber       = $assignment.payrollFileNumber
                            JobCode                 = $assignment.jobCode.codeValue
                            JobTitle                = $assignment.jobCode.longName
                            StandardHours           = $assignment.standardHours.hoursQuantity
                            StandardHoursQuantity   = $assignment.standardHours.unitCode.longName
                            AssignmentCostCenters   = for ($i = 0; $i -lt $assignment.AssignmentCostCenters.Length; $i++) {
                                @{
                                    costCenterPercentage = $assignment.AssignmentCostCenters[$i].costCenterPercentage
                                    costCenterID         = $assignment.AssignmentCostCenters[$i].costCenterID
                                }
                            }
                            WorkPercentage          = $assignment.fullTimeEquivalenceRatio
                            ReportsTo               = for ($i = 0; $i -lt $assignment.reportsTo.Length; $i++) {
                                @{
                                    FormattedName    = $assignment.reportsTo[2].reportsToWorkerName.formattedName
                                    WorkerID         = $assignment.reportsTo[1].workerID.idValue
                                    AssociateOID     = $assignment.reportsTo[3].associateOID
                                    RelationShipCode = $assignment.reportsTo[0].reportsToRelationshipCode.longName
                                }
                            }
                            CustomFields            = Select-CustomFields -CustomFields $assignment.customFieldGroup
                        }
                    }
                )
            } | ConvertTo-Json -Depth 100

            $PersonCount += 1
        }
    }
} While (($ADPWorkers.Workers).Count -eq 100)

Write-Verbose -Verbose "Active Persons imported: $($PersonCount)"
Write-Verbose -Verbose "Total persons processed: $($WorkerCount)"
#endregion Script
#####################################################
# HelloID-Conn-Prov-SOURCE-ADP-Workforce-Departments
#
# Version: 1.0.5.2
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

#region External functions
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
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

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
#endregion External functions

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

$splatADPRestMethodParams = @{
    Url         = "$($Config.BaseUrl)/core/v1/organization-departments"
    Method      = 'GET'
    AccessToken = $AccessToken.access_token
    ProxyServer = $Config.ProxyServer
    Certificate = $Certificate
}

$ADPDepartments = Invoke-ADPRestMethod @splatADPRestMethodParams

$ADPDepartments.organizationDepartments | ForEach-Object {
    [PSCustomObject]@{
        ExternalId        = $_.departmentCode.codeValue
        Name              = $_.departmentCode.longName
        DisplayName       = $_.departmentCode.longName
        ParentExternalId  = $_.parentDepartmentCode.codeValue
        #ManagerExternalId = $auxFieldObjects[3].FieldCode
        ManagerExternalId = foreach ($auxField in $department.auxilliaryFields) {
            if ($auxField.NameCode.codeValue -eq 'manager') {
                $auxField.stringValue
            }
        }
    } | ConvertTo-Json -Depth 100
}
#endregion Script
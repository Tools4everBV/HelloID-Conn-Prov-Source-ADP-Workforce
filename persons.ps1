#Region External functions
function Get-ADPWorkers {
    <#
    .SYNOPSIS
    Retrieves the Workers and WorkerAssignments from ADP Workforce

    .DESCRIPTION
    Retrieves the Workers and WorkerAssignments from ADP Workforce

    .PARAMETER CientID
    The ClientID for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER ClientSecret
    The ClientSecret for the ADP Workforce environment. This will be provided by ADP

    .PARAMETER Certificate
    The private key of the x.509 certificate that's used to generate a ClientID and ClientSecret and for activating the required API's.

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

    .PARAMETER UsePaging
    Retrieve the results using pagination
    #>
    [CmdletBinding()]
    param (
        [String]
        $CientID,

        [SecureString]
        $ClientSecret,

        [X509Certificate]
        $Certifcate,

        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ProxyServer,

        [Bool]
        $UsePaging
    )

    try {
        #$accessToken = Get-ADPAccessToken -CientID $ClientID -ClientSecret $ClientSecret -Certifcate $Certifcate
    } catch {
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $splatErrorRecordParams = @{
            ErrorMessage = "Could not retrieve ADP AccessToken. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'" 
            ExceptionType = 'System.Net.WebException'
        }
        $errorRecord = New-ErrorRecord @splatErrorRecordParams
        $PSCmdlet.WriteError($errorRecord)
    }

    try {
        $baseUri = 'https://test-api.adp.com'

        $splatADPRestMethodParams = @{
            BaseUri = "$baseUri/hr/v2/worker-demographics"
            HttpMethod = 'GET'
            AccessToken = $accessToken
            ProxyServer = $ProxyServer
            UsePaging = $UsePaging
        }
        Invoke-ADPRestMethod @splatADPRestMethodParams | ConvertTo-HelloIDPerson
    } catch [System.Net.WebException]{
        $webEx = $PSItem
        $errorObj = ($($webEx.ErrorDetails.Message) | ConvertFrom-Json).response
        $splatErrorRecordParams = @{
            ErrorMessage = "Could not retrieve ADP Workers. Error: '$($errorObj.applicationCode.message)' Code: '$($errorObj.applicationCode.code)'" 
            ExceptionType = 'System.Net.WebException'
        }
        $errorRecord = New-ErrorRecord @splatErrorRecordParams
        $PSCmdlet.WriteError($errorRecord)
    } catch [System.Exception] {
        $ex = $PSItem
        $splatErrorRecordParams = @{
            ErrorMessage = "Could not retrieve ADP Workers. Error: '$($ex.Exception.Message)'"
            ExceptionType = 'System.Exception'
        }
        $errorRecord = New-ErrorRecord @splatErrorRecordParams
        $PSCmdlet.WriteError($errorRecord)
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

    .PARAMETER BaseUri
    The BaseUri to the ADP Workforce environment

    .PARAMETER HttpMethod
    The CRUD operation for the request. Valid HttpMethods inlcude: GET and POST

    .PARAMETER AccessToken
    The AccessToken retrieved by the <Get-ADPAccessToken> function

    .PARAMETER ProxyServer
    The URL (or IP Address) to the ProxyServer in the network. Leave empty if no ProxyServer is being used

    .PARAMETER UsePaging
    Retrieve the results using pagination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $BaseUri,

        [Parameter(Mandatory)]
        [String]
        $HttpMethod,

        #[Parameter(Mandatory)]
        [String]
        $AccessToken,

        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ProxyServer,

        [Bool]
        $UsePaging
    )

    $headers = @{
        "grant_type" = "client_credentials&scope=api"
        "Content-Type" = "application/json"
        #"Authorization" = "Bearer $AccessToken"
    }

    if ([string]::IsNullOrEmpty($ProxyServer)){
        $proxy = $null
    } else {
        $proxy = $ProxyServer
    }

    try {
        if ($script:SecurityProtocolUseTls12) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        }

        $splatRestMethodParameters = @{
            Uri = $BaseUri
            Method = $HttpMethod
            Headers = $headers
            Proxy = $proxy
            UseBasicParsing = $true
        }
        Invoke-RestMethod @splatRestMethodParameters 
                
    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

function New-ErrorRecord {
    <#
    .SYNOPSIS
    Creates a new Automation.ErrorRecord object

    .DESCRIPTION
    Creates a new custom Automation.ErrorRecord object

    .PARAMETER ErrorMessage
    The ErrorMessage. Typically this is the error coming back from the API

    .PARAMETER ErrorCode
    The ErrorCode. Typically this is the errorcode coming back from the API

    .PARAMETER ExceptionType
    The ExceptionType. Like; System.Net.WebException
    #>
    [OutputType('System.Management.Automation.ErrorRecord')]
    [CmdletBinding()]
    param (
        [String]
        $ErrorMessage,

        [String]
        $ErrorCode,

        [String]
        $ExceptionType
    )

    $exception = New-Object $ExceptionType($ErrorMessage)
    New-Object System.Management.Automation.ErrorRecord(
        $exception,
        $ErrorCode,
        [System.Management.Automation.ErrorCategory]::NotSpecified,
        $TargetObject
    )
}

function ConvertTo-HelloIDPerson {
    <#
    .SYNOPSIS
    Converts the list of Workers to a HelloID Person object

    .DESCRIPTION
    Converts the list of Workers to a HelloID Person object

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
        [System.Collections.Generic.List[object]]$contracts = @()
    
        foreach ($worker in $workers.workers) {
            $workerObj = [PSCustomObject]@{
                FirstName = 'Anthony'
                LastName = 'Albright'
                Convention= 'A';
                NickName = 'Ant'
                ExteralId = $worker.associateOID
                DisplayName = 'Antonie'
                Contracts = $contracts
                Name = @{
                    FamilyName = 'Albright'
                }
            }
    
            foreach ($assignment in $worker.workAssignments){
                for ($i = 0; $i -lt $worker.workAssignments.Length; $i++) {
                    $contractObj = [PSCustomObject]@{
                        WorkingHoursQuantatiy = $assignment.StandardHours.HoursQuantity
                    }
                }
                $contracts.Add($contractObj)
            }
    
            $listWorkers.Add($workerObj)
        }
        $listWorkers | ConvertTo-Json
    }
}
#EndRegion

#Region Script
$SplatADPGetWorkers = @{
    #ClientID = ''
    #ClientSecret = ''
    #Certificate = ''
    #ProxyServer = "http://localhost:8888"
    #UsePaging = $false
}
Write-Verbose 'Starting Person import'
Get-ADPWorkers @SplatADPGetWorkers
Write-Verbose 'Person import completed'
#EndRegion

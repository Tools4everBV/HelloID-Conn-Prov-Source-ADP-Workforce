# HelloID-Conn-Prov-Source-ADP-Workforce

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

<br />

<p align="center">
  <img src="https://user-images.githubusercontent.com/69046642/166976515-105e6dcc-bf56-4fca-8d22-8ae2e2995ee2.jpg">
</p>![adp]()


<!-- Version -->
## Version
| Version | Description | Date |
| - | - | - |
| 1.1.0   | Performance updates and added support for custom fields | 05/05/2022  |
| 1.0.0   | Initial release | 28/02/2022  |

<!-- Requirements -->
## Requirements
- The 'Execute on-premises' switch on the 'System' tab is toggled.
- Windows PowerShell 5.1 installed on the server where the 'HelloID agent and provisioning agent' are running.
- The public key *.pfx certificate belonging to the X.509 certificate that's used to activate the required API's.
- The password for the public key *.pfx certificate.

<!-- TABLE OF CONTENTS -->
## Table of Contents
- [HelloID-Conn-Prov-Source-ADP-Workforce](#helloid-conn-prov-source-adp-workforce)
  - [Version](#version)
  - [Requirements](#requirements)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
    - [API's being used by the HelloID connector](#apis-being-used-by-the-helloid-connector)
  - [Getting started](#getting-started)
    - [Supported PowerShell versions](#supported-powershell-versions)
    - [X.509 certificate / public key](#x509-certificate--public-key)
    - [X.509 certificate / Private key](#x509-certificate--private-key)
    - [AccessToken](#accesstoken)
    - [Paging](#paging)
    - [Assignments](#assignments)
    - [Custom Fields](#custom-fields)
    - [Mappings](#mappings)
    - [Caveats](#caveats)
  - [PowerShell functions](#powershell-functions)
    - [Sample data](#sample-data)
  - [Setup the PowerShell connector](#setup-the-powershell-connector)
- [HelloID Docs](#helloid-docs)

<!-- Introduction -->
## Introduction
ADP Workforce is a cloud based HR management platform and provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID source connector uses the API's in the table below.
Note that the _'HelloID-Conn-Prov-Source-ADP-Workforce'_ implementation is based on ADP Workforce environments for the Dutch market. If you want to implement the connector for the US market, changes will have to be made within the source code.

### API's being used by the HelloID connector
| _API_ | _Description_|
| - | - | - |
| _Worker-Demographics_ | _Contains the employees personal and contract data_ |
| _Organization-Departments_ | _Contains data about the organisation structure_ |

<!-- Getting started -->
## Getting started

### Supported PowerShell versions
The recommended PowerShell version for the  _'HelloID-Conn-Prov-Source-ADP-Workforce'_ is _Windows PowerShell 5.1_. The connector is not tested on older versions of Windows PowerShell.

_PowerShell 7.0.3 Core_ is not yet supported.

### X.509 certificate / public key
To get access to the ADP Workforce API's, a x.509 certificate is needed. This certificate has to be created by the customer.

The public key belonging to the certificate, must be send ADP. ADP will then generate a ClientID and ClientSecret and will activate the required API's.

There are a few options for creating certificates. One of them being the 'OpenSSL' utility. Available on Linux/Windows. https://www.openssl.org/

APD will register an application that's allowed to access the specified API's. _worker-demographics_ and _organizational_departments_. Other API's within the ADP Workforce environment cannot be accessed.

### X.509 certificate / Private key
The private key (*.pfx) belonging to the X.590 certificate must be used in order obtain an accesstoken.

### AccessToken
In order to retrieve data from the ADP Workforce API's, an AccessToken has to be obtained. The AccessToken is used for all consecutive calls to ADP Workforce. To obtain an AccessToken, we will need the ___ClientID___, ___ClientSecret___, ___The path to your pfx certificate___ and the ___password for the pfx certificate___.

Tokens only have access to a certain API scope. Default the scope is set to: 'worker-demographics organization-departments'. Data outside this scope from other API's cannot be retrieved

### Paging
Paging is only supported by ADP for the 'worker-demograpics' endpoint. Paging is not yet implemented in the connector.

### Assignments
If a worker has multiple assignments, each assigment will be imported in HelloID.

### Custom Fields
Both the worker and assigment(s) may contain _custom fields_. Custom fields will be automatically imported in HelloID.

Custom fields can be selected in both the _person_ and _contract_ mapping.

### Mappings
A basic person and contract mapping is provided. Make sure to further customize these accordingly.

### Caveats
__[worker.businessCommunication]__

The _[worker.businessCommunication]_ array contains information about the:

- Fixed Phone Number
- Mobile Phone Number
- Email Address

All three are array's. Implying that they may contain multiple items.

Since the demo data doesn't have array's with multiple items and since there's no way to determine which item is 'primary'. At this point it's hardcoded to always pick the first __[0]__ based item in the array.

```powershell
if ($null -ne $worker.businessCommunication.landLines){
    $PhoneNumberFixed = $worker.businessCommunication.landLines[0].formattedNumber
}
```

__[worker.assignment.reportsTo]__

The _[worker.assignment.reportsTo]_ array for an assignment contains the information about the manager(s) a worker reports to.

The array may contain multiple items (managers) for an assignment. There's no way to determine which manager is the 'primary' manager for a particular contract/assignment. At this point it's hardcoded to always pick the first __[0]__ based item in the array.

<!-- PowerShell functions -->
## PowerShell functions

All PowerShell functions have comment based help. Both in the sourcecode and within the Github repository. <https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-ADP-Workforce/tree/main/docs/en-US>

### Sample data
If you want to customize the connector according to your own needs, you can use the demo data from ADP.

Workers: <https://github.com/marketplace-esi/postman-samples/blob/master/workforce/hr/workers-v2-demographics/success/workers-v2-demographics-al-workers-http-200-response.json>

Department: <https://github.com/marketplace-esi/postman-samples/blob/master/workforce/core/success/core-organization-departments-http-200-response.json>

The connector configuration supports an import from a JSON file for both persons and departments.

<!-- USAGE EXAMPLES -->
## Setup the PowerShell connector
1. Make sure you can access the ADP Workforce API's.

Obtain the accesstoken:

```powershell
$authorization = "$($CientID):$($clientSecretString)"
$base64String = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("grant_type", "client_credentials&scope=worker-demographics organization-departments")
$headers.Add("Authorization", "Basic $base64String)

$response = Invoke-RestMethod 'https://accounts.dex.adp.com/auth/oauth/v2/token' -Method 'POST' -Headers $headers
$response | ConvertTo-Json
$response.access_token
```

Test access to the ADP Workforce API's, replace the value from _$headers.Add("Authorization", "Bearer _your_access_token_")_ with the value from _$response.access_token_.

```powershell
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer _your_access_token_")

$response = Invoke-RestMethod 'https://api.dex.adp.com/test ' -Method 'GET' -Headers $headers
$response | ConvertTo-Json
```

2. Add a new 'Source System' to HelloID and make sure to import all the necessary files.

    - [ ] configuration.json
    - [ ] mapping.json
    - [ ] persons.ps1
    - [ ] departments.ps1

3. Fill in the required fields on the 'Configuration' tab.

---

# HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/

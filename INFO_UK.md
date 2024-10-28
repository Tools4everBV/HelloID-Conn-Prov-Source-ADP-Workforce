The ADP Workforce Source Connector connects ADP Workforce to your target systems the identity & access management (IAM) solution HelloID by Tools4ever. The connector simplifies the management of access rights and authorisations within your organisation, providing consistency and reducing the risk of errors. In this article, you will read more about this integration, specific features and benefits. 

## What is ADP Workforce?

ADP Workforce is a cloud-based Human Capital Management (HCM) solution developed by ADP. The solution is particularly aimed at Dutch private and public organisations with more than 1,000 employees. ADP Workforce combines payroll, HR, talent development and employee data management in one registration system, which automates and streamlines these processes. 

## Why is an ADP Workforce connector useful?

Managing user accounts and authorisations is a time-consuming and complex task, especially if your organisation has many employees. All changes you make in ADP Workforce also need to be processed in all target systems you use. By integrating ADP Workforce and your target systems via HelloID, you do not have to intervene in this process. HelloID automatically detects changes in ADP Workforce and makes the required changes in user accounts and authorisations in your target systems. This ensures that employees can always be optimally productive. The ADP Workforce connector makes it possible to integrate with common target systems, such as:

*	Entra ID
*	Salto Space

Further details on linking to these source systems can be found later in the article.

## HelloID for ADP Workforce helps you with

**Account management without errors:** Managing user accounts can be a complex task, with an ever-increasing complexity as your organisation scales. Errors in account management can also lead to a lot of frustration, disruption and delays. For example, employees cannot access the required applications, which prevents them from doing their work. The integration of ADP Workforce and HelloID makes sure account management is handles without errors, taking your service level to the next level.

**Creating accounts faster:** Employees need access to the right systems and data to be maximally productive. This requires the right user accounts and authorisations. When new employees join the company or employees get promoted, you’d want to create the accounts they require and assign the right authorisations as quickly as possible. With the help of HelloID you can automate and speed up this process, helping your employees get started in the best possible way. 

**Stronger security:** A cyber attack can cause a lot of damage. So you don't want to give attackers more opportunities than strictly necessary. This requires strict management of user accounts and authorisations. For example, you’ll want to block accounts of employees who leave your organisation as soon as possible and revoke unnecessary authorisations of existing users. That way, you minimise the so-called attack surface and offer malicious parties as few options as possible.

**Bidirectional synchronisation:** In some cases, you may want to link information or changes from your target systems back to your source system. A special connector is available via our GitHub repository for this purpose, allowing you to link the business e-mail address back to ADP Workforce.

## How HelloID integrates with ADP Workforce
ADP Workforce and HelloID can be integrated using a connector. Here, the HCM solution acts as the source system for HelloID. Thanks to this link, HelloID can automatically manage the entire lifecycle of accounts in ADP Workforce, without requiring any intervention from your side. HelloID also performs all necessary changes to accounts in your target systems automatically. 

| Change in ADP Workforce |	Procedure in target systems |
| ----------------------- | ---------------------------- | 
| New employee |	Based on the information in ADP Workforce, HelloID creates a user account in connected applications with the appropriate group memberships. Depending on the role of the new employees, HelloID additionally creates user accounts in linked systems the user requires access to and assigns the appropriate rights. |
| Employee changes role |	HelloID automatically makes changes to user accounts and assigns other rights in the connected systems if necessary. Here, the authorisation model in HelloID is followed for granting or withdrawing authorisations.|
| Employee changes name |	The display name and e-mail address are changed (if required) |
| Employee leaves the company |	HelloID deactivates user accounts in target systems and informs the affected parties in the organisation. After a while, the IAM solution automatically deletes the accounts. | 

HelloID uses ADP Workforce's API to import a standard set of data into the HelloID Vault. In this digital vault, the IAM solution stores information in a uniform manner by mapping data to the appropriate fields. This includes data related to employees, contract data and company information. 

## Customised data exchange
You can use a lot of different customised fields in ADP Workforce. If you integrate ADP Workforce with HelloID, the information in these fields also is also passed on directly through the connector. In HelloID, you can then map these customised fields to the correct fields in our so-called person schema. This makes it possible to also use data from customised fields for account provisioning. 

HelloID can also feed information from your target systems back to ADP Workforce. Consider, for example, linking a created business e-mail address back to ADP Workforce. This is important because it ensures that the data in ADP Workforce is always up-to-date.

## Linking ADP Workforce with target systems via HelloID
You can integrate ADP Workforce with various target systems via HelloID. This integration makes it possible to automatically process information and changes from ADP Workforce in your target systems. A great feature, because this way you don't have to do anything and you simultaneously raise both user account and authorization management to a higher level. Some common integrations are:

**ADP Workforce - Microsoft Entra ID integration:** Entra ID is the cloud-based counterpart of Active Directory. You can seamlessly integrate this solution with ADP Workforce using HelloID. The integration automates various manual tasks and also reduces the risk of human error. HelloID automatically synchronises ADP Workforce and Entra ID, ensuring that accounts and access rights are always up-to-date. 

**ADP Workforce - Salto Space integration:** A key prerequisite for being productive is access to the right resources. This includes access to physical locations such as an office building or a specific work or meeting space. The integration between ADP Workforce and Salto Space ensures this happens automatically, requiring no intervention from your end. Employees will automatically have access to the rooms they are authorised to access. This feature uses access groups, which HelloID configures based on the available employee information. HelloID also automatically blocks access in Salto Space if employees leave.

We offer more than 200 connectors for HelloID, allowing you to integrate the IAM solution with a wide range of source and target systems. The endless integration options give you the freedom to connect ADP Workforce to all popular target systems. You can find an overview of all available connectors <a href="https://www.tools4ever.nl/connectoren/">here</a>.

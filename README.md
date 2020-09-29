# HelloID-Conn-Prov-Source-ADP-Workforce

## This is a work in progress. Development has not yet finished.

### Todo

- [ ] Add _departments.ps1_
- [ ] Add pagination for the _workerDemographics_ endpoint
- [ ] Add / test logic to obtain an AccessToken inluding a *.pfx certificate



## Table of contents

 - Introduction
 - Getting started
    - Certificate
    - API scoping
    - API discovery
    - Paging
    - Known errors
    
## Introduction

ADP Workforce is a cloud based HR management platform and provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID source connector uses the API's in the table below.

___The ADP Workforce source connector can only be used in conjunction with the HelloID on premises agent___

---

### API's being used by the HelloID connector

| _API_ | _Description_|
| --- | ----------- |
| _WorkerDemographics_ | _Contains the employees personal and contract data_ |
| _Departments_ | _Contains data about the organisation structure_ |
| _CostCenters_ | _Contains data about the costcenter structure_ |

---

## Getting started

### Setup your environment

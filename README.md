# LeanIXConnector PowerShell Module

The **LeanIXConnector** PowerShell module provides a convenient way to interact with LeanIX, a platform for Enterprise Architecture and Cloud Governance. This module allows you to authenticate with LeanIX, query factsheets, and retrieve relevant information using PowerShell scripts.

## Prerequisites

Before using this module, make sure you have the following prerequisites:

- PowerShell 5.1 or higher
- An API token from your LeanIX instance
- Your LeanIX instance URL

## Installation

1. Download the `LeanIXConnector.psm1` file from this repository.
2. Place the file in a directory accessible by your PowerShell session.

## Usage

To use the **LeanIXConnector** module, follow these steps:

1. Import the module:

   The module needs to be imported with the "using module" statement at the top of the script
  
   ```powershell
   using module ".\leanIx-connector.psm1"
   ```

2. Create an instance of the `LeanIXConnector` class by providing your API token and your LeanIX instance :

   ```powershell
   $token = "YOUR_API_TOKEN"
   $instance = "YOUR_LEANIX_INSTANCE"
   $leanIX = [LeanIXConnector]::New($token, $instance)
   ```

3. Query factsheets:

   You can query factsheets by calling the `GetFactsheets` method. You can optionally provide a filter to narrow down the results.

   ```powershell
   # Get all factsheets
   $allFactsheets = $leanIX.GetFactsheets()

   # Get factsheets with a quick search filter
   $searchfilter =  @{quickSearch = '"ABC123"'}
   $search = $leanIX.GetFactsheets( $filter )

   # Get factsheets with an external id
   $id = "APM1234567"
   $idFilter = @{externalIds= "[`"externalId/$id`"]"}
   $apm = $leanIX.GetFactsheets( $idFilter )
   ```

## Methods

- `Login`: Authenticates with LeanIX using the provided API token. The method will be called automatically if you try to run a query or if the token is expired
- `GetFactsheets`: Retrieves factsheets from LeanIX. You can pass a filter as a hashtable to narrow down the results.

## License

This PowerShell module is provided under the [MIT License](LICENSE).

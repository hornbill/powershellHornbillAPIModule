## Powershell Hornbill XMLMC Module Example
## Browse assets of class "Computer" in your Hornbill instance, using the data::entityBrowseRecords API
## See the API documentation for a full list of supported API input parameters:
## https://api.hornbill.com/data/?op=entityBrowseRecords

# Import Hornbill XMLMC Powershell Module
Import-Module C:\Path\To\The\Module\xmlmcModule.psm1

# Define instance connection details & API key for session authentication
$hbInstance = "yourInstanceName"
$hbZone     = "eur"
$hbAPIKey   = "yourAPIKey"
Set-Instance -Instance $hbInstance  -Key $hbAPIKey -Zone $hbZone

# Build XMLMC API call
Add-Param       "application" "com.hornbill.servicemanager"
Add-Param       "entity" "Asset"
Open-Element    "searchFilter"
Add-Param       "h_class" "computer"
Add-Param       "h_name" "AY"
Close-Element   "searchFilter"
Open-Element    "orderBy"
Add-Param       "column" "h_name"
Add-Param       "direction" "descending"
Close-Element   "orderBy"
Add-Param       "maxResults" "3"

# Invoke XMLMC call, output returned as PSObject
$xmlmcOutput = Invoke-XMLMC "data" "entityBrowseRecords"

# Read output status
if($xmlmcOutput.status -eq "ok") {
    # Poputale object with returned rows
    $assetsRows = $xmlmcOutput.params.rowData.row

    "Assets Found: " + ($assetsRows.Count -as [string])

    for ($i = 0; $i -lt $assetsRows.Count ; $i++) {
        # Loop through returned rows, output to console
        "["+ (($i+1) -as [string]) + "] Asset Class : " + $assetsRows[$i].h_class
        "["+ (($i+1) -as [string]) + "] Asset Name  : " + $assetsRows[$i].h_name
    }
} else {
    # API call status not OK - return status and error to console
    "API Call Status : " + $xmlmcOutput.status
    "Error Returned  : " + $xmlmcOutput.error
}

# Important! Remove XMLMC module from memory for security once XMLMC calls complete
Remove-Module xmlmcModule
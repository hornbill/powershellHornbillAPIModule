## Powershell Hornbill XMLMC Module Example
## Add asset of class Computer to your Hornbill instance
## See the API documentation for a full list of supported input parameters:
## https://api.hornbill.com/apps/com.hornbill.servicemanager/AssetsComputer?op=addAssetComputer

# Import Hornbill XMLMC Powershell Module
Import-Module C:\Path\To\The\Module\xmlmcModule.psm1

# Define instance connection details & API key for session authentication
$hbInstance ="yourInstanceName"
$hbZone     = "eur"
$hbAPIKey   = "yourAPIKey"
Set-Instance -Instance $hbInstance  -Key $hbAPIKey -Zone $hbZone

# Define Asset details
$assetName          = "Example Desktop"
$assetDescription   = "This desktop computer asset record was added from a Powershell script"
$assetClass         = "computer"
$assetTypeName      = "Desktop"

# First we need to build and run an XMLMC call to get the Asset Type primary key
# Which is required by the 
Add-Param       "application" "com.hornbill.servicemanager"
Add-Param       "entity" "AssetsTypes"
Add-Param       "matchScope" "all"
Open-Element    "searchFilter"
Add-Param       "h_class" $assetClass
Add-Param       "h_name" $assetTypeName
Close-Element   "searchFilter"
Add-Param       "maxResults" "1"

# Invoke XMLMC call, output returned as PSObject
$assetTypeOutput = Invoke-XMLMC "data" "entityBrowseRecords"

if($assetTypeOutput.status -ne "ok" -or !$assetTypeOutput.params.rowData){
    if($assetTypeOutput.status -eq "ok") {
        "No matching Asset Type records found!"
    } else {
        # API call status not OK - return status and error to console
        "API Call Status : " + $assetTypeOutput.status
        "Error Returned  : " + $assetTypeOutput.error
    }
} else {
    # Now we have the AssetType Primary Key, we can add the record to the AssetsComputer entity
    $assetTypePK = $assetTypeOutput.params.rowData.row.h_pk_type_id

    # Build XMLMC API call to add Asset record
    Add-Param "description" $assetDescription
    Add-Param "name" $assetName
    Add-Param "type" $assetTypePK
    Add-Param "version" "1"

    # Invoke XMLMC call, output returned as PSObject
    $xmlmcOutput = Invoke-XMLMC "apps/com.hornbill.servicemanager/AssetsComputer" "addAssetComputer"

    # Read output status
    if($xmlmcOutput.status -eq "ok") {
        if($xmlmcOutput.params.assetId -and $xmlmcOutput.params.assetId -ne ""){
            "New asset created, ID : " + $xmlmcOutput.params.assetId
        }
        if($xmlmcOutput.params.exceptionName -and $xmlmcOutput.params.exceptionName -ne ""){
            "Exception Reported : " + $xmlmcOutput.params.exceptionName
            "Exception Summary : " + $xmlmcOutput.params.exceptionSummary
        }
        
    } else {
        # API call status not OK - return status and error to console
        "API Call Status : " + $xmlmcOutput.status
        "Error Returned  : " + $xmlmcOutput.error
    }
}

# Important! Remove XMLMC module from memory for security once XMLMC calls complete
Remove-Module xmlmcModule
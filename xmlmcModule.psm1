##############################
# Hornbill XMLMC API Module for Powershell
# v1.0.1
#
#.DESCRIPTION
# This module includes functions to allow your Powershell scripts to make and send API calls 
# to your Hornbill instance, and process responses accordingly.
#
# Requires Powershell 3.0 or above.
#
#.NOTES
# See example scripts and function documentation for guidance on usage.
##############################

# Initialise the module-level variables
[string]$script:InstanceName = ""
[string]$script:InstanceZone = ""
[string]$script:APIKey = ""
[string]$script:XMLMCParams = ""
[string]$script:InstanceURL = ""

##############################
# Set-Instance
#
#.DESCRIPTION
# MANDATORY - Allows your Powershell script to define the Hornbill instance to connect
# to, the zone in which it resides, and the API key to use for session generation.
#
#.PARAMETER Instance
# The (case-sensitive) instance name that you wish to connect to.
# 
#.PARAMETER Zone
# The (case-sensitive) zone in which the Hornbill instance resides.
# If not supplied, defaults to: eur
#
#.PARAMETER Key
# The API key to use to generate authenticate against the Hornbill instance with.
#
#.EXAMPLE
# Set-Instance "yourinstancename" "eur" "yourapikeygoeshere"
##############################
function Set-Instance {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the name of the Instance to connect to (case sensitive)")]
        [string]$Instance,
        
        [Parameter(Mandatory=$False, HelpMessage="Specify the Zone in which the Instance is run. Defaults to 'eur' (case sensitive)")]
        [string]$Zone="eur",

        [Parameter(Mandatory=$True, HelpMessage="Specify the API Key to authenticate the session against")]
        [string]$Key
    )
    $script:InstanceName = $Instance
    $script:InstanceZone = $Zone
    $script:APIKey = $Key
    $script:InstanceURL = "https://"+$script:InstanceZone+"api.hornbill.com/"+$script:InstanceName+"/xmlmc/"
}

##############################
# Add-Param
#
#.DESCRIPTION
# Add a parameter to the XMLMC request
#
#.PARAMETER ParamName
# Mandatory - the name of the parameter
#
#.PARAMETER ParamValue
# Mandatory - the [string] value of the parameter
#
#.PARAMETER ParamAttribs
# Any attributes to add to the XMLMC request
#
#.EXAMPLE
# Add-Param "application" "com.hornbill.servicemanager"
# Add-Param "h_class" "computer" "onError=""omitElement"" "
# 
# Note the escaped double-quotes in the ParamAttribs string.
##############################
function Add-Param {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the name of the Parameter to add")]
        [ValidateNotNullOrEmpty()]
            [string]$ParamName,
        [Parameter(Mandatory=$True, HelpMessage="Specify the Value of the Parameter")]
        [ValidateNotNullOrEmpty()]
            [string]$ParamValue,
        [Parameter(Mandatory=$False, HelpMessage="Specify attributes to add to the Parameter XML node")]
            [string]$ParamAttribs
    )
    if($ParamName.length -eq 0){
        return "Parameter name length needs to be greater than zero"
    }
    $script:EncodedParamVal = [System.Security.SecurityElement]::Escape($ParamValue)
    $CurrentParam = "<"+$ParamName
    if($ParamAttribs -and $ParamAttribs.length -gt 0){
        $CurrentParam = $CurrentParam + " " + $ParamAttribs
    }
    $CurrentParam = $CurrentParam + ">" + $EncodedParamVal + "</"+$ParamName+">"
    $script:XMLMCParams = $script:XMLMCParams + $CurrentParam
}

##############################
# Open-Element
#
#.DESCRIPTION
# Allows for the building of complex XML
#
#.PARAMETER Element
# The name of the complex element to open
#
#.EXAMPLE
# Open-Element "primaryEntityData"
##############################
function Open-Element {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the name of the Parameter to add")]
        [ValidateNotNullOrEmpty()]
            [string]$Element
    )
    $script:XMLMCParams = $script:XMLMCParams + "<"+$Element+">"
}

##############################
# Close-Element
#
#.DESCRIPTION
# Allows for the building of complex XML
#
#.PARAMETER Element
# The name of the complex element to close
#
#.EXAMPLE
# Close-Element "primaryEntityData"
##############################
function Close-Element {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the name of the Parameter to add")]
        [ValidateNotNullOrEmpty()]
            [string]$Element
    )
    $script:XMLMCParams = $script:XMLMCParams + "</"+$Element+">"
}

##############################
# Get-Params
#
#.DESCRIPTION
# Returns XML string of parameters that have been added by Add-Params, Open-Element or Close-Element
#
#.EXAMPLE
# Get-Params
##############################
function Get-Params {
    if($script:XMLMCParams.length -gt 0) {
        return "<params>"+$script:XMLMCParams+"</params>"
    }
    return ""
}

##############################
# Clear-Params
#
#.DESCRIPTION
# Clears any existing XMLMC parameters that have been added
#
#.EXAMPLE
# Clear-Params
##############################
function Clear-Params {
    $script:XMLMCParams = ""
}

##############################
# Get-B64Encode
#
#.DESCRIPTION
# Returns a Base64 encoded string from a given UTF8 string
#
#.PARAMETER StringVal
# The string to encode
#
#.EXAMPLE
# Get-B64Encode "encode this please"
##############################
function Get-B64Encode {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the string to Base-64 encode")]
        [ValidateNotNullOrEmpty()]
            [string]$StringVal
    )
    $UnencodedBytes = [System.Text.Encoding]::UTF8.GetBytes($StringVal)
    $EncodedText =[Convert]::ToBase64String($UnencodedBytes)
    return $EncodedText
}

##############################
# Get-B64Decode
#
#.DESCRIPTION
# Returns a UTF8 string from a given Base64 endcoded string
#
#.PARAMETER StringVal
# The string to decode
#
#.EXAMPLE
# Get-B64Decode "ZW5jb2RlIHRoaXMgcGxlYXNl"
##############################
function Get-B64Decode {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the Base-64 string to decode")]
        [ValidateNotNullOrEmpty()]
            [string]$B64Val
    )
    $DecodedString = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($B64Val))
    return $DecodedString
}

##############################
# Invoke-XMLMC
#
#.DESCRIPTION
# Takes the API Service and Method as inputs to this function, and any parameters 
# added with Add-Param, Open-Element or Close-Element, and invokes an API call using
# the instance details defined with the Set-Instance function.
# 
# Returns a Powershell Object containing:
# .status - the status of the API call or HTTP response
# .params - any returned parameters from the API
# .error  - any returned errors if the HTTP request or API call fails
#
#.PARAMETER XMLMCService
# The Service that contains the API on the Hornbill instance
#
#.PARAMETER XMLMCMethod
# The API Method
#
#.EXAMPLE
# $xmlmcCall = Invoke-XMLMC "session" "getSessionInfo"
#
# If successful This would return:
# $xmlmcCall.status = "ok"
# $xmlmcCall.params = A PSObject containing all output parameters returned by the
# session::getSessionInfo API
##############################
function Invoke-XMLMC {
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Specify the XMLMC Service")]
        [ValidateNotNullOrEmpty()]
            [string]$XMLMCService,
        [Parameter(Mandatory=$True, HelpMessage="Specify the XMLMC Method")]
        [ValidateNotNullOrEmpty()]
            [string]$XMLMCMethod
    )
    $script:responseStatus = ""
    $script:responseParams = ""
    $script:responseError = ""

    try {
        # Build XMLMC call
        $script:mcParamsXML = Get-Params
        $script:bodyString = '<methodCall service="'+$XMLMCService+'" method="'+$XMLMCMethod+'">'+$script:mcParamsXML+'</methodCall>'
        $script:body = [XML]$script:bodyString

        # Build HTTP request headers
        $script:headers = @{}
        $script:headers["Content-Type"] ="text/xmlmc"
        $script:headers["Cache-control"]="no-cache"
        $script:headers["Authorization"]="ESP-APIKEY "+$script:APIKey
        $script:headers["Accept"]="text/xml"

        # Build URI for HTTP request
        $script:URI = $script:InstanceURL + $XMLMCService+"/?method="+$XMLMCMethod
       
        # Invoke HTTP request
        $r = Invoke-WebRequest -Uri $script:URI -Method Post -Headers $script:headers -ContentType "text/xmlmc" -Body $script:body -ErrorAction:Stop

        # Read and process response
        [XML]$script:xmlResponse = $r.Content
        $script:responseStatus = $script:xmlResponse.methodCallResult.status
        if(($script:responseStatus -eq "fail") -or ($script:responseStatus -eq "false")){
            $script:responseError = $script:xmlResponse.methodCallResult.state.error
        } else {
            $script:responseParams = $script:xmlResponse.methodCallResult.params
        }        
    }
    catch {
        # HTTP request failed - return exception in response
        $script:responseError = $_.Exception
        $script:responseStatus = "fail"
    }

    # Clear the XMLMC parameters now ready for the next API call
    Clear-Params

    # Return an object of the results.
    $script:resultObject = New-Object PSObject -Property @{
        Status = $script:responseStatus
        Params = $script:responseParams
        Error = $script:responseError
    }
    # Return result object
    return  $script:resultObject       
}

# Export the functions available to the script importing this module
Export-ModuleMember -Function 'Set-*'
Export-ModuleMember -Function 'Add-*'
Export-ModuleMember -Function '*-Element'
Export-ModuleMember -Function 'Get-Params'
Export-ModuleMember -Function 'Clear-Params'
Export-ModuleMember -Function 'Get-B64*'
Export-ModuleMember -Function 'Invoke-XMLMC'
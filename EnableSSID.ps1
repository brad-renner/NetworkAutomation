# Take user input of WLAN/SSID selection & enable the WLAN administratively or enable the broadcasting of the WLAN's SSID.
# Parameters are passed from user input, select what WLAN to be enabled on what WLC from user input
# Dryrun either runs the script if "false" or writes the output to screen if "true"
param(
    [Parameter(Mandatory=$True, 
        HelpMessage = 'Please chose the WLAN/SSID to be enabled/broadcast)')]
    [ValidateSet("Internal", "Scanner", "POS", "Guest")]
    [string]$wlan,
    [Parameter(Mandatory=$True, 
        HelpMessage = 'Please chose which WLC the WLAN/SSID should be enabled on from the following options: ABCWLC9800-1, ABCWLC9800-2, ABCWLC9800-3, ABCNWLC9800, ABCLABWLC9800L-1')]
    [ValidateSet("ABCWLC9800-1","ABCWLC9800-2", "ABCWLC9800-3", "ABCNWLC9800", "ABCLABWLC9800L-1")]
    [string]$WLC,
    [switch]$broadcastSSID,
    [switch]$dryrun
)

# Import ABCWireless Module for the headers 
Import-Module ABCWireless -Function New-ABCWirelessHeaders
$headers = New-ABCWirelessHeaders

# Dryrun is selected, write to screen the parameters and body of the RESTCONF API call, & URI that would have run if dryrun was not selected
if ($dryrun){
    Write-Host "Dry Run:'$dryRun' detected, WLAN/SSID: $($wlan) & WLC: $($WLC) have been selected"

    if ($broadcastSSID){
        # Body input based off which WAN/SSID & WLC was selected from user input parameters
        $body = "{
            `"Cisco-IOS-XE-wireless-wlan-cfg:apf-vap-id-data`": {
                `"wlan-status`": true,
                `"broadcast-ssid`": true
            }
        }"   
    }
    else{
        $body = "{
            `"Cisco-IOS-XE-wireless-wlan-cfg:apf-vap-id-data`": {
                `"wlan-status`": true,
            }
        }" 
    }
        Write-Host "$($body)"
        Write-Host $("https://$($WLC)/restconf/data/Cisco-IOS-XE-wireless-wlan-cfg:wlan-cfg-data/wlan-cfg-entries/wlan-cfg-entry=`"$($wlan)`"/apf-vap-id-data/")
        return
}

if ($broadcastSSID){
    # Body input based off which WAN/SSID & WLC was selected from user input parameters
    $body = "{
        `"Cisco-IOS-XE-wireless-wlan-cfg:apf-vap-id-data`": {
            `"wlan-status`": true,
            `"broadcast-ssid`": true
        }
    }"   
}
else{
    $body = "{
        `"Cisco-IOS-XE-wireless-wlan-cfg:apf-vap-id-data`": {
            `"wlan-status`": true
        }
    }" 
}

# PowerShell Invoke-RestMethod to call the REST API URI, with the hearders specified, & skipping the certificate check + http error check for 404 messages.
$response = Invoke-RestMethod $("https://$($WLC)/restconf/data/Cisco-IOS-XE-wireless-wlan-cfg:wlan-cfg-data/wlan-cfg-entries/wlan-cfg-entry=`"$($wlan)`"/apf-vap-id-data/") -Method 'PATCH' -Headers $headers -Body $body -SkipCertificateCheck -SkipHttpErrorCheck -TimeoutSec 120
$jsonResponse = ($response | ConvertTo-Json)
Write-Host "$($jsonResponse)"

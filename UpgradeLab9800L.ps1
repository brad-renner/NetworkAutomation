# Script to upgrade ABCLABWLC9800L-1 WLC via RESTCONF URI/API call - Takes 15mins from Script launch to being back online.
# Parameters are passed from user input, select what version of software the WLC should be upgraded to ($version)
# $dryrun either runs the upgrade software command or writes to the screen what would be run without any action being taken.
param(
    [Parameter(Mandatory=$True, 
        HelpMessage = 'Please chose from the following options: 17.03.03, 17.03.04c, 17.03.05a, 17.03.06, 17.09.03')]
    [ValidateSet("17.03.03", "17.03.04c", "17.03.05a", "17.03.06", "17.09.03")]
    [string]$version,
    [switch]$dryrun
)

# Variable for ABCLABWLC9800L-1 wireless controller, hardcoding it into the script 
# so no other WLC can be upgraded accidentally
$9800L = "ABCLABWLC9800L-1"

# Import ABCWireless Module for the headers 
Import-Module ABCWireless -Function New-ABCWirelessHeaders
$headers = New-ABCWirelessHeaders

# If $dryRun is true, only output the version the controller would have been upgraded, but do not actually call the RESTCONF API call
if  ( $dryRun ){
	Write-Host "Dry Run:'$dryRun' detected, $($9800L) WLC would have been upgraded to $($version) version of code if this wasn't a dry run"

    # Body input based off which software the device should be upgraded to from user input parameter
    $body = "{
            `"Cisco-IOS-XE-install-rpc:input`": {
                `"uuid`": `"$($version)`",
                `"one-shot`": true,
        	    `"path`": `"bootflash:C9800-L-universalk9_wlc.$($version).SPA.bin`"
            }
        }"   
    Write-Host "$($body)"
    Write-Host "Version variable: $($version)"
    Write-Host "https://$($9800L)/restconf/data/Cisco-IOS-XE-install-rpc:install/"
    return
}

# Create the following $body syntax for the HTTP Invoke RestMethod API call based on the $version
# Body input based off which software the device should be upgraded to from user input parameter
    $body = "{
            `"Cisco-IOS-XE-install-rpc:input`": {
                `"uuid`": `"$($version)`",
                `"one-shot`": true,
        	    `"path`": `"bootflash:C9800-L-universalk9_wlc.$($version).SPA.bin`"
            }
        }"
    Write-Host "$($body)"
    Write-Host "$($version) selected, https://$($9800L)/restconf/data/Cisco-IOS-XE-install-rpc:install/"

# PowerShell Invoke-RestMethod to call the REST API URI, with the hearders specified, & skipping the certificate check + http error check for 404 messages.
    $response = Invoke-RestMethod "https://$($9800L)/restconf/data/Cisco-IOS-XE-install-rpc:install/" -Method 'POST' -Headers $headers -Body $body -SkipCertificateCheck -SkipHttpErrorCheck -TimeoutSec 120
    $jsonResponse = ($response | ConvertTo-Json)
    Write-Host "$($jsonResponse)"

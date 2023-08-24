# Test Script to make RESTCONF URI/API call with correct HTTP RESTMETHOD RPC to save device's config
# Parameters that are being passed from Script 'TaggedNetboxDevices.ps1', $wlcs denotes the device(s) to run the script against.
param(
    [Parameter(Mandatory=$True)]
    [string]$wlcs
)

# Import ABCWireless Module for the headers 
Import-Module ABCWireless -Function New-ABCWirelessHeaders
$headers = New-ABCWirelessHeaders
$body = ""

# PowerShell Invoke-RestMethod to call the REST API URI, with the hearders specified, & skipping the certificate check + http error check for 404 messages.
$response = Invoke-RestMethod "https://$($wlcs)/restconf/operations/cisco-ia:save-config/" -Method 'POST' -Headers $headers -Body $body -SkipCertificateCheck -SkipHttpErrorCheck -TimeoutSec 120
$jsonResponse= ($response | ConvertTo-Json)

# Check if response to REST HTTPS call was successfull
# If save-config was successfull print it was on which device
if ($response.'cisco-ia:output' -match "Save running-config successful"){
	Write-Host "Saving the config on $($wlcs) was a success!"
}
# If '404 Not Found' is returned, print unsuccessful, confirm RESTCONF is enabled, & the output recieved back 
elseif ($response -match "404 Not Found"){
	Write-Host "ERROR: Config was NOT saved on $($wlcs). Is RESTCONF enabled on device? See error: $jsonResponse"
}
# Otherwise print it was unsuccessful, and the output recieved back 
elseif ($response.'cisco-ia:output' -notmatch "Save running-config successful"){
	Write-Host "ERROR: Config was NOT saved on $($wlcs). See error: $jsonResponse"
}

# Write the output of the request to the screen
# Write-Host $jsonResponse

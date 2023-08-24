# Function to upgrade take user input of AP(s) name (xxxxAPyy, where xxxx = store number & y is AP number) and reboot the APs.
# Parameters are passed from user input, select what AP(s) to be rebooted. 
# $dryrun either runs the script if "false" or if "true" it writes to the screen what action WOULD HAVE being taken.
function Invoke-RebootAP
{
    param(
        [Parameter(Mandatory=$True, 
            HelpMessage = 'Input AP(s) to be rebooted, in this format: xxxxAPyy (xxxx = store number & y is the 1 or 2 digit AP number)')]
        [ValidatePattern("^\d{4}AP\d{1,2}$")]
        [string]$apName,
        [switch]$dryRun
    )

    # Import ABCWireless Module for the headers 
    Import-Module ABCWireless -Function New-ABCWirelessHeaders
    $headers = New-ABCWirelessHeaders

    # Body input based off which AP(s) should be rebooted from user input parameter
    $body = "{
        `"input`": {
        `"ap-name`": [`"$($apName.ToUpper())`"]
        }
    }"   

    $store9800WLC = Get-ABCWirelessStoreController -storenumber $($apName.ToUpper().Substring(0,4))
    Write-Host "$($apName.ToUpper()) should be on Controller: $($store9800WLC)"

    # If $dryRun is true, only output the what would have been done to the screen, but do not actually call the RESTCONF API call
    if  ($dryRun){
	    Write-Host "Dry Run:'$dryRun' detected"

        # Write AP list to the screen for verification of user AP input
        Write-Host "AP: $($apName.ToUpper())"
        Write-Host "$($body)"

        # Print to the screen the URI that would have been sent in the HTTP Method, if it was NOT a "dryrun"
        Write-Host "https://$($store9800WLC)/restconf/data/Cisco-IOS-XE-wireless-access-point-cmd-rpc:ap-reset/"
    }
    else {          
        # PowerShell Invoke-RestMethod to call the REST API URI, with the hearders specified, & skipping the certificate check + http error check for 404 messages.
        $response = Invoke-RestMethod "https://$($store9800WLC)/restconf/data/Cisco-IOS-XE-wireless-access-point-cmd-rpc:ap-reset/" -Method 'POST' -Headers $headers -Body $body -SkipCertificateCheck -SkipHttpErrorCheck -TimeoutSec 120
        $jsonResponse = ($response | ConvertTo-Json)

        # If/Else statement that will write to the screen an error if the script couldn't find the AP to reboot on the controller specified.
        # If no error, then write to output that the AP has been rebooted successfully on which WLC & the output response back (blank in successful)     
        if ($response.errors){
            Write-Error "$($apName.ToUpper()) was not found on $($store9800WLC). It was NOT rebooted. See if AP is offline/disconnected from the network. Error Output: $($jsonResponse)"
        }
        else{
            Write-Host "$($apName.ToUpper()) was successfully rebooted on $($store9800WLC): $($jsonResponse)"
            $true
        }
    }
}
# Invoke-RebootAP -dryrun 0868AP1,0868AP5

function Invoke-MigrateAP
{
    param(
        [Parameter(Mandatory=$True, 
            HelpMessage = 'Input AP(s) to be rebooted, in this format: xxxxAPyy (xxxx = store number & y is the 1 or 2 digit AP number)')]
        [ValidatePattern("^\d{4}AP\d{1,2}$")]
        [string]$apName,
        [Parameter(Mandatory=$True, 
            HelpMessage = 'Please chose which WLC the AP(s) should be migrated to from the following options: ABCWLC9800-1, ABCWLC9800-2, ABCWLC9800-3, ABCNWLC9800, ABCLABWLC9800L-1')]
        [ValidateSet("ABCWLC9800-1","ABCWLC9800-2", "ABCWLC9800-3", "ABCNWLC9800", "ABCLABWLC9800L-1")]
        [string]$WLC,
        [switch]$dryRun
    )

    # Import ABCWireless Module for the headers 
    Import-Module ABCWireless -Function New-ABCWirelessHeaders
    $headers = New-ABCWirelessHeaders

    # Body input based off which AP(s) should be rebooted from user input parameter & which WLC they should be 
    # Migrated too from the WLC user input parameter
        $body = "{
            `"input`" : {
                `"mode`": `"controller-name-enable`",
                `"controller-name`": `"$($WLC)`",
                `"ipaddr`": `"$((resolve-DnsName $($WLC)).IpAddress)`",
                `"index`": `"index-primary`",
                `"ap-name`": `"$($apName.ToUpper())`"
            }
        }"

    $store9800WLC = Get-ABCWirelessStoreController -storenumber $($apName.ToUpper().Substring(0,4))
    Write-Host "$($apName.ToUpper()) should be on Controller: $($store9800WLC)"

    # If $dryRun is true, only output the what would have been done to the screen, but do not actually call the RESTCONF API call
    if  ($dryRun){
	    Write-Host "Dry Run:'$dryRun' detected"

        # Write AP list to the screen for verification of user AP input
        Write-Host "AP: $($apName.ToUpper())"
        Write-Host "$($body)"

        # Print to the screen the URI that would have been sent in the HTTP Method, if it was NOT a "dryrun"
        Write-Host "https://$($store9800WLC)/restconf/data/Cisco-IOS-XE-wireless-access-point-cfg-rpc:set-ap-controller"
    }
    else {          
        # PowerShell Invoke-RestMethod to call the REST API URI, with the hearders specified, & skipping the certificate check + http error check for 404 messages.
        $response = Invoke-RestMethod "https://$($store9800WLC)/restconf/data/Cisco-IOS-XE-wireless-access-point-cfg-rpc:set-ap-controller" -Method 'POST' -Headers $headers -Body $body -SkipCertificateCheck -SkipHttpErrorCheck -TimeoutSec 120
        $jsonResponse = ($response | ConvertTo-Json)

        # If/Else statement that will write to the screen an error if the script couldn't find the AP to reboot on the controller specified.
        # If no error, then write to output that the AP has been rebooted successfully on which WLC & the output response back (blank in successful)     
        if ($response.errors){
            Write-Error "$($apName.ToUpper()) was not found on $($store9800WLC). It was NOT migrated to $($WLC). See if AP is offline/disconnected from the network. Error Output: $($jsonResponse)"
        }
        else{
            Write-Host "$($apName.ToUpper()) was successfully migrated to $($WLC): $($jsonResponse)"
            $true
        }
    }
}
# Invoke-MigrateAP -dryrun 0868AP1,0868AP5 -WLC ABCNWLC9800

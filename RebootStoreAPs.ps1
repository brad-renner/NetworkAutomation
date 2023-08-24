param (
    [Parameter(Mandatory = $true,
        HelpMessage = '4 digit store number')]
    [ValidatePattern('^\d{4}$')]
    [string]$storenumber,
    [int]$rebootDelayMinutes = 6,
    [Parameter(Mandatory=$True)]
    [ValidateSet("ABCWLC9800-1", "ABCWLC9800-2", "ABCWLC9800-3", "ABCNWLC9800")]
    [string]$storeController,
    [Parameter(Mandatory = $false,
        HelpMessage = 'Will display commands without rebooting')]
    [bool]$dryRun
)


<#
This code is used to reboot wireless access points (APs). It starts by importing two modules and setting up the headers.
It then determines the registering controller, gets the AP data, and if it detects APs, issues a reboot command.
If the -dryRun parameter is used, it will not execute the commands but instead display the commands that would have been used.
If the -dryRun parameter is not used, it will wait up to the provided rebootDelayMinutes to check if the APs have returned online.
If it times out, it will display an error with the APs that are still offline.
#>

Import-Module ABCWireless
Import-Module ABCWirelessAP
$headers = New-ABCWirelessHeaders

Write-Information "Wireless controller is $($storeController)"
# END determine registering controller

# get ap data
Write-Information "Getting Store number $($storenumber) registered APs"

$currentAPData = Get-ABCWirelessAPMacs -controller $storeController | Where-Object "wtp-name" -match $storenumber

# end script if not APs are detected
if (!($currentAPData)){
    Write-Error "no APs found for $($storenumber). controller determined to be $($storeController)"
}

$currentAPData | Format-Table
$apCount = ($currentAPData | measure).count
# END get ap data
###################################

# reboot commands

$bodyTemplate = "{
`n    `"input`" : {
`n            `"ap-name`": `"{{ apName }}`"
`n    }
`n}"

If ($currentAPData){
    $feedback = Read-host "I have $($apCount) connected APs, what is your feedback?"
}
else {$feedback = Read-host "No APs detected, what is your feedback? (type stop to stop job"}

if ($feedback -match "[sS]top"){
    return
}

if ($dryRun){ Write-Information "`t DRY RUN, commands won't be sent" }
else { Write-Information "Rebooting AP Configs" }

Foreach ($ap in $currentAPData."wtp-name"){

    $body = $bodyTemplate -replace "{{ apName }}",$ap | ConvertFrom-Json | ConvertTo-Json -Depth 5

    # if a dry run show the commands that would have been entered
    if ($dryRun){
        Write-Information "`t Invoke-RestMethod "https://$($storeController)/restconf/data/"Cisco-IOS-XE-wireless-access-point-cmd-rpc:ap-reset/"
        Write-Information "`t -Method 'POST' -Headers `$headers"
        Write-Information "`t -Body `$body -SkipCertificateCheck"
        Write-Information "`t body value is..."
        Write-Information $body
    }
    else {
        Invoke-RestMethod "https://$($storeController)/restconf/data/Cisco-IOS-XE-wireless-access-point-cmd-rpc:ap-reset/" `
        -Method 'POST' -Headers $headers `
        -Body $body -SkipCertificateCheck

        Start-Sleep 1
    }
}

# end script if this is a dry run
# if ($dryRun){ return }

Write-Information "reboot commands sent!"

$countdown = [System.Diagnostics.Stopwatch]::StartNew()
Start-Sleep 5

# END reboot commands
#########################

# Wait for rebooted devices

while ($countdown.Elapsed.TotalMinutes -lt $rebootDelayMinutes){

    $afterRebootAPData =  Get-ABCWirelessAPMacs -controller $storeController | where "wtp-name" -match $storenumber

    if ($afterRebootAPData){

        Write-Information "Waited $($countdown.Elapsed.TotalMinutes) minutes for APs to return online"

        $comparedDifference = Compare-Object `
        -ReferenceObject $currentAPData `
        -DifferenceObject $afterRebootAPData `
        -Property "wtp-name"

        if ($comparedDifference){
            Write-Information "still waiting for $($comparedDifference.'wtp-name' | Out-String)"
            Write-Information "start-sleep 60"
            start-sleep 60
        }
        else {
            Write-Information "All APs online"
            $afterRebootAPData | Format-Table
            break
        }
    }
    else{
        Write-Information "start-sleep 60"
        start-sleep 60
    }
}

if ($countdown.Elapsed.TotalMinutes -gt $rebootDelayMinutes){
    if ($comparedDifference.'wtp-name'){
        Write-Error "Timeout Exceeded, still waiting on the following APs `n $($comparedDifference.'wtp-name' | Out-String)"
    }
    else {
        Write-Error "no APs Detected... Should have $($currentAPData.'wtp-name')"
        return
    }

}

Get-ABCWirelessControllerAPsIPDetails -controller $storeController

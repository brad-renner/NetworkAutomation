# Take user input of AP(s) (xxxxAPyy, where xxxx = store number & y is AP number) & migrate them
# Parameters are passed from user input, select what AP(s) to be migrated
# And what WLC the APs should be migrated to, from user input
# Dryrun either runs the script if "false" or writes the output to screen if "true"
param(
    [Parameter(Mandatory=$True, 
        HelpMessage = 'Input AP(s) to be rebooted, in this format: xxxxAPyy (xxxx = store number & y is the 1 or 2 digit AP number)')]
    [ValidatePattern("^\d{4}AP\d{1,2}$")]
    [string[]]$apList,
    [Parameter(Mandatory=$True, 
        HelpMessage = 'Please chose which WLC the AP(s) should be migrated to from the following options: ABCWLC9800-1, ABCWLC9800-2, ABCWLC9800-3, ABCNWLC9800, ABCLABWLC9800L-1')]
    [ValidateSet("ABCWLC9800-1","ABCWLC9800-2", "ABCWLC9800-3", "ABCNWLC9800", "ABCLABWLC9800L-1")]
    [string]$WLC,
    [switch]$dryrun
)

# Import ABCWirelessOperations Module & Invoke-RebotAP Function 
Import-Module ABCWirelessOperations -Function Invoke-MigrateAP

# Create an array/list for results of each AP rebooting
$resultsList = @()

# Dryrun is selected, pass each AP to Invoke-RebootAP with "dryrun" enabled on the function
if ($dryrun){
    $apList | ForEach-Object {
        Write-Host $_
        Invoke-MigrateAP -apName $_ -WLC $WLC -dryrun
    }
    return
}

# Otherwise pass each AP input to the Invoke-RebootAP & record the results in $resultList
$apList | ForEach-Object {
    # Write-Host $_
    $response = Invoke-MigrateAP $_ -WLC $WLC

    if ($response) {
        Write-Host "Success: $($_ ) was migrated to $($WLC)"
        Write-Host "----------------------------"
        $myhash = @{
            name = $_
            status = "Success"
            WLC = $WLC
        }
        $resultsList += [pscustomobject]$myhash
    }
    else {
        Write-Host "Failure: $($_ ) was NOT migrated to $($WLC)"
        $myhash = @{
            name = $_
            status = "Failure"
            WLC = $WLC
        }
        $resultsList += [pscustomobject]$myhash
    }
}
# Output the $resultList as a nicely formatted table
# Write-Host $($resultsList | Out-String)
$resultsList

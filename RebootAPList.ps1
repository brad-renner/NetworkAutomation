#Take user input of AP(s) (xxxxAPyy, where xxxx = store number & yy is AP number) & reboot them
#Parameters are passed from user input, select what AP(s) to be rebooted
#Dryrun either runs the script if "false" or writes the output to screen if "true"
param(
    [Parameter(Mandatory=$True, 
        HelpMessage = 'Input AP(s) to be rebooted, in this format: xxxxAPyy (xxxx = store number & y is the 1 or 2 digit AP number)')]
    [ValidatePattern("^\d{4}AP\d{1,2}$")]
    [string[]]$apList,
    [switch]$dryrun
)
#Import ABCWirelessOperations Module & Invoke-RebootAP Function 
Import-Module ABCWirelessOperations -Function Invoke-RebootAP

#Create an array/list for results of each AP rebooting
$resultsList = @()

#Dryrun is selected, pass each AP to Invoke-RebootAP with "dryrun" enabled on the function
if ($dryrun){
    $apList | ForEach-Object {
        Write-Host $_
        Invoke-RebootAP -apName $_ -dryrun
    }
    return
}

#Otherwise pass each AP input to the Invoke-RebootAP & record the results in $resultList
$apList | ForEach-Object {
    #Write-Host $_
    $response = Invoke-RebootAP $_

    if ($response) {
        Write-Host "Success: $($_ ) was rebooted"
        Write-Host "----------------------------"
        $myhash = @{
            name = $_
            status = "Success"
        }
        $resultsList += [pscustomobject]$myhash
    }
    else {
        Write-Host "Failure: $($_ ) was NOT rebooted"
        $myhash = @{
            name = $_
            status = "Failure"
        }
        $resultsList += [pscustomobject]$myhash
    }
}
#Output the $resultList as a nicely formatted table
# Write-Host $($resultsList | Out-String)
$resultsList

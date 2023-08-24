# Test Netbox tags, we want to filter Netbox devices per a specific NetBox tag (9800wlc)
# Once the tagged devices are filtered, pass devices (hostname) as arguments to the SaveControllerConfig.ps1 script
# The script will then craft REST METHOD API calls to the devices (via RESTCONF) to save their running config

# Write output about job starting to MS Team Network Automation  
# Import-Module ABCTeamsMessaging -Function Send-MessageToPSUTeamsCoversionJob -ErrorAction 0

# Requires 9800 controller to be tagged in Netbox with '9800wlc' tag
$netboxScheduleTagName ="9800wlc"

# $true means it will run TaggedNetboxDevices.ps1 job without changes (not running SaveControllerConfig.ps1 script)
[switch]$dryRun = $false

# Write output about job's "dryrun status" to MS Team NE Automation 
# Send-MessageToPSUTeamsCoversionJob -MessageText "Starting Netbox device filtering job, TaggedNetboxDevices.ps1 dryRun = $($dryRun)" -ErrorAction 0 | Out-Null

# This is the script that is run to send the RESTCONF Save Config RPC API call, with the parameters to passed to it
$scriptName = 'SaveControllerConfig.ps1'
Write-Host "Script to run is: $($scriptName)"
$Script = Get-PSUScript -Name $scriptName

# Import Netbox modules to filter on devices with the '9800wlc' Netbox tag
Write-Host "Importing Netbox modules..."
Import-Module NetboxABCModule -Function Get-ABCNetboxDevices

# Do some magic here where you would filter devices by $netboxScheduleTagName ('9800wlc') via the Get-ABCNetboxDevice module we imported above
Write-Host "Getting tagged devices from Netbox..."
$devices = Get-ABCNetboxDevices -queryUrl "?status=active&tag=$($netboxScheduleTagName)"
Write-Host "Device info from Netbox found: $(Convertto-Json($devices))"
$deviceList = ($devices.DeviceName)
$deviceCount = ($deviceList).Count
Write-Host "Number of devices found: $($deviceCount)"

# Loop through the devices found and print each one's hostname to the output
[Array]$deviceList | ForEach-Object {
    Write-Host "Device found: $($_)"
}

# If $dryRun is true, only output the devices the script would have run against, but do not actually call the SaveControllerConfig.ps1 script
if  ( $dryRun ){
	Write-Host "Dry Run:'$dryRun' detected, returning $($devicecount) device(s) that match tag '$netboxScheduleTagName' found and exiting"
    #Send-MessageToPSUTeamsCoversionJob -MessageText "Dry Run:'$dryRun' detected, returning devices that match tag '$netboxScheduleTagName' found and exiting... $devices + $deviceList" `
    #    -ErrorAction 0 | Out-Null
}
else {
    # If dryrun is not true, run like usual, specify the params and pass to the SaveControllerConfig.ps1 script
    $j = 0
    $deviceList | ForEach-Object {
        $params = @{
            wlcs 		= $deviceList[$j]
        #    #dryRun		= $false
        }
        # Kicks off SaveControllerConfig job for devices in Netbox that have the $netboxScheduleTagName ("9800wlc")
        Write-Host "Passing parameters: $($deviceList[$j]) to: $scriptName"
        # Send-MessageToPSUTeamsCoversionJob -MessageText "Starting job against device: $($Script.name)"
        Invoke-PSUScript -Script $Script @params
        $j++
    }
}

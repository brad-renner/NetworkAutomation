Import-Module ABCWireless -Function Get-ABCWirelessAPMacs
Import-Module ABCNetboxInventory -Function Get-ABCNetboxSites


$sites = Get-ABCNetboxSites
$storeNumbers = (($sites | Where-Object slug -Match '^store-\d{4}$').name).substring(7,4)


$controllers = @("ABCWLC9800-1", "ABCWLC9800-2", "ABCWLC9800-3")

$macs = $controllers | Foreach-Object -ThrottleLimit 3 -Parallel {
    $theseMacs = Get-ABCWirelessAPMacs -controller $_
    $theseMacs | Add-Member -MemberType NoteProperty -Name "controller" -Value $_ -Force
    $theseMacs
}

$storeNumbers | Foreach-Object{
    Clear-Variable "storeMacs","controller" -EA 0
    $storeMacs = $macs | where-object wtp-name -match $_
    $controller = ($storeMacs | Select-Object controller -Unique).controller

    if (($controller | Measure-Object).Count -gt 1) {
        Write-Host "Store $($_) controllers $($controller)"   
        $storeMacs    
    }
}

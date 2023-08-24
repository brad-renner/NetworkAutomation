param (
    [Parameter(Mandatory=$False)]
    [ValidateSet("GET", "PUT", "PATCH", "POST", "DELETE")]
    $CallVerb,
    [Parameter(Mandatory=$True)]
    [ValidateSet("ABCWLC9800-1", "ABCWLC9800-2", "ABCWLC9800-3", "ABCNWLC9800")]
    [string]$controller,
    [ValidateSet(
        "Cisco-IOS-XE-wireless-ap-cfg:ap-cfg-data/ap-tags/",
        "Cisco-IOS-XE-wireless-ap-cfg:ap-cfg-data/ap-tags/ap-tag",
        "Cisco-IOS-XE-wireless-wlan-cfg:wlan-cfg-data/policy-list-entries",
        "Cisco-IOS-XE-wireless-access-point-oper:access-point-oper-data/oper-data"
        )]
    [string]$module,
    [bool]$getMembers,
    [bool]$toJson,
    [string]$body,
    [bool]$filter,
    [string]$filterProperty,
    [string]$filterValue,
    [bool]$debugScript

)

Import-Module ABCWireless
$headers = New-ABCWirelessHeaders
$uri = "https://$($controller)/restconf/data/$($module)"

$result = Invoke-RestMethod `
    -Uri $uri `
    -Method $CallVerb -Headers $headers -SkipCertificateCheck `
    -Body $body 


$member = ($result | Get-Member -MemberType NoteProperty).name
$result = $result.$($member)


if ($getMembers){
    {Write-Information "members triggered"}
    return $result | Get-Member -MemberType NoteProperty | Select-Object name,definition
}

if ($filter){
    if ($debugScript) {Write-Information "filter triggered"}
    if ($toJson){
        if ($debugScript) {Write-Information "JSON triggered in filter"}
        return $result | Where-Object $filterProperty -match $filterValue | ConvertTo-Json -Depth 10
    }
    else {
        return $result | Where-Object $filterProperty -match $filterValue
        }
}
if ($toJson){
    if ($debugScript) {Write-Information "JSON triggered Solo"}
    $result | ConvertTo-Json -Depth 10
}
else {
    if ($debugScript) {Write-Information "Regular Output triggered"}
    $result
}


param (
    [string]
    $TestStr
)
function Test-IPv4AddressString
{
    param (
        [string]
        $TestStr
    )
    $RegExIPv4Str = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    return $TestStr -match $RegExIPv4Str
}

Test-IPv4AddressString $TestStr
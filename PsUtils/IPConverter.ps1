function Test-IPv4AddressString
{
    param (
        [string]
        $TestStr
    )
    $RegExIPv4Str = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    return $TestStr -match $RegExIPv4Str
}
function Convert-IPv4ToHexString
{
    param (
        [Parameter()]
        [string]
        $IpAddr
    )
    
    if (!(Test-IPv4AddressString($IpAddr)))
    {
        throw 'Not IPv4 Address!'
    }

    $res = '0x'
    $octets = $IpAddr.Split('.')
    foreach ($octet in $octets)
    {
        $strOctetHex = [Convert]::ToByte($octet).ToString("X2")
        $res += $strOctetHex
    }
    return $res
}

function Convert-HexStringToIPv4
{
    param (
        [Parameter()]
        [string]
        $HexString
    )
    
    $res = ''
    for ($i = 2; $i -lt 10; $i += 2)
    {
        $Octet = [Convert]::ToByte($HexString.Substring($i, 2), 16)
        $res += $Octet
        if ($i -ne 8)
        {
            $res += '.'
        }
    }
    return $res
}

function Convert-HexToIPv4
{
    param (
        [Parameter()]
        [int]
        $Hex
    )
    
    $HexString = '0x' + $Hex.ToString('X8')
    return Convert-HexStringToIPv4 -HexString $HexString
}

function Convert-IPv4ToHex
{
    param (
        [Parameter()]
        [string]
        $IpAddr
    )
    
    $HexString = Convert-IPv4ToHexString -IpAddr $IpAddr
    return [Convert]::ToInt32($HexString, 16)
}
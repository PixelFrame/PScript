function Test-IPv4AddressString
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $TestStr
    )
    $RegExIPv4Str = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    return $TestStr -match $RegExIPv4Str
}
function Convert-IPv4ToHexString
{
    param (
        [Parameter(ValueFromPipeline)]
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
        [Parameter(ValueFromPipeline)]
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

function Convert-UInt32ToIPv4
{
    param (
        [Parameter(ValueFromPipeline)]
        [UInt32]
        $Hex
    )
    
    $HexString = '0x' + $Hex.ToString('X8')
    return Convert-HexStringToIPv4 -HexString $HexString
}

function Convert-IPv4ToUInt32
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $IpAddr
    )
    
    $HexString = Convert-IPv4ToHexString -IpAddr $IpAddr
    return [Convert]::ToUInt32($HexString, 16)
}

function Convert-SubnetToIPv4Range
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $Subnet,

        [Switch]
        $UIntOutput
    )
    
    $NetworkId = $Subnet.Split('/')[0]
    $MaskLen = [Convert]::ToInt32($Subnet.Split('/')[1])

    $NetworkIdUInt32 = Convert-IPv4ToUInt32 -IpAddr $NetworkId
    $Mask = [UInt32] 0
    for ($i = 0; $i -lt 32; $i++)
    {
        $Mask = $Mask -shl 1
        if ($MaskLen -gt 0)
        {
            ++$Mask
            --$MaskLen
        }
    }

    $StartingIP = $NetworkIdUInt32 -band $Mask
    $EndingIP = $NetworkIdUInt32 -bor (-bnot $Mask)

    if (!$UIntOutput)
    {
        $StartingIP = Convert-UInt32ToIPv4 $StartingIP
        $EndingIP = Convert-UInt32ToIPv4 $EndingIP
    }

    return @($StartingIP, $EndingIP)
}

Export-ModuleMember -Function *
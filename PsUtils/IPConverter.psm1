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
        $Ipv4Addr
    )
    
    if (!(Test-IPv4AddressString($Ipv4Addr)))
    {
        throw 'Not IPv4 Address!'
    }

    $res = '0x'
    $octets = $Ipv4Addr.Split('.')
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
function Convert-IPv4ToBitString
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $Ipv4Addr
    )
    
    if (!(Test-IPv4AddressString($Ipv4Addr)))
    {
        throw 'Not IPv4 Address!'
    }

    $res = ''
    $octets = $Ipv4Addr.Split('.')
    foreach ($octet in $octets)
    {
        $strOctetHex = [Convert]::ToString([Convert]::ToByte($octet), 2).PadLeft(8, '0')
        $res += $strOctetHex
    }
    return $res
}

function Convert-BitStringToIPv4
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $BitString
    )
    
    $res = ''
    for ($i = 0; $i -lt 32; $i += 8)
    {
        $Octet = [Convert]::ToByte($BitString.Substring($i, 8), 2)
        $res += $Octet
        if ($i -ne 24)
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
        $Num
    )
    
    $HexString = '0x' + $Num.ToString('X8')
    return Convert-HexStringToIPv4 -HexString $HexString
}

function Convert-IPv4ToUInt32
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $Ipv4Addr
    )
    
    $HexString = Convert-IPv4ToHexString -Ipv4Addr $Ipv4Addr
    return [Convert]::ToUInt32($HexString, 16)
}

class IPv4Range
{
    [string]    $BeginningIP;
    [string]    $EndingIP;
    [UInt32]    $BeginningIPNum;
    [UInt32]    $EndingIPNum;

    IPv4Range(
        [string]    $BeginningIP,
        [string]    $EndingIP
    )
    {
        $this.BeginningIP = $BeginningIP
        $this.EndingIP = $EndingIP
        $this.BeginningIPNum = Convert-IPv4ToUInt32 -Ipv4Addr $BeginningIP
        $this.EndingIPNum = Convert-IPv4ToUInt32 -Ipv4Addr $EndingIP
    }

    [string] ToString()
    {
        return "BeginningIP: $this.BeginningIP, EndingIP: $this.EndingIP"
    }
}

function Convert-SubnetToIPv4Range
{
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $Subnet
    )
    
    $NetworkId = $Subnet.Split('/')[0]
    $MaskLen = [Convert]::ToInt32($Subnet.Split('/')[1])

    $NetworkIdUInt32 = Convert-IPv4ToUInt32 -Ipv4Addr $NetworkId
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

    $BeginningIP = $NetworkIdUInt32 -band $Mask
    $EndingIP = $NetworkIdUInt32 -bor (-bnot $Mask)

    if (!$UIntOutput)
    {
        $BeginningIP = Convert-UInt32ToIPv4 $BeginningIP
        $EndingIP = Convert-UInt32ToIPv4 $EndingIP
    }

    return [IPv4Range]::new($BeginningIP, $EndingIP)
}

class IPv4Subnet
{
    [string]    $NetworkId;
    [int]       $MaskLen;
    [string]    $MaskBits;

    IPv4Subnet(
        [string]    $NetworkId,
        [int]       $MaskLen,
        [string]    $MaskBits
    )
    {
        $this.NetworkId = $NetworkId
        $this.MaskLen = $MaskLen
        $this.MaskBits = $MaskBits
    }
}

function Get-SubnetFromIPv4Address
{
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Ipv4Addrs
    )

    $Mask = [UInt32] 0x80000000u
    $Ipv4AddrNums = @()

    foreach ($Ipv4Addr in $Ipv4Addrs)
    {
        $Ipv4AddrNums += Convert-IPv4ToUInt32 -Ipv4Addr $Ipv4Addr
    }

    $MaskLen = 0
    for ($MaskLen = 0; $MaskLen -lt 32; ++$MaskLen)
    {
        $Stop = $false
        $Token = $Ipv4AddrNums[0] -band $Mask
        foreach ($Ipv4AddrNum in $Ipv4AddrNums)
        {
            if ($Token -eq ($Ipv4AddrNum -band $Mask))
            {
                continue
            }
            $Stop = $true
        }
        if ($Stop)
        {
            $Mask = $Mask -shl 1
            break
        }
        $Mask = $Mask -shr 1
        $Mask += [UInt32] 0x80000000u
    }
    $NetworkId = Convert-UInt32ToIPv4 ($Ipv4AddrNum[0] -band $Mask)
    return [IPv4Subnet]::new($NetworkId, $MaskLen, [Convert]::ToString($Mask, 2).PadLeft(32, '0'))
}

Export-ModuleMember -Function *
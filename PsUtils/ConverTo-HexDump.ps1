[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline, ParameterSetName = 'String')]
    [string]
    $InputString = '0x2AA08180000100080000000103777777096D6963726F736F667403636F6D00001C0001C00C00050001000007B1002303777777096D6963726F736F667407636F6D2D632D3307656467656B6579036E657400C02F0005000100000200003703777777096D6963726F736F667407636F6D2D632D3307656467656B6579036E65740B676C6F62616C726564697206616B61646E73C04DC05E000500010000020000190665313336373804647363620A616B616D616965646765C04DC0A1001C000100000014001026001417003F108E000000000000356EC0A1001C000100000014001026001417003F108C000000000000356EC0A1001C000100000014001026001417003F1087000000000000356EC0A1001C000100000014001026001417003F1086000000000000356EC0A1001C000100000014001026001417003F108D000000000000356E0000291000000080000000',

    [Parameter(ValueFromPipeline, ParameterSetName = 'File')]
    [string]
    $InputFile,

    [Parameter()]
    [UInt32]
    $Step = 0x10,

    [Parameter()]
    [switch]
    $ShowDecoded
)

if ($PSCmdlet.ParameterSetName -eq 'File') 
{    
    $RawBinary = Get-Content -Path $InputFile -AsByteStream
    $RawHexString = [BitConverter]::ToString($RawBinary)
} else {
    $RawHexString = $InputString
}

$RegexDenoise = New-Object Regex '[\\\r\n\t, -]|0x'
$RawHexString = $RegexDenoise.Replace($RawHexString, '')
if ($RawHexString.Length % 2) { $RawHexString = '0' + $RawHexString }

$ByteCount = $RawHexString.Length -shr 1
$Offset = 0
$Result = ''
$RegexInsertSpaces = New-Object Regex '..'

while ($ByteCount -gt 0)
{
    if ($ByteCount -lt $Step)
    {
        $__ = $RawHexString.Substring($Offset * 2)
        $Padding = ' ' * (($Step - $ByteCount) * 3)
    }
    else
    {
        $__ = $RawHexString.Substring($Offset * 2, $Step * 2)
        $Padding = ''
    }
    $__ = $RegexInsertSpaces.Replace($__, '$0 ').TrimEnd()
    $DecodedSection = ''
    if ($ShowDecoded)
    {
        $DecodedSection = '  '
        $__.Split(' ') | ForEach-Object {
            $Decoded = [Convert]::ToUInt32($_, 16)
            if (($Decoded -lt 0x20) -or ($Decoded -gt 0x7e -and $Decoded -lt 0xA0))
            {
                $DecodedSection += '.'
            }
            else
            {
                $DecodedSection += [char] $Decoded
            }
        }
    }
    $Result += "$($Offset.ToString('X8'))  $__$Padding$DecodedSection`n"
    $Offset += $Step
    $ByteCount -= $Step
}

$Result
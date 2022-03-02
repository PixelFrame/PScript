[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline, ParameterSetName = 'String')]
    [string]
    $InputString,

    [Parameter(ParameterSetName = 'File')]
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
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $PKTPath = '.\PKT.ps1'
)

Add-Type -AssemblyName System.Windows.Forms

#REGION Widget Callbacks
function onASCII
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexString = SplitOnNull $HexString
    $HexBytes = StringToByteArray($HexString)
    $textBox2.Text = DoConvert 'ASCII' $HexBytes
}
function onUTF8
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexString = SplitOnNull $HexString
    $HexBytes = StringToByteArray($HexString)
    $textBox2.Text = DoConvert 'UTF8' $HexBytes
}

function onUnicode
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexString = SplitOnNull $HexString -Unicode
    $HexBytes = StringToByteArray($HexString)
    $textBox2.Text = DoConvert 'Unicode' $HexBytes
}

function onDnsIP
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    if ($HexBytes.Count -eq 4)
    {
        $Output = DoDnsConvert -Type 1 -HexBytes $HexBytes -IsBigEndian $false
    }
    elseif ($HexBytes.Count -eq 16)
    {
        $Output = DoDnsConvert -Type 28 -HexBytes $HexBytes -IsBigEndian $false
    }
    else
    {
        $Output = "Invalid HEX string"
    }

    $textBox2.Text = $Output
}

function onDnsNodeName
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    $textBox2.Text = DoDnsConvert -Type 12 -HexBytes $HexBytes -IsBigEndian $false
}

function onDnsNameString
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    $textBox2.Text = DoDnsConvert -Type -1 -HexBytes $HexBytes -IsBigEndian $false
}

function onDnsSRV
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    if ([System.Windows.Forms.Control]::ModifierKeys -eq 'Shift')
    {
        $textBox2.Text = DoDnsConvert -Type 33 -HexBytes $HexBytes -IsBigEndian $true
    }
    else
    {
        $textBox2.Text = DoDnsConvert -Type 33 -HexBytes $HexBytes -IsBigEndian $false
    }
}

function onDnsSOA
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    if ([System.Windows.Forms.Control]::ModifierKeys -eq 'Shift')
    {
        $textBox2.Text = DoDnsConvert -Type 6 -HexBytes $HexBytes -IsBigEndian $true
    }
    else
    {
        $textBox2.Text = DoDnsConvert -Type 6 -HexBytes $HexBytes -IsBigEndian $false
    }
}

function onDnsMX
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    if ([System.Windows.Forms.Control]::ModifierKeys -eq 'Shift')
    {
        $textBox2.Text = DoDnsConvert -Type 13 -HexBytes $HexBytes -IsBigEndian $true
    }
    else
    {
        $textBox2.Text = DoDnsConvert -Type 15 -HexBytes $HexBytes -IsBigEndian $false
    }
}

function onDnsTXT
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    $textBox2.Text = DoDnsConvert -Type 16 -HexBytes $HexBytes -IsBigEndian $false
}

function onPKT
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    try
    {
        $PKTObj = [PKT]::new($HexBytes)
        $textBox2.Text = $PKTObj.PrintTree() -join "`r`n"
    }
    catch
    {
        $textBox2.Text = 'Invalid HEX string'
    }
}

function onDnsRecord
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    $DataLength = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 0 -Length 2) -IsBigEndian $false
    $RecordType = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 2 -Length 2) -IsBigEndian $false
    $Version = $HexBytes[4]
    $Rank = $HexBytes[5]
    $Flags = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 6 -Length 2) -IsBigEndian $false
    $Serial = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 8 -Length 4) -IsBigEndian $false
    $TTL = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 12 -Length 4) -IsBigEndian $true
    $Reserved = Convert-BytesToUInt32(Get-SubArray -Source $HexBytes -StartIndex 16 -Length 4) -IsBigEndian $false
    $Timestamp = Convert-BytesToUInt32(Get-SubArray -Source $HexBytes -StartIndex 20 -Length 4) -IsBigEndian $false
    if ($Timestamp -eq 0)
    {
        $TimestampString = 'Static'
    }
    else
    {
        $TimestampString = (Get-Date '01/01/1601 0:0:0').AddHours($Timestamp).ToString('MM/dd/yyyy hh:mm:ss tt')
    }

    $RecordBytes = Get-SubArray -Source $HexBytes -StartIndex 24 -Length $DataLength

    $Output = @"
Data Length:    $DataLength
Record Type:    $([DnsTypes]$RecordType) ($RecordType)
Version:        $Version (Must be 5)
Rank:           $Rank (Usually 240)
Flags:          $Flags (Must be 0)
Serial:         $Serial
TTL:            $TTL
Reserved:       $Reserved (Must be 0)
Timestamp:      $TimestampString
Data:

"@
    $Output += DoDnsConvert -Type $RecordType -HexBytes $RecordBytes -IsBigEndian $true
    $textBox2.Text = $Output
}

function onWordWarp
{
    $textBox2.WordWrap = $checkBox.Checked;
}

function UpdateSelected
{
    $label.Text = "Selected: $($textBox2.SelectionLength)";
}
#ENDREGION

#REGION Auxiliary Functions
function Get-SubArray
{
    param (
        [byte[]] $Source,
        [int] $StartIndex,
        [int] $Length
    )
    
    $Result = New-Object 'byte[]' -ArgumentList $Length
    [Array]::Copy($Source, $StartIndex, $Result, 0, $Length);
    return $Result
}

function Convert-BytesToUInt32
{
    param (
        [byte[]] $Bytes,
        [bool] $IsBigEndian
    )
    if ($Bytes.Length -gt 4)
    {
        throw 'Byte array too long!'
    }
    if ([BitConverter]::IsLittleEndian -and $IsBigEndian)
    {
        [Array]::Reverse($Bytes); 
    }
    return [BitConverter]::ToUInt32($Bytes, 0);
}

function Convert-BytesToUInt16
{
    param (
        [byte[]] $Bytes,
        [bool] $IsBigEndian
    )
    if ($Bytes.Length -gt 2)
    {
        throw 'Byte array too long!'
    }
    if ([BitConverter]::IsLittleEndian -and $IsBigEndian)
    {
        [Array]::Reverse($Bytes); 
    }
    return [BitConverter]::ToUInt16($Bytes, 0);
}

function SplitOnNull
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $HexString,

        [switch]
        $Unicode
    )
    $HexStrBuilder = New-Object 'System.Text.StringBuilder' $HexString
    if ($Unicode)
    {
        for ($i = 0; $i -lt $HexStrBuilder.Length; $i += 4)
        {
            if ($HexStrBuilder[$i] -eq '0' -and $HexStrBuilder[$i + 1] -eq '0' -and $HexStrBuilder[$i + 2] -eq '0' -and $HexStrBuilder[$i + 3] -eq '0')
            {
                $HexStrBuilder[$i] = '2'
            }
        }
    }
    else
    {
        for ($i = 0; $i -lt $HexStrBuilder.Length; $i += 2)
        {
            if (($HexStrBuilder[$i] -eq '0') -and ($HexStrBuilder[$i + 1] -eq '0'))
            {
                $HexStrBuilder[$i] = '2'
            }
        }
    }
    return $HexStrBuilder.ToString()
}

function DoConvert
{
    param (
        [string] $Encoding,
        [byte[]] $HexBytes
    )
    if ($null -eq $HexBytes)
    {
        return 'Invalid HEX string'
    }
    switch ($Encoding)
    {
        'ASCII' { $Result = [System.Text.Encoding]::ASCII.GetString($HexBytes) }
        'UTF8' { $Result = [System.Text.Encoding]::UTF8.GetString($HexBytes) }
        'Unicode' { $Result = [System.Text.Encoding]::Unicode.GetString($HexBytes) }
        Default { $Result = 'Unknown Encoding' }
    }
    return $Result
}

function StringToByteArray
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $HexString
    )
    if ($HexString.Length % 2 -eq 1) { return $null; }
    try
    {
        $arr = New-Object byte[] -ArgumentList ($HexString.Length -shr 1);
        for ($i = 0; $i -lt ($HexString.Length -shr 1); ++$i)
        {
            $arr[$i] = [byte](((GetHexVal($HexString[$i -shl 1])) -shl 4) + (GetHexVal($HexString[($i -shl 1) + 1])));
        }
    }
    catch
    {
        return $null
    }
    return $arr;
}

function GetHexVal
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [char]
        $hex
    )
    $val = [int] $hex;
    if ($val -lt 58) { $val -= 48 }
    elseif ($val -lt 97) { $val -= 55 }
    else { $val -= 87 }
    return $val;
}

function GetDnsNameSegments
{
    param (
        [int] $Index,
        [byte[]] $HexBytes,
        [int] $FullLength
    )
    $Output = ''
    while ($Index -lt $FullLength) 
    {
        $SegLength = [int] $HexBytes[$Index]
        $SegBytes = New-Object 'byte[]' -ArgumentList $SegLength
        [Array]::Copy($HexBytes, $Index + 1, $SegBytes, 0, $SegLength)
        $Seg = [System.Text.Encoding]::UTF8.GetString($SegBytes)
        $Output += "`r`n  ($SegLength)$Seg"
        $Index += ($SegLength + 1)
        # Write-Host "[DBG] CURRENT INDEX $Index"
    }
    return $Output
}

function DoDnsConvert
{
    param (
        [Parameter()]
        [int]
        $Type,

        [Parameter()]
        [byte[]]
        $HexBytes,

        [Parameter()]
        [bool]
        $IsBigEndian
    )
    
    $Output = ''
    switch ($Type)
    {
        1
        { 
            $Output = $HexBytes -join '.'
        }
        28
        {
            for ($i = 0; $i -lt 16; $i += 2)
            {
                $Output += ($HexBytes[$i].ToString('X2') + $HexBytes[$i + 1].ToString('X2'))
                if ($i -ne 14)
                {
                    $Output += ':'
                }
            }
            $ip = [System.Net.IPAddress]::Parse($Output)
            $Output += ("`r`nCompressed: " + $ip.IPAddressToString)
        }
        { $_ -in 2, 5, 12, 39 }
        {
            $NameLength = [int] $HexBytes[0]
            $SegCount = [int] $HexBytes[1]
            $Index = 2
            $Output = @" 
Name Length: $NameLength
Segment Count: $SegCount
Segments:
"@
            $Output += GetDnsNameSegments $Index $HexBytes ($NameLength + 1)
        }
        -1
        {
            $FullLength = [int] $HexBytes[0]
            $NameBytes = New-Object 'byte[]' -ArgumentList $FullLength
            [Array]::Copy($HexBytes, 1, $NameBytes, 0, $FullLength)
            $Name = [System.Text.Encoding]::UTF8.GetString($NameBytes)
            $Output = @" 
Length: $FullLength
Name: $Name
"@
        }
        33
        {
            $Priority = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 0 -Length 2) -IsBigEndian $IsBigEndian
            $Weight = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 2 -Length 2) -IsBigEndian $IsBigEndian
            $Port = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 4 -Length 2) -IsBigEndian $IsBigEndian
            $NameLength = [int] $HexBytes[6]
            $SegCount = [int] $HexBytes[7]
            $Index = 8
            if (!$IsBigEndian)
            {
                $Output = @"
Priority:       $Priority
Weight:         $Weight
Port:           $Port
Name Length:    $NameLength

$(DoConvert -Encoding 'UTF8' -HexBytes (Get-SubArray -Source $HexBytes -StartIndex 7 -Length $NameLength))
"@
            }
            else
            {
                $Output = @"
Priority:       $Priority
Weight:         $Weight
Port:           $Port
Name Length:    $NameLength
Segment Count:  $SegCount
Segments:
"@
                $Output += GetDnsNameSegments $Index $HexBytes ($NameLength + 7)
            }
        }
        6
        {
            $Serial = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 0 -Length 4) -IsBigEndian $IsBigEndian
            $Refresh = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 4 -Length 4) -IsBigEndian $IsBigEndian
            $Retry = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 8 -Length 4) -IsBigEndian $IsBigEndian
            $Expire = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 12 -Length 4) -IsBigEndian $IsBigEndian
            $DefaultTTL = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 16 -Length 4) -IsBigEndian $IsBigEndian
            
            if (!$IsBigEndian)
            {
                $LenPri = [int] $HexBytes[20]
                $LenResp = [int] $HexBytes[21 + $LenPri]
                $Output = @"
Serial number:      $Serial
Refresh interval:   $Refresh
Retry interval:     $Retry
Expires after:      $Expire
Default TTL:        $DefaultTTL

Primary Server:
  Length: $LenPri
  $(DoConvert -Encoding 'UTF8' -HexBytes (Get-SubArray -Source $HexBytes -StartIndex 21 -Length $LenPri))

Responsible Person:
  Length: $LenResp
  $(DoConvert -Encoding 'UTF8' -HexBytes (Get-SubArray -Source $HexBytes -StartIndex (22+$LenPri) -Length $LenResp))
"@
            }
            else
            {
                $LenPri = [int] $HexBytes[20]
                $SegCountPri = [int] $HexBytes[21]
                $LenResp = [int] $HexBytes[20 + $LenPri + 2]
                $SegCountResp = [int] $HexBytes[20 + $LenPri + 3]
                $Output = @"
Serial number:      $Serial
Refresh interval:   $Refresh
Retry interval:     $Retry
Expires after:      $Expire
Default TTL:        $DefaultTTL

Primary Server:
  Length: $LenPri
  Segment Count: $SegCountPri
  $(GetDnsNameSegments 22 $HexBytes ($LenPri + 21))

Responsible Person:
  Length: $LenResp
  Segment Count: $SegCountResp
  $(GetDnsNameSegments (24 + $LenPri) $HexBytes ($LenResp + 23 + $LenPri))
"@
            }
        }
        { $_ -in 15, 18 }
        {
            $Preference = Convert-BytesToUInt16 -Bytes (Get-SubArray -Source $HexBytes -StartIndex 0 -Length 2) -IsBigEndian $IsBigEndian
            $Length = [int] $HexBytes[2]
            $SegCount = [int] $HexBytes[3]

            if (!$IsBigEndian)
            {
                $Output = @"
Preference:     $Preference
Length:         $Length

$(DoConvert -Encoding 'UTF8' -HexBytes (Get-SubArray -Source $HexBytes -StartIndex 3 -Length $Length))
"@
            }
            else
            {
                $Output = @"
Preference:     $Preference
Length:         $Length
Segment Count:  $SegCount
$(GetDnsNameSegments 4 $HexBytes ($Length + 3))
"@
            }
        }
        { $_ -in 13, 16, 29 }
        {
            $Output = "Length: $($HexBytes[0])`r`n"
            $Output += DoConvert -Encoding 'UTF8' -HexBytes (Get-SubArray -Source $HexBytes -StartIndex 1 -Length ($HexBytes.Length - 1))
        }
        Default
        {
            $Output = 'Parsing of this type is NOT implemented'
        }
    }
    return $Output
}

#ENDREGION

#REGION WinForm Design
[System.Windows.Forms.Application]::EnableVisualStyles()

$Version = '1.0.0.0'

$Form = New-Object System.Windows.Forms.Form
$tableLayoutPanel1 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel2 = New-Object System.Windows.Forms.TableLayoutPanel
$groupBox1 = New-Object System.Windows.Forms.GroupBox
$groupBox2 = New-Object System.Windows.Forms.GroupBox
$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox2 = New-Object System.Windows.Forms.TextBox
$buttonAscii = New-Object System.Windows.Forms.Button
$buttonUtf8 = New-Object System.Windows.Forms.Button
$buttonUnicode = New-Object System.Windows.Forms.Button
$buttonDnsIP = New-Object System.Windows.Forms.Button
$buttonDnsNodeName = New-Object System.Windows.Forms.Button
$buttonDnsNameString = New-Object System.Windows.Forms.Button
$buttonDnsSRV = New-Object System.Windows.Forms.Button
$buttonDnsSOA = New-Object System.Windows.Forms.Button
$buttonDnsMX = New-Object System.Windows.Forms.Button
$buttonDnsTXT = New-Object System.Windows.Forms.Button
$buttonPKT = New-Object System.Windows.Forms.Button
$buttonDnsRecord = New-Object System.Windows.Forms.Button
$buttonAbout = New-Object System.Windows.Forms.Button
$checkBox = New-Object System.Windows.Forms.CheckBox
$label = New-Object System.Windows.Forms.Label

$Form.ClientSize = New-Object System.Drawing.Point(1000, 600)
$Form.Text = "HEX Converter"
$Form.TopMost = $false

$tableLayoutPanel1.ColumnCount = 1;
$tableLayoutPanel1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$tableLayoutPanel1.Controls.Add($groupBox2, 0, 1) | Out-Null
$tableLayoutPanel1.Controls.Add($groupBox1, 0, 0) | Out-Null
$tableLayoutPanel1.Controls.Add($tableLayoutPanel2, 0, 2) | Out-Null
$tableLayoutPanel1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$tableLayoutPanel1.Location = New-Object System.Drawing.Point -ArgumentList @(0, 0);
$tableLayoutPanel1.Name = "tableLayoutPanel1";
$tableLayoutPanel1.RowCount = 3;
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 40))) | Out-Null
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 40))) | Out-Null
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null

$tableLayoutPanel2.ColumnCount = 8;
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 12.5))) | Out-Null
$tableLayoutPanel2.RowCount = 3;
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 25))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 25))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 25))) | Out-Null
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 25))) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonAscii, 0, 0) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonUtf8, 1, 0) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonUnicode, 2, 0) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsIP, 0, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsNodeName, 1, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsNameString, 2, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsSRV, 3, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsSOA, 4, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsMX, 5, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsTXT, 6, 1) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonPKT, 0, 2) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonDnsRecord, 1, 2) | Out-Null
$tableLayoutPanel2.Controls.Add($checkBox, 0, 3) | Out-Null
$tableLayoutPanel2.Controls.Add($label, 1, 3) | Out-Null
$tableLayoutPanel2.Controls.Add($buttonAbout, 7, 3) | Out-Null
$tableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$tableLayoutPanel2.Name = "tableLayoutPanel2";

$groupBox1.Controls.Add($textBox1) | Out-Null
$groupBox1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$groupBox1.Name = "groupBox1";
$groupBox1.TabStop = $false;
$groupBox1.Text = "HEX";

$groupBox2.Controls.Add($textBox2) | Out-Null
$groupBox2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$groupBox2.Name = "groupBox2";
$groupBox2.TabStop = $false;
$groupBox2.Text = "STRING";

$textBox1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$textBox1.Multiline = $true;
$textBox1.Name = "textBox1";
$textBox1.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical;
$textBox1.Font = New-Object System.Drawing.Font('Consolas', 10);
$textBox1.TabIndex = 0

$textBox2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$textBox2.Multiline = $true;
$textBox2.Name = "textBox2";
$textBox2.ReadOnly = $true;
$textBox2.ScrollBars = [System.Windows.Forms.ScrollBars]::Both;
$textBox2.WordWrap = $false;
$textBox2.Font = New-Object System.Drawing.Font('Consolas', 10);
$textBox2.HideSelection = $false;
$textBox2.Add_Click( { UpdateSelected } ) | Out-Null
$textBox2.TabStop = $false

$buttonAscii.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonAscii.Name = "buttonAscii";
$buttonAscii.Text = "ASCII";
$buttonAscii.UseVisualStyleBackColor = $true;
$buttonAscii.Add_Click( { onASCII }) | Out-Null

$buttonUtf8.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonUtf8.Name = "buttonUtf8";
$buttonUtf8.Text = "UTF8";
$buttonUtf8.UseVisualStyleBackColor = $true;
$buttonUtf8.Add_Click( { onUTF8 }) | Out-Null

$buttonUnicode.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonUnicode.Name = "buttonUnicode";
$buttonUnicode.Text = "Unicode";
$buttonUnicode.UseVisualStyleBackColor = $true;
$buttonUnicode.Add_Click( { onUnicode }) | Out-Null

$buttonDnsIP.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsIP.Name = "buttonDnsIP";
$buttonDnsIP.Text = "A(1)/AAAA(28)";
$buttonDnsIP.UseVisualStyleBackColor = $true;
$buttonDnsIP.Add_Click( { onDnsIP }) | Out-Null

$buttonDnsNodeName.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsNodeName.Name = "buttonDnsNodeName";
$buttonDnsNodeName.Text = "Name(2,5,12,39)";
$buttonDnsNodeName.UseVisualStyleBackColor = $true;
$buttonDnsNodeName.Add_Click( { onDnsNodeName }) | Out-Null

$buttonDnsNameString.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsNameString.Name = "buttonDnsNameString";
$buttonDnsNameString.Text = "Name String(5)";
$buttonDnsNameString.UseVisualStyleBackColor = $true;
$buttonDnsNameString.Add_Click( { onDnsNameString }) | Out-Null

$buttonDnsSRV.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsSRV.Name = "buttonDnsSRV";
$buttonDnsSRV.Text = "SRV(33)";
$buttonDnsSRV.UseVisualStyleBackColor = $true;
$buttonDnsSRV.Add_Click( { onDnsSRV }) | Out-Null

$buttonDnsSOA.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsSOA.Name = "buttonDnsSOA";
$buttonDnsSOA.Text = "SOA(6)";
$buttonDnsSOA.UseVisualStyleBackColor = $true;
$buttonDnsSOA.Add_Click( { onDnsSOA }) | Out-Null

$buttonDnsMX.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsMX.Name = "buttonDnsMX";
$buttonDnsMX.Text = "MX(15)";
$buttonDnsMX.UseVisualStyleBackColor = $true;
$buttonDnsMX.Add_Click( { onDnsMX }) | Out-Null

$buttonDnsTXT.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsTXT.Name = "buttonDnsTXT";
$buttonDnsTXT.Text = "TXT(16)";
$buttonDnsTXT.UseVisualStyleBackColor = $true;
$buttonDnsTXT.Add_Click( { onDnsTXT }) | Out-Null

if (Test-Path $PKTPath)
{
    . $PKTPath
}
else
{
    Write-Host '[WARNING] Cannot find PKT.ps1. DFSN PKT conversion will not be available.' -ForegroundColor Yellow
    $buttonPKT.Enabled = $false
}
$buttonPKT.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonPKT.Name = "buttonPKT";
$buttonPKT.Text = "PKT";
$buttonPKT.UseVisualStyleBackColor = $true;
$buttonPKT.Add_Click( { onPKT }) | Out-Null

$buttonDnsRecord.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsRecord.Name = "buttonDnsRecord";
$buttonDnsRecord.Text = "DNS Record";
$buttonDnsRecord.UseVisualStyleBackColor = $true;
$buttonDnsRecord.Add_Click( { onDnsRecord }) | Out-Null

$buttonAbout.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonAbout.Name = "buttonAbout";
$buttonAbout.Text = "About";
$buttonAbout.UseVisualStyleBackColor = $true;
$buttonAbout.Add_Click( { [System.Windows.Forms.MessageBox]::Show("HEX CONVERTER`r`nVersion: $Version`r`nWritten by PixelFrame`r`nEXE version created with PS2EXE", 'About') }) | Out-Null

$checkBox.Name = "checkBox";
$checkBox.Text = "Word Wrap";
$checkBox.Checked = $false;
$checkBox.CheckState = [System.Windows.Forms.CheckState]::Unchecked;
$checkBox.Add_Click( { onWordWarp } ) | Out-Null

$label.Name = "label";
$label.Text = "Selected: $($textBox2.SelectionLength)";
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft;

$Form.Controls.AddRange(@($tableLayoutPanel1))

$Form.ShowDialog() | Out-Null
#ENDREGION

#REGION Supporting Classes
enum DnsTypes
{
    UNKNOWN
    A = 1
    NS = 2
    CNAME = 5
    SOA = 6
    PTR = 12
    HINFO = 13
    MX = 15
    TXT = 16
    RP = 17
    AFSDB = 18
    SIG = 24
    KEY = 25
    AAAA = 28
    LOC = 29
    SRV = 33
    NAPTR = 35
    KX = 36
    CERT = 37
    DNAME = 39
    APL = 42
    DS = 43
    SSHFP = 44
    IPSECKEY = 45
    RRSIG = 46
    NSEC = 47
    DNSKEY = 48
    DHCID = 49
    NSEC3 = 50
    NSEC3PARAM = 51
    TLSA = 52
    SMIMEA = 53
    HIP = 55
    CDS = 59
    CDNSKEY = 60
    OPENPGPKEY = 61
    CSYNC = 62
    ZONEMD = 63
    SVCB = 64
    HTTPS = 65
    EUI48 = 108
    EUI64 = 109
    TKEY = 249
    TSIG = 250
    URI = 256
    CAA = 257
    TA = 32768
    DLV = 32769
}
#ENDREGION
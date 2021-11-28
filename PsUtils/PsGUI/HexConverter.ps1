Add-Type -AssemblyName System.Windows.Forms

#REGION Widget Callbacks
function onASCII
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexString = SplitOnNull $HexString
    $textBox2.Text = DoConvert 'ASCII' $HexString
}
function onUTF8
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexString = SplitOnNull $HexString
    $textBox2.Text = DoConvert 'UTF8' $HexString
}

function onUnicode
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexString = SplitOnNull $HexString -Unicode
    $textBox2.Text = DoConvert 'Unicode' $HexString
}

function onDnsA
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    if ($HexBytes.Count -ne 4)
    {
        $Output = "Invalid Hex string"
    }
    else
    {
        $Output = $HexBytes -join '.'
    }

    $textBox2.Text = $Output
}

function onDnsPTR
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    $FullLength = [int] $HexBytes[0]
    $SegCount = [int] $HexBytes[1]
    $Index = 2
    $Output = @" 
Length: $FullLength
Segment Count: $SegCount
Segments:
"@

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

    $textBox2.Text = $Output
}

function onDnsCNAME
{
    $RegexPattern = New-Object regex '[\\\r\n\t, ]|0x'
    $HexString = $RegexPattern.Replace($textBox1.Text, '')
    $HexBytes = StringToByteArray($HexString)

    $FullLength = [int] $HexBytes[0]
    $NameBytes = New-Object 'byte[]' -ArgumentList $FullLength
    [Array]::Copy($HexBytes, 1, $NameBytes, 0, $FullLength)
    $Name = [System.Text.Encoding]::UTF8.GetString($NameBytes)
    $Output = @" 
Length: $FullLength
Name: $Name
"@

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
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Encoding,

        [Parameter()]
        [string]
        $HexString
    )
    # Write-Host "[DBG] $HexString"
    $HexBytes = StringToByteArray($HexString)
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
#ENDREGION

#REGION WinForm Design
[System.Windows.Forms.Application]::EnableVisualStyles()

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
$buttonDnsA = New-Object System.Windows.Forms.Button
$buttonDnsPTR = New-Object System.Windows.Forms.Button
$buttonDnsCNAME = New-Object System.Windows.Forms.Button
$checkBox = New-Object System.Windows.Forms.CheckBox
$label = New-Object System.Windows.Forms.Label

$Form.ClientSize = New-Object System.Drawing.Point(800, 450)
$Form.Text = "HEX Converter"
$Form.TopMost = $false
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false

$tableLayoutPanel1.ColumnCount = 1;
$tableLayoutPanel1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 100)));
$tableLayoutPanel1.Controls.Add($groupBox2, 0, 1);
$tableLayoutPanel1.Controls.Add($groupBox1, 0, 0);
$tableLayoutPanel1.Controls.Add($tableLayoutPanel2, 0, 2);
$tableLayoutPanel1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$tableLayoutPanel1.Location = New-Object System.Drawing.Point -ArgumentList @(0, 0);
$tableLayoutPanel1.Name = "tableLayoutPanel1";
$tableLayoutPanel1.RowCount = 3;
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 50)));
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 50)));
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 70)));
$tableLayoutPanel1.Size = New-Object System.Drawing.Size -ArgumentList @(800, 450);

$tableLayoutPanel2.ColumnCount = 5;
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 100)));
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 100)));
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 100)));
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 100)));
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 300)));
$tableLayoutPanel2.RowCount = 2;
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 50)));
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 50)));
$tableLayoutPanel2.Controls.Add($buttonAscii, 0, 0);
$tableLayoutPanel2.Controls.Add($buttonUtf8, 1, 0);
$tableLayoutPanel2.Controls.Add($buttonUnicode, 2, 0);
$tableLayoutPanel2.Controls.Add($buttonDnsA, 0, 1);
$tableLayoutPanel2.Controls.Add($buttonDnsPTR, 1, 1);
$tableLayoutPanel2.Controls.Add($buttonDnsCNAME, 2, 1);
$tableLayoutPanel2.Controls.Add($checkBox, 3, 0);
$tableLayoutPanel2.Controls.Add($label, 4, 0);
$tableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$tableLayoutPanel2.Size = New-Object System.Drawing.Size -ArgumentList @(800, 30);
$tableLayoutPanel2.Name = "tableLayoutPanel2";

$groupBox1.Controls.Add($textBox1);
$groupBox1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$groupBox1.Name = "groupBox1";
$groupBox1.TabStop = $false;
$groupBox1.Text = "HEX";

$groupBox2.Controls.Add($textBox2);
$groupBox2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$groupBox2.Name = "groupBox2";
$groupBox2.TabStop = $false;
$groupBox2.Text = "STRING";

$textBox1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$textBox1.Multiline = $true;
$textBox1.Name = "textBox1";
$textBox1.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical;
$textBox1.Font = New-Object System.Drawing.Font('Consolas', 10);

$textBox2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$textBox2.Multiline = $true;
$textBox2.Name = "textBox2";
$textBox2.ReadOnly = $true;
$textBox2.ScrollBars = [System.Windows.Forms.ScrollBars]::Both;
$textBox2.WordWrap = $false;
$textBox2.Font = New-Object System.Drawing.Font('Consolas', 10);
$textBox2.HideSelection = $false;
$textBox2.Add_Click( { UpdateSelected } );

$buttonAscii.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonAscii.Name = "buttonAscii";
$buttonAscii.Text = "ASCII";
$buttonAscii.UseVisualStyleBackColor = $true;
$buttonAscii.Add_Click( { onASCII });

$buttonUtf8.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonUtf8.Name = "buttonUtf8";
$buttonUtf8.Text = "UTF8";
$buttonUtf8.UseVisualStyleBackColor = $true;
$buttonUtf8.Add_Click( { onUTF8 });

$buttonUnicode.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonUnicode.Name = "buttonUnicode";
$buttonUnicode.Text = "Unicode";
$buttonUnicode.UseVisualStyleBackColor = $true;
$buttonUnicode.Add_Click( { onUnicode });

$buttonDnsA.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsA.Name = "buttonDnsA";
$buttonDnsA.Text = "DNS A";
$buttonDnsA.UseVisualStyleBackColor = $true;
$buttonDnsA.Add_Click( { onDnsA });

$buttonDnsPTR.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsPTR.Name = "buttonDnsPTR";
$buttonDnsPTR.Text = "DNS PTR";
$buttonDnsPTR.UseVisualStyleBackColor = $true;
$buttonDnsPTR.Add_Click( { onDnsPTR });

$buttonDnsCNAME.Dock = [System.Windows.Forms.DockStyle]::Fill;
$buttonDnsCNAME.Name = "buttonDnsCNAME";
$buttonDnsCNAME.Text = "DNS CNAME";
$buttonDnsCNAME.UseVisualStyleBackColor = $true;
$buttonDnsCNAME.Add_Click( { onDnsCNAME });

$checkBox.Name = "checkBox";
$checkBox.Text = "Word Wrap";
$checkBox.Checked = $false;
$checkBox.CheckState = [System.Windows.Forms.CheckState]::Unchecked;
$checkBox.Add_Click( { onWordWarp } );

$label.Name = "label";
$label.Text = "Selected: $($textBox2.SelectionLength)";
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft;

$Form.Controls.AddRange(@($tableLayoutPanel1))

$Form.ShowDialog()
#ENDREGION

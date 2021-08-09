Add-Type -AssemblyName System.Windows.Forms

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
    Write-Host "[DBG] $HexString"
    $HexBytes = StringToByteArray($HexString)
    if ($null -eq $HexBytes)
    {
        $Result = 'Invalid HEX string'
        return
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
    return $val - ($val -lt 58 ? 48 : ($val -lt 97 ? 55 : 87));
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object System.Windows.Forms.Form
$tableLayoutPanel1 = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayoutPanel2 = New-Object System.Windows.Forms.TableLayoutPanel
$groupBox1 = New-Object System.Windows.Forms.GroupBox
$groupBox2 = New-Object System.Windows.Forms.GroupBox
$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox2 = New-Object System.Windows.Forms.TextBox
$button1 = New-Object System.Windows.Forms.Button
$button2 = New-Object System.Windows.Forms.Button
$button3 = New-Object System.Windows.Forms.Button

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
$tableLayoutPanel1.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 30)));
$tableLayoutPanel1.Size = New-Object System.Drawing.Size -ArgumentList @(800, 450);

$tableLayoutPanel2.ColumnCount = 3;
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 80)));
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 80)));
$tableLayoutPanel2.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle -ArgumentList @([System.Windows.Forms.SizeType]::Absolute, 80)));
$tableLayoutPanel2.RowCount = 1;
$tableLayoutPanel2.RowStyles.Add((New-Object System.Windows.Forms.RowStyle -ArgumentList @([System.Windows.Forms.SizeType]::Percent, 100)));
$tableLayoutPanel2.Controls.Add($button1, 0, 0);
$tableLayoutPanel2.Controls.Add($button2, 1, 0);
$tableLayoutPanel2.Controls.Add($button3, 2, 0);
$tableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$tableLayoutPanel1.Size = New-Object System.Drawing.Size -ArgumentList @(800, 30);
$tableLayoutPanel2.Name = "tableLayoutPanel2";

$groupBox1.Controls.Add($textBox1);
$groupBox1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$groupBox1.Location = New-Object System.Drawing.Point -ArgumentList @(3, 3);
$groupBox1.Name = "groupBox1";
$groupBox1.Size = New-Object System.Drawing.Size -ArgumentList @(794, 204);
$groupBox1.TabIndex = 0;
$groupBox1.TabStop = $false;
$groupBox1.Text = "HEX";

$groupBox2.Controls.Add($textBox2);
$groupBox2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$groupBox2.Location = New-Object System.Drawing.Point -ArgumentList @(3, 213);
$groupBox2.Name = "groupBox2";
$groupBox2.Size = New-Object System.Drawing.Size -ArgumentList @(794, 204);
$groupBox2.TabStop = $false;
$groupBox2.Text = "STRING";

$textBox1.Dock = [System.Windows.Forms.DockStyle]::Fill;
$textBox1.Location = New-Object System.Drawing.Point -ArgumentList @(3, 19);
$textBox1.Multiline = $true;
$textBox1.Name = "textBox1";
$textBox1.Size = New-Object System.Drawing.Size -ArgumentList @(788, 182);
$textBox1.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical;
$textBox1.Font = New-Object System.Drawing.Font('Consolas', 10);

$textBox2.Dock = [System.Windows.Forms.DockStyle]::Fill;
$textBox2.Location = New-Object System.Drawing.Point -ArgumentList @(3, 19);
$textBox2.Multiline = $true;
$textBox2.Name = "textBox2";
$textBox2.ReadOnly = $true;
$textBox2.Size = New-Object System.Drawing.Size -ArgumentList @(788, 182);
$textBox2.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical;
$textBox2.Font = New-Object System.Drawing.Font('Consolas', 10);

$button1.Location = New-Object System.Drawing.Point -ArgumentList @(3, 423);
$button1.Name = "button1";
$button1.Size = New-Object System.Drawing.Size -ArgumentList @(75, 23);
$button1.Text = "ASCII";
$button1.UseVisualStyleBackColor = $true;
$button1.Add_Click( { onASCII })

$button2.Location = New-Object System.Drawing.Point -ArgumentList @(81, 423);
$button2.Name = "button2";
$button2.Size = New-Object System.Drawing.Size -ArgumentList @(75, 23);
$button2.Text = "UTF8";
$button2.UseVisualStyleBackColor = $true;
$button2.Add_Click( { onUTF8 })

$button3.Location = New-Object System.Drawing.Point -ArgumentList @(159, 423);
$button3.Name = "button3";
$button3.Size = New-Object System.Drawing.Size -ArgumentList @(75, 23);
$button3.Text = "Unicode";
$button3.UseVisualStyleBackColor = $true;
$button3.Add_Click( { onUnicode })

$Form.Controls.AddRange(@($tableLayoutPanel1))

$Form.ShowDialog()


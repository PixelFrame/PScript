<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    BwCalc
#>

[string[]] $cbdBandwidth = @('GByte/s', 'MByte/s', 'KByte/s', 'Byte/s', 'GBit/s', 'MBit/s', 'KBit/s', 'Bit/s')
[string[]] $cbdWindow = @(0..16)
[string[]] $cbdRtt = @('second', 'millisecond', 'nanosecond')

[double] $dBandwidth = 0    # Byte/Second
[double] $dWindow = 0       # Byte
[double] $dRtt = 10000      # NanoSecond

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$MainForm = New-Object system.Windows.Forms.Form
$MainForm.ClientSize = New-Object System.Drawing.Point(620, 170)
$MainForm.text = "Bandwidth Calculator Advanced"
$MainForm.TopMost = $false
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$MainForm.MaximizeBox = $false

$AboutForm = New-Object system.Windows.Forms.Form
$AboutForm.ClientSize = New-Object System.Drawing.Point(300, 100)
$AboutForm.text = "About: Bandwidth Calculator Advanced"
$AboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$AboutForm.MaximizeBox = $false

$cbBwUnit = New-Object system.Windows.Forms.ComboBox
$cbBwUnit.text = "comboBox"
$cbBwUnit.width = 100
$cbBwUnit.height = 20
$cbBwUnit.location = New-Object System.Drawing.Point(130, 19)
$cbBwUnit.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$cbBwUnit.Items.AddRange($cbdBandwidth)
$cbBwUnit.SelectedIndex = 0
$cbBwUnit.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

$cbRttUnit = New-Object system.Windows.Forms.ComboBox
$cbRttUnit.text = "comboBox"
$cbRttUnit.width = 100
$cbRttUnit.height = 20
$cbRttUnit.location = New-Object System.Drawing.Point(130, 96)
$cbRttUnit.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$cbRttUnit.Items.AddRange($cbdRtt)
$cbRttUnit.SelectedIndex = 1
$cbRttUnit.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

$cbWinUnit = New-Object system.Windows.Forms.ComboBox
$cbWinUnit.text = "comboBox"
$cbWinUnit.width = 100
$cbWinUnit.height = 20
$cbWinUnit.location = New-Object System.Drawing.Point(130, 56)
$cbWinUnit.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$cbWinUnit.Items.AddRange($cbdWindow)
$cbWinUnit.SelectedIndex = 0
$cbWinUnit.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

$lbBandwidth = New-Object system.Windows.Forms.Label
$lbBandwidth.text = "Bandwidth: "
$lbBandwidth.AutoSize = $true
$lbBandwidth.width = 25
$lbBandwidth.height = 20
$lbBandwidth.location = New-Object System.Drawing.Point(15, 19)
$lbBandwidth.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$lbWIndow = New-Object system.Windows.Forms.Label
$lbWIndow.text = "Window Size: "
$lbWIndow.AutoSize = $true
$lbWIndow.width = 25
$lbWIndow.height = 20
$lbWIndow.location = New-Object System.Drawing.Point(15, 56)
$lbWIndow.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$lbRtt = New-Object system.Windows.Forms.Label
$lbRtt.text = "Round Trip Time: "
$lbRtt.AutoSize = $true
$lbRtt.width = 25
$lbRtt.height = 20
$lbRtt.location = New-Object System.Drawing.Point(15, 96)
$lbRtt.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$tbBandwidth = New-Object system.Windows.Forms.TextBox
$tbBandwidth.multiline = $false
$tbBandwidth.width = 250
$tbBandwidth.height = 20
$tbBandwidth.location = New-Object System.Drawing.Point(250, 17)
$tbBandwidth.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbBandwidth.Text = 0

$tbWindow = New-Object system.Windows.Forms.TextBox
$tbWindow.multiline = $false
$tbWindow.width = 120
$tbWindow.height = 20
$tbWindow.location = New-Object System.Drawing.Point(250, 55)
$tbWindow.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbWindow.Text = 0

$tbWinCalced = New-Object system.Windows.Forms.TextBox
$tbWinCalced.multiline = $false
$tbWinCalced.width = 120
$tbWinCalced.height = 20
$tbWinCalced.enabled = $false
$tbWinCalced.location = New-Object System.Drawing.Point(380, 55)
$tbWinCalced.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbWinCalced.Text = 0

$tbRtt = New-Object system.Windows.Forms.TextBox
$tbRtt.multiline = $false
$tbRtt.width = 250
$tbRtt.height = 20
$tbRtt.location = New-Object System.Drawing.Point(250, 96)
$tbRtt.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbRtt.Text = 10

$btnBandwidth = New-Object system.Windows.Forms.Button
$btnBandwidth.text = "Get BW"
$btnBandwidth.width = 75
$btnBandwidth.height = 25
$btnBandwidth.location = New-Object System.Drawing.Point(527, 15)
$btnBandwidth.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnWindow = New-Object system.Windows.Forms.Button
$btnWindow.text = "Get Win"
$btnWindow.width = 75
$btnWindow.height = 25
$btnWindow.location = New-Object System.Drawing.Point(527, 54)
$btnWindow.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnRtt = New-Object system.Windows.Forms.Button
$btnRtt.text = "Get RTT"
$btnRtt.width = 75
$btnRtt.height = 25
$btnRtt.location = New-Object System.Drawing.Point(527, 94)
$btnRtt.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnRst = New-Object system.Windows.Forms.Button
$btnRst.text = "Reset"
$btnRst.width = 75
$btnRst.height = 25
$btnRst.location = New-Object System.Drawing.Point(527, 130)
$btnRst.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$btnAbout = New-Object system.Windows.Forms.Button
$btnAbout.text = "About"
$btnAbout.width = 75
$btnAbout.height = 25
$btnAbout.location = New-Object System.Drawing.Point(447, 130)
$btnAbout.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$MainForm.controls.AddRange(@($cbBwUnit, $lbBandwidth, $lbWIndow, $lbRtt, $cbRttUnit, $cbWinUnit, $tbBandwidth, $tbWindow, $tbRtt, $btnBandwidth, $btnWindow, $btnRtt, $btnRst, $btnAbout, $tbWinCalced))

$lbAbout = New-Object system.Windows.Forms.Label
$lbAbout.text = "Bandwidth Calculator Advanced v0.1-alpha`nWritten by Pixel Frame`nFor PowerShell 5.0+"
$lbAbout.AutoSize = $true
$lbAbout.location = New-Object System.Drawing.Point(10, 10)
$lbAbout.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$AboutForm.Controls.AddRange(@($lbAbout))

$btnBandwidth.Add_Click( { onClickBw })
$btnWindow.Add_Click( { onClickWindow })
$btnRtt.Add_Click( { onClickRtt })
$btnRst.Add_Click( { onClickRst })
$btnAbout.Add_Click( { onClickAbout })
$cbBwUnit.Add_SelectedIndexChanged( { onSelectBw })
$cbWinUnit.Add_SelectedIndexChanged( { onSelectWin })
$cbRttUnit.Add_SelectedIndexChanged( { onSelectRtt } )
$tbBandwidth.Add_TextChanged( { onBwInput })
$tbWindow.Add_TextChanged( { onWinInput })
$tbRtt.Add_TextChanged( { onRttInput })

function onClickRst
{
    $Global:dWindow = 0
    $Global:dRtt = 10000
    $Global:dBandwidth = 0
    $cbBwUnit.SelectedIndex = 0
    $cbWinUnit.SelectedIndex = 0
    $cbRttUnit.SelectedIndex = 1
    $tbBandwidth.Text = 0
    $tbWindow.Text = 0
    $tbWinCalced.Text = 0
    $tbRtt.Text = 10
}
function onClickRtt
{
    calcRtt
    onSelectRtt
}
function onClickWindow
{
    calcWindow
    $tbWinCalced.Text = $Global:dWindow
    $tbWindow.Text = $Global:dWindow / ([Math]::Pow(2, $cbWinUnit.SelectedIndex))
}
function onClickBw
{ 
    calcBandwidth
    onSelectBw
}

function onClickAbout
{
    $AboutForm.ShowDialog()
}

function calcBandwidth
{
    $Global:dBandwidth = $Global:dWindow / ($Global:dRtt / 1000000)
}

function calcWindow
{
    $Global:dWindow = $Global:dBandwidth * ($Global:dRtt / 1000000)
}

function calcRtt
{
    $Global:dRtt = $Global:dWindow * 1000000 / $Global:dBandwidth
}

function onSelectBw
{
    $txtValue = 0
    switch ($cbBwUnit.SelectedIndex)
    {
        0 { $txtValue = $Global:dBandwidth / 1024 / 1024 / 1024 }
        1 { $txtValue = $Global:dBandwidth / 1024 / 1024 }
        2 { $txtValue = $Global:dBandwidth / 1024 }
        3 { $txtValue = $Global:dBandwidth }
        4 { $txtValue = $Global:dBandwidth * 8 / 1024 / 1024 / 1024 }
        5 { $txtValue = $Global:dBandwidth * 8 / 1024 / 1024 }
        6 { $txtValue = $Global:dBandwidth * 8 / 1024 }
        7 { $txtValue = $Global:dBandwidth * 8 }
        Default {}
    }
    $tbBandwidth.Text = $txtValue.ToString()
}

function onSelectWin
{
    $txtValue = [double]::Parse($tbWindow.Text)
    $Global:dWindow = $txtValue * [Math]::Pow(2, $cbWinUnit.SelectedIndex)
    $tbWinCalced.Text = $Global:dWindow.ToString()
}

function onSelectRtt
{
    $txtValue = 0
    switch ($cbRttUnit.SelectedIndex)
    {
        0 { $txtValue = $Global:dRtt / 1000 / 1000 }
        1 { $txtValue = $Global:dRtt / 1000 }
        2 { $txtValue = $Global:dRtt }
        Default {}
    }
    $tbRtt.Text = $txtValue.ToString()
}

function onBwInput
{
    $txtValue = [double]::Parse($tbBandwidth.Text)
    switch ($cbBwUnit.SelectedIndex)
    {
        0 { $Global:dBandwidth = $txtValue * 1024 * 1024 * 1024 }
        1 { $Global:dBandwidth = $txtValue * 1024 * 1024 }
        2 { $Global:dBandwidth = $txtValue * 1024 }
        3 { $Global:dBandwidth = $txtValue }
        4 { $Global:dBandwidth = $txtValue * 1024 * 1024 * 1024 / 8 }
        5 { $Global:dBandwidth = $txtValue * 1024 * 1024 / 8 }
        6 { $Global:dBandwidth = $txtValue * 1024 / 8 }
        7 { $Global:dBandwidth = $txtValue / 8 }
        Default {}
    }
    $tbBandwidth.Text = $txtValue
}

function onWinInput
{
    $txtValue = 0
    if (![double]::TryParse($tbWindow.Text, [ref] $txtValue))
    {
        $txtValue = 0
        $tbWindow.Text = ''
    }
    $Global:dWindow = $txtValue * [Math]::Pow(2, $cbWinUnit.SelectedIndex)
    $tbWinCalced.Text = $Global:dWindow.ToString()
}

function onRttInput
{
    $txtValue = [double]::Parse($tbRtt.Text)
    switch ($cbRttUnit.SelectedIndex)
    {
        0 { $Global:dRtt = $txtValue * 1000 * 1000 }
        1 { $Global:dRtt = $txtValue * 1000 }
        2 { $Global:dRtt = $txtValue }
        Default {}
    }
    $tbRtt.Text = $txtValue
}

function dbgPrint
{
    Write-Host ("[DBG] Bandwidth: " + $Global:dBandwidth)
    Write-Host ("[DBG] Window: " + $Global:dWindow)
    Write-Host ("[DBG] RTT: " + $Global:dRtt)
}

[void]$MainForm.ShowDialog()

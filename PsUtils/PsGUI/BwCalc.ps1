<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    BwCalc
.SYNOPSIS
    Bandwidth Calculator
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = New-Object System.Drawing.Point(410, 175)
$Form.text = "Bandwidth Calculator"
$Form.TopMost = $false
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false

$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline = $false
$TextBox1.width = 236
$TextBox1.height = 20
$TextBox1.location = New-Object System.Drawing.Point(151, 20)
$TextBox1.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$TextBox1.Text = 0

$TextBox2 = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline = $false
$TextBox2.width = 236
$TextBox2.height = 20
$TextBox2.location = New-Object System.Drawing.Point(151, 58)
$TextBox2.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$TextBox2.Text = 0

$TextBox3 = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline = $false
$TextBox3.width = 236
$TextBox3.height = 20
$TextBox3.location = New-Object System.Drawing.Point(151, 95)
$TextBox3.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$TextBox3.Text = 100

$Label1 = New-Object system.Windows.Forms.Label
$Label1.text = "Bandwidth (MByte/s)"
$Label1.AutoSize = $true
$Label1.width = 25
$Label1.height = 10
$Label1.location = New-Object System.Drawing.Point(19, 20)
$Label1.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Label2 = New-Object system.Windows.Forms.Label
$Label2.text = "Window Size (Byte)"
$Label2.AutoSize = $true
$Label2.width = 25
$Label2.height = 10
$Label2.location = New-Object System.Drawing.Point(19, 58)
$Label2.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Label3 = New-Object system.Windows.Forms.Label
$Label3.text = "Round Trip Time (ms)"
$Label3.AutoSize = $true
$Label3.width = 25
$Label3.height = 10
$Label3.location = New-Object System.Drawing.Point(19, 95)
$Label3.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "Get BW"
$Button1.width = 81
$Button1.height = 30
$Button1.location = New-Object System.Drawing.Point(19, 128)
$Button1.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Button2 = New-Object system.Windows.Forms.Button
$Button2.text = "Get Win"
$Button2.width = 81
$Button2.height = 30
$Button2.location = New-Object System.Drawing.Point(115, 128)
$Button2.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "Get RTT"
$Button3.width = 81
$Button3.height = 30
$Button3.location = New-Object System.Drawing.Point(211, 128)
$Button3.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "Reset"
$Button4.width = 81
$Button4.height = 30
$Button4.location = New-Object System.Drawing.Point(308, 128)
$Button4.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$Form.controls.AddRange(@($TextBox1, $TextBox2, $TextBox3, $Label1, $Label2, $Label3, $Button1, $Button2, $Button3, $Button4))

$Button1.Add_Click( { onBwClick })
$Button2.Add_Click( { onWinClick })
$Button3.Add_Click( { onRttClick })
$Button4.Add_Click( { onResetClick })

function onResetClick
{
    $TextBox1.Text = 0
    $TextBox2.Text = 0
    $TextBox3.Text = 100
}
function onRttClick
{ 
    $bw = [double]::Parse($TextBox1.Text)
    $win = [double]::Parse($TextBox2.Text)
    $rtt = $win / ($bw * 1024 * 1024) * 1000
    $TextBox3.Text = $rtt
}
function onWinClick
{ 
    $bw = [double]::Parse($TextBox1.Text)
    $rtt = [double]::Parse($TextBox3.Text)
    $win = $bw * $rtt / 1000 * 1024 * 1024
    $TextBox2.Text = $win
}
function onBwClick
{
    $rtt = [double]::Parse($TextBox3.Text)    
    $win = [double]::Parse($TextBox2.Text)
    $bw = $win / ($rtt / 1000) / 1024 / 1024
    $TextBox1.Text = $bw
}

#Write your logic code here

[void]$Form.ShowDialog()
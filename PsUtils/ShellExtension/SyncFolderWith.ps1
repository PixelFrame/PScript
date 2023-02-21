[CmdletBinding()]
param (
    [Parameter()] [string] $SrcDir = "E:\Temp"
)

if ($SrcDir -like '?:"') {                  # For disk root (e.g. "E:") will be passed as E:" by shell param "%V"
    $SrcDir = $SrcDir.Replace('"', '\')
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$InputForm = New-Object System.Windows.Forms.Form
$InputForm.ClientSize = New-Object System.Drawing.Point(390, 230)
$InputForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$InputForm.MaximizeBox = $false
$InputForm.text = 'Sync folder with ...' 
$InputForm.TopMost = $true

$BtnOK = New-Object System.Windows.Forms.Button
$BtnOK.Text = "OK"
$BtnOK.Width = 60
$BtnOK.Height = 25
$BtnOK.Location = New-Object System.Drawing.Point(10, 190)
$BtnOK.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$BtnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$BtnOK.TabIndex = 2

$BtnCancel = New-Object System.Windows.Forms.Button
$BtnCancel.Text = "Cancel"
$BtnCancel.Width = 60
$BtnCancel.Height = 25
$BtnCancel.Location = New-Object System.Drawing.Point(75, 190)
$BtnCancel.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$BtnCancel.TabIndex = 3

$tbSrcDir = New-Object System.Windows.Forms.TextBox
$tbSrcDir.Multiline = $false
$tbSrcDir.Width = 300
$tbSrcDir.Height = 30
$tbSrcDir.Location = New-Object System.Drawing.Point(10, 5)
$tbSrcDir.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$tbSrcDir.TabIndex = 0
$tbSrcDir.ReadOnly = $true
$tbSrcDir.Text = $SrcDir

$tbInput = New-Object System.Windows.Forms.TextBox
$tbInput.Multiline = $false
$tbInput.Width = 300
$tbInput.Height = 30
$tbInput.Location = New-Object System.Drawing.Point(10, 65)
$tbInput.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$tbInput.TabIndex = 0
$tbInput.Text = $ENV:USERPROFILE

$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "Browse"
$BtnBrowse.Width = 65
$BtnBrowse.Height = 25
$BtnBrowse.Location = New-Object System.Drawing.Point(315, 65)
$BtnBrowse.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$BtnBrowse.TabIndex = 1
$BtnBrowse.Add_Click( { browseFolder })

$rbFrom = New-Object System.Windows.Forms.RadioButton
$rbFrom.Text = "From"
$rbFrom.Checked = $false
$rbFrom.AutoSize = $true
$rbFrom.Location = New-Object System.Drawing.Point(10, 35)
$rbFrom.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$rbTo = New-Object System.Windows.Forms.RadioButton
$rbTo.Text = "To"
$rbTo.Checked = $true
$rbTo.AutoSize = $true
$rbTo.Location = New-Object System.Drawing.Point(70, 35)
$rbTo.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$tbFilter = New-Object System.Windows.Forms.TextBox
$tbFilter.Multiline = $false
$tbFilter.Width = 300
$tbFilter.Height = 30
$tbFilter.Location = New-Object System.Drawing.Point(10, 95)
$tbFilter.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$tbFilter.Text = '*.*'

$cbxRecusive = New-Object System.Windows.Forms.CheckBox
$cbxRecusive.Text = "Recursive"
$cbxRecusive.Checked = $true
$cbxRecusive.AutoSize = $true
$cbxRecusive.Location = New-Object System.Drawing.Point(10, 125)
$cbxRecusive.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$cbxPurge = New-Object System.Windows.Forms.CheckBox
$cbxPurge.Text = "Purge"
$cbxPurge.Checked = $true
$cbxPurge.AutoSize = $true
$cbxPurge.Location = New-Object System.Drawing.Point(110, 125)
$cbxPurge.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$cbxSec = New-Object System.Windows.Forms.CheckBox
$cbxSec.Text = "Copy SEC Info"
$cbxSec.Checked = $true
$cbxSec.AutoSize = $true
$cbxSec.Location = New-Object System.Drawing.Point(220, 125)
$cbxSec.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$cbxElevate = New-Object System.Windows.Forms.CheckBox
$cbxElevate.Text = "Elevation"
$cbxElevate.Checked = $false
$cbxElevate.AutoSize = $true
$cbxElevate.Location = New-Object System.Drawing.Point(10, 155)
$cbxElevate.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$cbxLog = New-Object System.Windows.Forms.CheckBox
$cbxLog.Text = "Logging"
$cbxLog.Checked = $true
$cbxLog.AutoSize = $true
$cbxLog.Location = New-Object System.Drawing.Point(110, 155)
$cbxLog.Font = New-Object System.Drawing.Font('Segoe UI', 11)

$cbxMon = New-Object System.Windows.Forms.CheckBox
$cbxMon.Text = "Montoring"
$cbxMon.Checked = $false
$cbxMon.AutoSize = $true
$cbxMon.Location = New-Object System.Drawing.Point(220, 155)
$cbxMon.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$cbxMon.Add_CheckedChanged( { $numUpDown.Enabled = $cbxMon.Checked })

$numUpDown = New-Object System.Windows.Forms.NumericUpDown
$numUpDown.Width = 65
$numUpDown.Height = 30
$numUpDown.Location = New-Object System.Drawing.Point(316, 155)
$numUpDown.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$numUpDown.Minimum = 1
$numUpDown.Maximum = 1440 # 60min x 24hr
$numUpDown.Value = 10
$numUpDown.Enabled = $false

function browseFolder
{
    param ( )
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $result = $fbd.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $tbInput.Text = $fbd.SelectedPath
    }
}

$InputForm.AcceptButton = $BtnOK
$InputForm.CancelButton = $BtnCancel
$InputForm.Controls.AddRange(@($BtnOK, $BtnCancel, $tbInput, $tbSrcDir, $BtnBrowse, $rbFrom, $rbTo, $tbFilter, $cbxRecusive, $cbxSec, $cbxPurge, $cbxElevate, $cbxLog, $cbxMon, $numUpDown))
$dlgResult = $InputForm.ShowDialog()

if ($dlgResult -eq [System.Windows.Forms.DialogResult]::OK)
{
    if ($rbFrom.Checked) { $param = "`"$($tbInput.Text)`" `"$SrcDir`" $($tbFilter.Text)" }
    else { $param = "`"$SrcDir`" `"$($tbInput.Text)`" $($tbFilter.Text)" }
    if ($cbxRecusive.Checked) { $param += " /E" }
    if ($cbxPurge.Checked) { $param += " /PURGE" }
    if ($cbxSec.Checked) { $param += " /SEC" }
    if ($cbxLog.Checked) { 
        $userprofile = [Environment]::GetFolderPath("UserProfile")
        $now = Get-Date -Format "yyyyMMdd_HHmmss"
        $param += " /UNILOG:`"$userprofile\FolderSync_$now.log`" /TEE" 
    }
    $params += " /ETA"
    if ($cbxMon.Checked) { $param += " /MON:$($numUpDown.Value)" }
    $confirm = [System.Windows.Forms.MessageBox]::Show("Do you confirm to run command: `r`nrobocopy.exe $param", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes)
    {
        if ($cbxElevate.Checked) 
        {
            Start-Process -FilePath "robocopy.exe" -ArgumentList @($param) -Verb RunAs
        }
        else
        {
            Start-Process -FilePath "robocopy.exe" -ArgumentList @($param)
        }
    }
}

[CmdletBinding()]
param (
    [Parameter()] [string] $SrcDir = "E:\Temp"
)

if ($SrcDir -like '?:"') {                  # For disk root (e.g. "E:") will be passed as E:" by shell param "%V"
    $SrcDir = $SrcDir.Replace('"', '\')
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object System.Windows.Forms.Form
$Form.ClientSize = New-Object System.Drawing.Point(480, 300)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$Form.MaximizeBox = $false
$Form.Text = 'Folder Sync' 
$Form.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$Form.TopMost = $true

$Comps = @()

$tbSource = New-Object System.Windows.Forms.TextBox
$tbSource.Multiline = $false
$tbSource.Width = 390
$tbSource.Height = 30
$tbSource.Location = New-Object System.Drawing.Point(5, 5)
$tbSource.TabIndex = 0
$tbSource.ReadOnly = $true
$tbSource.Text = $SrcDir
$Comps += $tbSource

$rbFrom = New-Object System.Windows.Forms.RadioButton
$rbFrom.Text = "↑"
$rbFrom.Checked = $false
$rbFrom.AutoSize = $true
$rbFrom.Location = New-Object System.Drawing.Point(60, 40)
$rbFrom.TabIndex = 1
$Comps += $rbFrom

$rbTo = New-Object System.Windows.Forms.RadioButton
$rbTo.Text = "↓"
$rbTo.Checked = $true
$rbTo.AutoSize = $true
$rbTo.Location = New-Object System.Drawing.Point(210, 40)
$rbTo.TabIndex = 2
$Comps += $rbTo

$tbDest = New-Object System.Windows.Forms.TextBox
$tbDest.Multiline = $false
$tbDest.Width = 390
$tbDest.Height = 30
$tbDest.Location = New-Object System.Drawing.Point(5, 75)
$tbDest.TabIndex = 3
$tbDest.Text = $ENV:USERPROFILE
$Comps += $tbDest

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Width = 70
$btnBrowse.Height = 30
$btnBrowse.Location = New-Object System.Drawing.Point(400, 75)
$btnBrowse.TabIndex = 4
$btnBrowse.Add_Click( { browseFolder })
$Comps += $btnBrowse

$tbFilter = New-Object System.Windows.Forms.TextBox
$tbFilter.Multiline = $false
$tbFilter.Width = 465
$tbFilter.Height = 30
$tbFilter.Location = New-Object System.Drawing.Point(5, 110)
$tbFilter.TabIndex = 5
$tbFilter.Text = "*"
$Comps += $tbFilter

$cbxRecusive = New-Object System.Windows.Forms.CheckBox
$cbxRecusive.Text = "Recursive"
$cbxRecusive.Checked = $true
$cbxRecusive.AutoSize = $true
$cbxRecusive.Location = New-Object System.Drawing.Point(5, 145)
$cbxRecusive.TabIndex = 6
$Comps += $cbxRecusive

$cbxPurge = New-Object System.Windows.Forms.CheckBox
$cbxPurge.Text = "Purge"
$cbxPurge.Checked = $true
$cbxPurge.AutoSize = $true
$cbxPurge.Location = New-Object System.Drawing.Point(130, 145)
$cbxPurge.TabIndex = 7
$Comps += $cbxPurge

$cbxCopyAcl = New-Object System.Windows.Forms.CheckBox
$cbxCopyAcl.Text = "Copy ACL"
$cbxCopyAcl.Checked = $false
$cbxCopyAcl.AutoSize = $true
$cbxCopyAcl.Location = New-Object System.Drawing.Point(255, 145)
$cbxCopyAcl.TabIndex = 8
$Comps += $cbxCopyAcl

$cbxExHidden = New-Object System.Windows.Forms.CheckBox
$cbxExHidden.Text = "Skip Hidden"
$cbxExHidden.Checked = $true
$cbxExHidden.AutoSize = $true
$cbxExHidden.Location = New-Object System.Drawing.Point(5, 180)
$cbxExHidden.TabIndex = 9
$Comps += $cbxExHidden

$cbxPreSym = New-Object System.Windows.Forms.CheckBox
$cbxPreSym.Text = "Keep SymLink"
$cbxPreSym.Checked = $false
$cbxPreSym.AutoSize = $true
$cbxPreSym.Location = New-Object System.Drawing.Point(130, 180)
$cbxPreSym.TabIndex = 10
$Comps += $cbxPreSym

$cbxPreJunc = New-Object System.Windows.Forms.CheckBox
$cbxPreJunc.Text = "Keep Junction"
$cbxPreJunc.Checked = $false
$cbxPreJunc.AutoSize = $true
$cbxPreJunc.Location = New-Object System.Drawing.Point(255, 180)
$cbxPreJunc.TabIndex = 11
$Comps += $cbxPreJunc

$cbxElevate = New-Object System.Windows.Forms.CheckBox
$cbxElevate.Text = "Run As Admin"
$cbxElevate.Checked = $false
$cbxElevate.AutoSize = $true
$cbxElevate.Location = New-Object System.Drawing.Point(5, 215)
$cbxElevate.TabIndex = 12
$Comps += $cbxElevate

$cbxLogging = New-Object System.Windows.Forms.CheckBox
$cbxLogging.Text = "Logging"
$cbxLogging.Checked = $false
$cbxLogging.AutoSize = $true
$cbxLogging.Location = New-Object System.Drawing.Point(130, 215)
$cbxLogging.TabIndex = 13
$Comps += $cbxLogging

$cbxMonitor = New-Object System.Windows.Forms.CheckBox
$cbxMonitor.Text = "Monitor"
$cbxMonitor.Checked = $false
$cbxMonitor.AutoSize = $true
$cbxMonitor.Location = New-Object System.Drawing.Point(255, 215)
$cbxMonitor.Add_CheckedChanged( { $nudMonitor.Enabled = $cbxMonitor.Checked })
$cbxMonitor.TabIndex = 14
$Comps += $cbxMonitor

$nudMonitor = New-Object System.Windows.Forms.NumericUpDown
$nudMonitor.Width = 60
$nudMonitor.Height = 30
$nudMonitor.Location = New-Object System.Drawing.Point(380, 215)
$nudMonitor.Minimum = 1
$nudMonitor.Maximum = 1440 # 60min x 24hr
$nudMonitor.Value = 10
$nudMonitor.Enabled = $false
$nudMonitor.TabIndex = 15
$Comps += $nudMonitor

$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "OK"
$btnOK.Width = 120
$btnOK.Height = 30
$btnOK.Location = New-Object System.Drawing.Point(5, 250)
$btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$btnOK.TabIndex = 16
$Comps += $btnOK

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Width = 120
$btnCancel.Height = 30
$btnCancel.Location = New-Object System.Drawing.Point(130, 250)
$btnCancel.TabIndex = 17
$Comps += $btnCancel

function browseFolder
{
    param ( )
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $result = $fbd.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $tbDest.Text = $fbd.SelectedPath
    }
}

$Form.AcceptButton = $BtnOK
$Form.CancelButton = $BtnCancel
$Form.Controls.AddRange($Comps)
$dlgResult = $Form.ShowDialog()

if ($dlgResult -eq [System.Windows.Forms.DialogResult]::OK)
{
    if ($rbFrom.Checked) { $param = "`"$($tbSource.Text)`" `"$SrcDir`" $($tbFilter.Text)" }
    else { $param = "`"$SrcDir`" `"$($tbSource.Text)`" $($tbFilter.Text)" }
    if ($cbxRecusive.Checked) { $param += " /E" }
    if ($cbxPurge.Checked) { $param += " /PURGE" }
    if ($cbxCopyAcl.Checked) { $param += " /SEC" }
    if ($cbxLogging.Checked)
    { 
        $userprofile = [Environment]::GetFolderPath("UserProfile")
        $now = Get-Date -Format "yyyyMMdd_HHmmss"
        $param += " /UNILOG:`"$userprofile\FolderSync_$now.log`" /TEE" 
    }
    if ($cbxExHidden.Checked) { $param += " /XA:H" }
    if ($cbxPreSym.Checked) { $param += " /SL" }
    if ($cbxPreJunc.Checked) { $param += " /SJ" }
    $params += " /ETA"
    if ($cbxMonitor.Checked) { $param += " /MON:$($nudMonitor.Value)" }
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
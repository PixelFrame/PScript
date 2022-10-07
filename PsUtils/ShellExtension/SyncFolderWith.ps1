[CmdletBinding()]
param (
    [Parameter()] [string] $SrcDir = "E:\Temp"
)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$InputForm = New-Object System.Windows.Forms.Form
$InputForm.ClientSize = New-Object System.Drawing.Point(385, 125)
$InputForm.text = 'Sync folder with ...' 
$InputForm.TopMost = $false

$BtnOK = New-Object System.Windows.Forms.Button
$BtnOK.Text = "OK"
$BtnOK.Width = 60
$BtnOK.Height = 20
$BtnOK.Location = New-Object System.Drawing.Point(10, 100)
$BtnOK.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$BtnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$BtnOK.TabIndex = 2

$BtnCancel = New-Object System.Windows.Forms.Button
$BtnCancel.Text = "Cancel"
$BtnCancel.Width = 60
$BtnCancel.Height = 20
$BtnCancel.Location = New-Object System.Drawing.Point(75, 100)
$BtnCancel.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$BtnCancel.TabIndex = 3

$tbSrcDir = New-Object System.Windows.Forms.TextBox
$tbSrcDir.Multiline = $false
$tbSrcDir.Width = 300
$tbSrcDir.Height = 30
$tbSrcDir.Location = New-Object System.Drawing.Point(10, 5)
$tbSrcDir.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbSrcDir.TabIndex = 0
$tbSrcDir.ReadOnly = $true
$tbSrcDir.Text = $SrcDir

$tbInput = New-Object System.Windows.Forms.TextBox
$tbInput.Multiline = $false
$tbInput.Width = 300
$tbInput.Height = 30
$tbInput.Location = New-Object System.Drawing.Point(10, 65)
$tbInput.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbInput.TabIndex = 0
$tbInput.Text = $ENV:USERPROFILE

$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "Browse"
$BtnBrowse.Width = 60
$BtnBrowse.Height = 20
$BtnBrowse.Location = New-Object System.Drawing.Point(320, 65)
$BtnBrowse.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$BtnBrowse.TabIndex = 1
$BtnBrowse.Add_Click( { browseFolder })

$rbFrom = New-Object System.Windows.Forms.RadioButton
$rbFrom.Text = "From"
$rbFrom.Checked = $true
$rbFrom.AutoSize = $true
$rbFrom.Location =  New-Object System.Drawing.Point(10, 35)
$rbFrom.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$rbTo = New-Object System.Windows.Forms.RadioButton
$rbTo.Text = "To"
$rbTo.Checked = $false
$rbTo.AutoSize = $true
$rbTo.Location =  New-Object System.Drawing.Point(70, 35)
$rbTo.Font = New-Object System.Drawing.Font('Segoe UI', 10)

function browseFolder {
    param ( )
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $result = $fbd.ShowDialog()
    if($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $tbInput.Text = $fbd.SelectedPath
    }
}

$InputForm.AcceptButton = $BtnOK
$InputForm.CancelButton = $BtnCancel
$InputForm.Controls.AddRange(@($BtnOK, $BtnCancel, $tbInput, $tbSrcDir, $BtnBrowse, $rbFrom, $rbTo))
$dlgResult = $InputForm.ShowDialog()

if ($dlgResult -eq [System.Windows.Forms.DialogResult]::OK)
{
    if ($rbFrom.Checked) { $param = "`"$($tbInput.Text)`" `"$SrcDir`" /MIR" }
    else { $param = "`"$SrcDir`" `"$($tbInput.Text)`" /MIR" }
    $confirm = [System.Windows.Forms.MessageBox]::Show("Do you confirm to run command: `r`nrobocopy.exe $param", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes)
    {
        Start-Process -FilePath "robocopy.exe" -ArgumentList @($param)
    }
}

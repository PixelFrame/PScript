[CmdletBinding()]
param (
    [Parameter()] [string] $Title = 'Input Form',
    [Parameter()] [string] $Description = 'Input your data'
)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$InputForm = New-Object system.Windows.Forms.Form
$InputForm.ClientSize = New-Object System.Drawing.Point(400, 175)
$InputForm.text = $Title 
$InputForm.TopMost = $false

$BtnOK = New-Object system.Windows.Forms.Button
$BtnOK.text = "OK"
$BtnOK.width = 60
$BtnOK.height = 30
$BtnOK.location = New-Object System.Drawing.Point(130, 120)
$BtnOK.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$BtnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
$BtnOK.TabIndex = 1

$BtnCancel = New-Object system.Windows.Forms.Button
$BtnCancel.text = "Cancel"
$BtnCancel.width = 60
$BtnCancel.height = 30
$BtnCancel.location = New-Object System.Drawing.Point(210, 120)
$BtnCancel.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$BtnCancel.TabIndex = 2

$tbInput = New-Object system.Windows.Forms.TextBox
$tbInput.multiline = $false
$tbInput.width = 350
$tbInput.height = 30
$tbInput.location = New-Object System.Drawing.Point(25, 75)
$tbInput.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$tbInput.TabIndex = 0

$LbDescription = New-Object system.Windows.Forms.Label
$LbDescription.text = $Description 
$LbDescription.AutoSize = $true
$LbDescription.width = 350
$LbDescription.height = 15
$LbDescription.location = New-Object System.Drawing.Point(25, 30)
$LbDescription.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$InputForm.AcceptButton = $BtnOK
$InputForm.CancelButton = $BtnCancel
$InputForm.controls.AddRange(@($BtnOK, $BtnCancel, $tbInput, $LbDescription))
$Result = $InputForm.ShowDialog()

if ($Result -eq [System.Windows.Forms.DialogResult]::OK)
{
    return $tbInput.Text
}
return $null
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]
    $SourceFile,

    [Parameter()]
    [string]
    $PathFolder = 'C:\QuickLaunch'
)

[string] $ShortName = & $PSScriptRoot\PsGUI\DialogBoxInput.ps1 'Input Short Name' 'Input Short Name'

if ([string]::Empty -eq $ShortName)
{
    exit
}

while ($ShortName.IndexOfAny(@('/', '\', ':', '*', '?', '"', '<', '>', '|')) -ne -1)
{
    [System.Windows.Forms.MessageBox]::Show("Invalid File Name!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    $ShortName = & $PSScriptRoot\PsGUI\DialogBoxInput.ps1 'Input Short Name' 'Input Short Name'
    if ($null -eq $ShortName)
    {
        exit
    }
}

if (Test-Path "$PathFolder\$ShortName.lnk")
{
    [System.Windows.Forms.MessageBox]::Show("ShortCut Already Exist!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    exit
}

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PathFolder\$ShortName.lnk")
$Shortcut.TargetPath = $SourceFile
$Shortcut.Save()
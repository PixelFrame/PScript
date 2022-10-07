[CmdletBinding()]
param (
    [Parameter()] [string] $Extension,
    [Parameter()] [hashtable] $Options
)

try
{
    $ExtProperty = Get-ItemPropertyValue "HKCU:\SOFTWARE\Classes\.$Extension" -Name '(default)' -ErrorAction Stop
}
catch
{
    New-Item "HKCU:\SOFTWARE\Classes\.$Extension" -Force | Out-Null
    New-ItemProperty -Path "HKCU:\SOFTWARE\Classes\.$Extension" -Name '(default)'
    Set-ItemProperty "HKCU:\SOFTWARE\Classes\.$Extension" -Name '(default)' -Value "$Extension.Default"
    $ExtProperty = "$Extension.Default"
}

[string[]] $ClassPaths = "HKCU:\SOFTWARE\Classes\$ExtProperty"
$ClassPaths += "HKCU:\SOFTWARE\Classes\.$Extension"
$ClassPaths += "HKCU:\SOFTWARE\Classes\SystemFileAssociations\.$Extension"
foreach ($ClassPath in $ClassPaths)
{
    foreach ($optName in $Options.Keys) {
        
    }
    if (!(Test-Path $ClassPath\'shell')) { (New-Item $ClassPath\'shell' -Force).Name }
    if (!(Test-Path $ClassPath\'shell\Option')) { (New-Item $ClassPath\'shell\Option' -Force).Name }
    if (!(Test-Path $ClassPath\'shell\Option\command')) { (New-Item $ClassPath\'shell\Option\command' -Force).Name }
    Set-ItemProperty -Path $ClassPath\'shell\Option\command' -Name '(default)' -Value "OptionCommand" -Force
}
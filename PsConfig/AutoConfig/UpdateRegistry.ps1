[string[]] $RegPaths += 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe'
$RegPaths += 'HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe'
$RegPaths += 'HKCU:\Console\C:_Program Files_PowerShell_7_pwsh.exe'
foreach ($RegPath in $RegPaths)
{ 
    if (!(Test-Path $RegPath)) { New-Item $RegPath | Out-Null }

    Set-ItemProperty -Path $RegPath -Name FaceName -Type STRING -Value "Cascadia Code PL"
    Set-ItemProperty -Path $RegPath -Name FontSize -Type DWORD -Value 0x00120000
    Set-ItemProperty -Path $RegPath -Name ScreenColors -Type DWORD -Value 0x00000001
    Set-ItemProperty -Path $RegPath -Name CodePage -Type DWORD -Value 65001
}
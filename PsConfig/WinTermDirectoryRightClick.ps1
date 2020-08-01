#Requires -RunAsAdministrator

# Locate Windows Terminal Root Folder and User Executable

$WinTermRoot = (Get-ChildItem -Path 'HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages' `
    | Where-Object { $_.Name -like '*WindowsTerminal*' }).GetValue('PackageRootFolder')

if ($null -eq $WinTermRoot)
{
    Write-Host 'Cannot Locate Windows Terminal Package Root' -ForegroundColor Red
    Exit
}

$WinTermExe = $env:LOCALAPPDATA + '\Microsoft\WindowsApps\wt.exe'
if (Test-Path $WinTermExe)
{
    $WinTermOpenCmd = "`"$WinTermExe`" -d `"%V\.`""
}
else
{
    Write-Host 'Cannot Locate Windows Terminal User Executable' -ForegroundColor Red
    Exit
}

# Write Registry Properties to HKEY_CLASS_ROOT

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
$RegPath = 'HKCR:\Directory'
if (!(Test-Path $RegPath\'Background')) { (New-Item $RegPath\'Background' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell')) { (New-Item $RegPath\'Background\shell' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell\Windows Terminal')) { (New-Item $RegPath\'Background\shell\Windows Terminal' -Force).Name }

New-ItemProperty -Path $RegPath\'Background\shell\Windows Terminal' -Name 'ExtendedSubCommandsKey' `
    -Value 'Directory\ContextMenus\Windows Terminal' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'Background\shell\Windows Terminal' -Name 'Icon' `
    -Value $WinTermRoot\'WindowsTerminal.exe' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'Background\shell\Windows Terminal' -Name 'MUIVerb' `
    -Value 'Windows Terminal' `
    -PropertyType String -Force

if (!(Test-Path $RegPath\'ContextMenus')) { (New-Item $RegPath\'ContextMenus' -Force).Name }
if (!(Test-Path $RegPath\'ContextMenus\Windows Terminal')) { (New-Item $RegPath\'ContextMenus\Windows Terminal' -Force).Name }
if (!(Test-Path $RegPath\'ContextMenus\Windows Terminal\shell')) { (New-Item $RegPath\'ContextMenus\Windows Terminal\shell' -Force).Name }
if (!(Test-Path $RegPath\'ContextMenus\Windows Terminal\shell\openwt')) { (New-Item $RegPath\'ContextMenus\Windows Terminal\shell\openwt' -Force).Name }
if (!(Test-Path $RegPath\'ContextMenus\Windows Terminal\shell\runas')) { (New-Item $RegPath\'ContextMenus\Windows Terminal\shell\runas' -Force).Name }
if (!(Test-Path $RegPath\'ContextMenus\Windows Terminal\shell\openwt\command')) { (New-Item $RegPath\'ContextMenus\Windows Terminal\shell\openwt\command' -Force).Name }
if (!(Test-Path $RegPath\'ContextMenus\Windows Terminal\shell\runas\command')) { (New-Item $RegPath\'ContextMenus\Windows Terminal\shell\runas\command' -Force).Name }

New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\openwt' -Name 'Icon' `
    -Value $WinTermRoot\'WindowsTerminal.exe' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\openwt' -Name 'MUIVerb' `
    -Value 'Open here' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\openwt\command' -Name '(default)' `
    -Value $WinTermOpenCmd `
    -PropertyType String -Force

New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\runas' -Name 'Icon' `
    -Value $WinTermRoot\'WindowsTerminal.exe' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\runas' -Name 'MUIVerb' `
    -Value 'Open here as Administrator' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\runas' -Name 'HasLUAShield' `
    -Value '' `
    -PropertyType String -Force
New-ItemProperty -Path $RegPath\'ContextMenus\Windows Terminal\shell\runas\command' -Name '(default)' `
    -Value $WinTermOpenCmd `
    -PropertyType String -Force
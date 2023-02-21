if (!(Test-Path "$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts"))
{
    [System.IO.Directory]::CreateDirectory("$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts")
}
$StubFile = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts\SyncFolderWith.ps1"
$IconFile = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts\SyncFolderWith.ico"
Copy-Item -Path $PSScriptRoot\SyncFolderWith.ps1 -Destination $StubFile -Force
Copy-Item -Path $PSScriptRoot\..\..\bin\SyncFolderWith.ico -Destination $IconFile -Force

$RegPath = 'HKCU:\SOFTWARE\Classes\Directory'
if (!(Test-Path $RegPath\'Background')) { (New-Item $RegPath\'Background' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell')) { (New-Item $RegPath\'Background\shell' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell\Sync this folder with')) { (New-Item $RegPath\'Background\shell\Sync this folder with' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell\Sync this folder with\command')) { (New-Item $RegPath\'Background\shell\Sync this folder with\command' -Force).Name }
Set-ItemProperty -Path $RegPath\'Background\shell\Sync this folder with\command' -Name '(default)' -Value "pwsh.exe -NoProfile -File `"$StubFile`" -SrcDir `"%V`"" -Force
Set-ItemProperty -Path $RegPath\'Background\shell\Sync this folder with' -Name 'Icon' -Value "`"$IconFile`"" -Force

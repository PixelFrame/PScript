if (!(Test-Path "$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts"))
{
    [System.IO.Directory]::CreateDirectory("$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts")
}
$StubFile = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Scripts\SyncFolderWith.ps1"
Copy-Item -Path .\SyncFolderWith.ps1 -Destination $StubFile -Force

$RegPath = 'HKCU:\SOFTWARE\Classes\Directory'
if (!(Test-Path $RegPath\'Background')) { (New-Item $RegPath\'Background' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell')) { (New-Item $RegPath\'Background\shell' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell\Sync this folder with')) { (New-Item $RegPath\'Background\shell\Sync this folder with' -Force).Name }
if (!(Test-Path $RegPath\'Background\shell\Sync this folder with\command')) { (New-Item $RegPath\'Background\shell\Sync this folder with\command' -Force).Name }
Set-ItemProperty -Path $RegPath\'Background\shell\Sync this folder with\command' -Name '(default)' -Value "pwsh.exe -NoProfile -File `"$StubFile`" -SrcDir `"%V`"" -Force

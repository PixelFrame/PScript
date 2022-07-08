try 
{
    Get-Command choco.exe -ErrorAction Stop | Out-Null
}
catch
{
    Write-Host '[Info] Chocolatey is not installed'
    Write-Host '[Info] Installing Chocolatey'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

Write-Host '[Info] Installing Softwares via Chocolatey'

$ChocoInstalledApps = choco list --localonly

if ($null -eq ($ChocoInstalledApps | Where-Object { $_.Contains('git') })) { choco install git -y -r }
else { Write-Host '[Info] Git Installed. Skipping.' }
if ($null -eq ($ChocoInstalledApps | Where-Object { $_.Contains('colortool') })) { choco install ColorTool -y -r }
else { Write-Host '[Info] ColorTool Installed. Skipping.' }
if ($null -eq ($ChocoInstalledApps | Where-Object { $_.Contains('Sudo') })) { choco install Sudo -y -r }
else { Write-Host '[Info] Sudo Installed. Skipping.' }
if ($null -eq ($ChocoInstalledApps | Where-Object { $_.Contains('cascadiafonts') })) { choco install cascadiafonts -y -r }
else { Write-Host '[Info] Cascadia Fonts Installed. Skipping.' }

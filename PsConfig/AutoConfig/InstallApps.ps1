try 
{
    Get-Command choco.exe -ErrorAction Stop
}
catch
{
    Write-Host '[Info] Chocolatey is not installed'
    Write-Host '[Info] Installing Chocolatey'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

Write-Host '[Info] Installing Softwares via Chocolatey'
choco install git -y -r
choco install ColorTool -y -r
choco install Sudo -y -r
choco install cascadiafonts -y -r

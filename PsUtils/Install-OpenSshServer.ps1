#Requires -RunAsAdministrator

Invoke-WebRequest -Uri 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.6.0.0p1-Beta/OpenSSH-Win64.zip' -UseBasicParsing -OutFile $env:USERPROFILE\OpenSSH-Win64.zip
Expand-Archive -Path $env:USERPROFILE\OpenSSH-Win64.zip -DestinationPath $env:ProgramFiles\
& $env:ProgramFiles\OpenSSH-Win64\Install-Sshd.ps1
Import-Module $env:ProgramFiles\OpenSSH-Win64\OpenSSHUtils.psm1 -Scope Global
Start-Service sshd
Get-Service sshd
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
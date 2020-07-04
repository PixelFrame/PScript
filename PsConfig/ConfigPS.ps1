if ($PSEdition -eq 'Core')
{
    $PSType = 'PowerShell'
    Write-Host '[Info] Host is PowerShell'
}
else
{
    $PSType = 'WindowsPowerShell'
    Write-Host '[Info] Host is Windows PowerShell'
}

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
    .\AutoConfig\InstallPoshModules.ps1
    .\AutoConfig\WriteProfile.ps1 -PSType $PSType
    .\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
    .\AutoConfig\SetColor.ps1
    .\AutoConfig\InstallPoshModules.ps1
    .\AutoConfig\UpdateRegistry.ps1
    .\AutoConfig\UpdateShortcuts.ps1
    .\AutoConfig\WriteStub.ps1
}
else
{
    Write-Host "[Error] You're not running this script as Administrator." -ForegroundColor Red
    Pause
    Exit
}

Write-Host '[Info] Script Completed Successfully' -ForegroundColor Green
Write-Host '[Info] Restart Your PowerShell and Check the Result' -ForegroundColor Green

Pause
Exit
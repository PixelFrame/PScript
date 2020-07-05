[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('Full', 'Profile', 'TerminalStyle', 'ModuleInstall', 'AppInstall', 'StubOnly')]
    [string]
    $Mode = 'Full'
)

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
    switch ($Mode)
    {
        'Full'
        {
            Write-Host '[Info] Full Mode: All configuration will be installed/refreshed'
            .\AutoConfig\InstallPoshModules.ps1
            .\AutoConfig\WriteProfile.ps1 -PSType $PSType
            .\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
            .\AutoConfig\SetColor.ps1
            .\AutoConfig\InstallApps.ps1
            .\AutoConfig\UpdateRegistry.ps1
            .\AutoConfig\UpdateShortcuts.ps1
            .\AutoConfig\WriteStub.ps1
            break
        }
        'Profile'
        {
            Write-Host '[Info] Profile Mode: Will refresh PowerShell user profile and PoshTheme'
            .\AutoConfig\WriteProfile.ps1 -PSType $PSType
            .\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
            break
        }
        'TerminalStyle'
        {
            Write-Host '[Info] Terminal Style Mode: Will refresh color scheme and update refresh settings'
            .\AutoConfig\SetColor.ps1
            .\AutoConfig\UpdateRegistry.ps1
            .\AutoConfig\UpdateShortcuts.ps1
            break
        }
        'ModuleInstall'
        {
            Write-Host '[Info] Module Installation Mode: Will install/update posh modules and refresh PowerShell user profile and PoshTheme'
            .\AutoConfig\InstallPoshModules.ps1
            .\AutoConfig\WriteProfile.ps1 -PSType $PSType
            .\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
            break
        }
        'AppInstall'
        {
            Write-Host '[Info] App Installation Mode: Will install chocolatey, git, Sudo, ColorTool and Cascadia fonts'
            .\AutoConfig\InstallApps.ps1
            break
        }
        'StubOnly'
        {
            Write-Host '[Info] Stub Only Mode: Will copy this script to user PowerShell scripts folder'
            .\AutoConfig\WriteStub.ps1
            break
        }
        Default {}
    }
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
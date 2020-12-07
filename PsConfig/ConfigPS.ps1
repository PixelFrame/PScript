[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('Full', 'Profile', 'TerminalStyle', 'ModuleInstall', 'AppInstall', 'StubOnly')]
    [string]
    $Mode = 'Full'
)

@'
###################################################
###                                             ###
###       PowerShell Configuration Script       ###
###                                      v1.4c  ###
###                                             ###
###################################################
'@

if ($PSEdition -eq 'Core')
{
    $PSType = 'PowerShell'
    Write-Host '[Info] Host is PowerShell ' -NoNewline
    Write-Host $PSVersionTable.PSVersion.ToString()
}
else
{
    $PSType = 'WindowsPowerShell'
    Write-Host '[Info] Host is Windows PowerShell ' -NoNewline
    Write-Host $PSVersionTable.PSVersion.ToString()

    $CodePage = ((chcp.com).Split(' '))[3]
    if ($CodePage -eq 936)
    {
        Write-Host '[Warning] Code Page 936 is detect on Windows PowerShell!' -ForegroundColor Yellow
        Write-Host '          Font configuration on shortcuts will not work properly. Consider to use Sarasa Mono instead.' -ForegroundColor Yellow
    }
}

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
    switch ($Mode)
    {
        'Full'
        {
            Write-Host '[Info] Full Mode: All configuration will be installed/refreshed'
            & $PSScriptRoot\AutoConfig\InstallPoshModules.ps1
            & $PSScriptRoot\AutoConfig\WriteProfile.ps1 -PSType $PSType
            & $PSScriptRoot\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
            & $PSScriptRoot\AutoConfig\SetColor.ps1
            & $PSScriptRoot\AutoConfig\InstallApps.ps1
            & $PSScriptRoot\AutoConfig\UpdateRegistry.ps1
            & $PSScriptRoot\AutoConfig\UpdateShortcuts.ps1
            & $PSScriptRoot\AutoConfig\WriteStub.ps1 -PSType $PSType
            break
        }
        'Profile'
        {
            Write-Host '[Info] Profile Mode: Will refresh PowerShell user profile and PoshTheme'
            & $PSScriptRoot\AutoConfig\WriteProfile.ps1 -PSType $PSType
            & $PSScriptRoot\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
            break
        }
        'TerminalStyle'
        {
            Write-Host '[Info] Terminal Style Mode: Will refresh color scheme and update refresh settings'
            & $PSScriptRoot\AutoConfig\SetColor.ps1
            & $PSScriptRoot\AutoConfig\UpdateRegistry.ps1
            & $PSScriptRoot\AutoConfig\UpdateShortcuts.ps1
            break
        }
        'ModuleInstall'
        {
            Write-Host '[Info] Module Installation Mode: Will install/update posh modules and refresh PowerShell user profile and PoshTheme'
            & $PSScriptRoot\AutoConfig\InstallPoshModules.ps1
            & $PSScriptRoot\AutoConfig\WriteProfile.ps1 -PSType $PSType
            & $PSScriptRoot\AutoConfig\WritePoshTheme.ps1 -PSType $PSType
            break
        }
        'AppInstall'
        {
            Write-Host '[Info] App Installation Mode: Will install chocolatey, git, Sudo, ColorTool and Cascadia fonts'
            & $PSScriptRoot\AutoConfig\InstallApps.ps1
            break
        }
        'StubOnly'
        {
            Write-Host '[Info] Stub Only Mode: Will copy this script to user PowerShell scripts folder'
            & $PSScriptRoot\AutoConfig\WriteStub.ps1 -PSType $PSType
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
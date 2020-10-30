Write-Host '[Info] Installing/Upgrading oh-my-posh & posh-git'

if ($null -eq (Get-Module -Name 'oh-my-posh'))
{
    try
    {
        if ((Get-PackageProvider).Name -notcontains 'NuGet')
        {
            Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        }
        Install-Module -Name 'posh-git' -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Install-Module -Name 'oh-my-posh' -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }
    catch
    {
        Write-Host '[Error] Unable to Install Module' -ForegroundColor Red
        Write-Host 'Script Aborted' -ForegroundColor Red
        Pause
        Exit
    }
}
else
{
    Update-Module -Name 'posh-git'
    Update-Module -Name 'oh-my-posh'
}
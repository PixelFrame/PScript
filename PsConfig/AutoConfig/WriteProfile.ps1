[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PSType,

    [switch]
    $PoshV3
)

Write-Host '[Info] Writing to User PowerShell Profile'

$ProfilePath = $env:USERPROFILE + '\Documents\' + $PSType

if (!(Test-Path -Path $ProfilePath)) { New-Item -Path $ProfilePath -ItemType Directory | Out-Null }
if (!(Test-Path $ProfilePath\Scripts)) { New-Item -Path $ProfilePath\Scripts -ItemType Directory | Out-Null }

if ($PoshV3)
{
    $ProfileContent = @"
# Set Posh Theme
Import-Module oh-my-posh
Set-PoshPrompt -Theme '$env:USERPROFILE\.poshthemes\ParadoxCascadiaV3.json'
"@
}
else
{
    $ProfileContent = @'
# Set Posh Theme
Import-Module oh-my-posh
Set-Theme ParadoxCascadia
$ThemeSettings.Options.ConsoleTitle = $false
'@
}

if (!(Test-Path $ProfilePath\Scripts\Alias.ps1)) { New-Item -ItemType File -Path $ProfilePath\Scripts\Alias.ps1 | Out-Null }
$ProfileContent += @"

# Alias
. "$ProfilePath\Scripts\Alias.ps1"
"@

if (!(Test-Path $ProfilePath\Scripts\Functions.ps1)) { New-Item -ItemType File -Path $ProfilePath\Scripts\Functions.ps1 | Out-Null }
$ProfileContent += @"

# Functions
. "$ProfilePath\Scripts\Functions.ps1"
"@

$ProfileContent += @'

# Host Title
$Host.UI.RawUI.WindowTitle = $env:USERDOMAIN + '\'
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $Host.UI.RawUI.WindowTitle += 'Administrator: '
}
else
{
    $Host.UI.RawUI.WindowTitle += $env:USERNAME + ': '
}
'@

if ($PSType -eq 'WindowsPowerShell')
{
    $HostTitle = 'Windows PowerShell '
}
else
{
    $HostTitle = 'PowerShell '
}
$ProfileContent += "`n" + '$Host.UI.RawUI.WindowTitle +=' + "'$HostTitle' + " + ' $PSVersionTable.PSVersion.ToString() + " @ " + [environment]::OSVersion.VersionString'

$ProfileContent += @'

# Welcome
Write-Host @"
    ____ _       _______ __  __
   / __ \ |     / / ___// / / /
  / /_/ / | /| / /\__ \/ /_/ / 
 / ____/| |/ |/ /___/ / __  /  
/_/     |__/|__//____/_/ /_/   

"@ -ForegroundColor Blue
'@

Out-File -FilePath $ProfilePath\Microsoft.PowerShell_profile.ps1 -Encoding utf8 -InputObject $ProfileContent
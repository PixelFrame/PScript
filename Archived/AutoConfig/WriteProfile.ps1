[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PSType,

    [switch]
    $PoshV2
)

Write-Host '[Info] Writing to User PowerShell Profile'

$ProfilePath = $env:USERPROFILE + '\Documents\' + $PSType

if (!(Test-Path -Path $ProfilePath)) { New-Item -Path $ProfilePath -ItemType Directory | Out-Null }
if (!(Test-Path $ProfilePath\Scripts)) { New-Item -Path $ProfilePath\Scripts -ItemType Directory | Out-Null }

if ($PoshV2)
{
    $ProfileContent = @'
# Set Posh Theme
Import-Module oh-my-posh
Set-Theme ParadoxCascadia
$ThemeSettings.Options.ConsoleTitle = $false
'@
}
else
{
    $ProfileContent = @"
# Set Posh Theme
Import-Module oh-my-posh
Set-PoshPrompt -Theme '$env:USERPROFILE\.poshthemes\ParadoxCascadiaV3.json'
"@
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

if ($PSType -eq 'WindowsPowerShell')
{
    $HostTitle = 'Windows PowerShell '
}
else
{
    $HostTitle = 'PowerShell '
}

$ProfileContent += @"

# Host Title
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    `$Admin = '[Administrator] '
}
else
{
    `$Admin = ''
}
`$Host.UI.RawUI.WindowTitle = "`$Admin `$env:USERDOMAIN\`$(`$env:USERNAME): $HostTitle `$(`$PSVersionTable.PSVersion.ToString()) @ `$([environment]::OSVersion.VersionString)"
"@

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
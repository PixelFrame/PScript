[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PSType
)

Write-Host '[Info] Writing to User PowerShell Profile'

$ProfilePath = $env:USERPROFILE + '\Documents\' + $PSType

if (!(Test-Path -Path $ProfilePath))
{
    New-Item -Path $ProfilePath -ItemType Directory | Out-Null
}
$ProfilePath += '\Microsoft.PowerShell_profile.ps1'
$ProfileContent = @'
# Set Posh Theme
Import-Module oh-my-posh
Set-Theme ParadoxCascadia
$ThemeSettings.Options.ConsoleTitle = $false

# Alias
'@
$PathVsCode = $env:USERPROFILE + '\AppData\Local\Programs\Microsoft VS Code\Code.exe'
if (Test-Path -Path $PathVsCode)
{
    $ProfileContent += "New-Alias -Name vscode -Value '$PathVsCode' -Description 'Visual Studio Code'"
}

$ProfileContent += '# Environment Path'
$ProfileContent += '$ScriptsPath = "; " + ' + "$ProfilePath\Scripts"
$ProfileContent += '$Env:Path += $ScriptsPath'

$ProfileContent += @'
# Host Title
$Host.UI.RawUI.WindowTitle = $env:USERDOMAIN + '\'
if (Test-Administrator)
{
    $Host.UI.RawUI.WindowTitle += 'Administrator: '
}
else
{
    $Host.UI.RawUI.WindowTitle += $env:USERNAME + ': '
}

# Functions
function ConfigPSStyle
{
    Set-Location $env:USERPROFILE\Documents\WindowsPowerShell\Scripts
    & $env:USERPROFILE\Documents\WindowsPowerShell\Scripts\ConfigPS.ps1 TerminalStyle
    exit
}

# Welcome
Write-Host @"
    ____ _       _______ __  __
   / __ \ |     / / ___// / / /
  / /_/ / | /| / /\__ \/ /_/ / 
 / ____/| |/ |/ /___/ / __  /  
/_/     |__/|__//____/_/ /_/   
"@ -ForegroundColor Blue

'@

if ($PSType -eq 'WindowsPowerShell')
{
    $HostTitle = 'Windows PowerShell'
}
else
{
    $HostTitle = 'PowerShell'
}
$ProfileContent += '$Host.UI.RawUI.WindowTitle += ' + "'$HostTitle' + " + ' $PSVersionTable.PSVersion.ToString() + " @ " + [environment]::OSVersion.VersionString'

Out-File -FilePath $ProfilePath -Encoding utf8 -InputObject $ProfileContent
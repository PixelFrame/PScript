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
    New-Item -Path $ProfilePath -ItemType Directory
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

# Welcome
Write-Host @"
 _       _______   ______  _____
| |     / /  _/ | / / __ \/ ___/
| | /| / // //  |/ / /_/ /\__ \ 
| |/ |/ // // /|  / ____/___/ / 
|__/|__/___/_/ |_/_/    /____/  
                                
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
##### ! Please remove the if-clauses in production to speed up opening ! #####

# Import oh-my-posh
try
{
    Import-Module oh-my-posh
    Set-Theme ParadoxE
    $ThemeSettings.Options.ConsoleTitle = $false
}
catch
{
    Write-Host "[WARNING] Missing Module oh-my-posh"
}

$Host.UI.RawUI.WindowTitle = $env:USERDOMAIN + '\'
if (Test-Administrator)
{
    $Host.UI.RawUI.WindowTitle += 'Administrator: '
}
else
{
    $Host.UI.RawUI.WindowTitle += $env:USERNAME + ': '
}

if ($PSEdition -eq "Core")
{
    $Host.UI.RawUI.WindowTitle += "PowerShell Core " + $PSVersionTable.PSVersion.ToString() + " @ " + [environment]::OSVersion.VersionString
}
else
{
    $Host.UI.RawUI.WindowTitle += "Windows PowerShell " + $PSVersionTable.PSVersion.ToString() + " @ " + [environment]::OSVersion.VersionString
}

# Alias
$PathVsCode = $Env:USERPROFILE + "/APPDATA/Local/Programs/Microsoft VS Code/Code.exe"
$PathVsCodeProg = $Env:ProgramFiles + "/Microsoft VS Code/Code.exe"
if (Test-Path -Path $PathVsCode)
{
    New-Alias -Name vscode -Value $PathVsCode -Description "Visual Studio Code"
}
elseif (Test-Path -Path $PathVsCodeProg)
{
    Write-Host "[INFO] Visual Studio Code (User) Not Exist"    
    Write-Host "[INFO] Falling Back..."
    New-Alias -Name vscode -Value $PathVsCodeProg -Description "Visual Studio Code"
}
else
{
    Write-Host "[WARNING] Visual Studio Code Not Exist"
}

# Functions
function ConfigPSStyle
{
    Set-Location $env:USERPROFILE\Documents\WindowsPowerShell\Scripts
    & $env:USERPROFILE\Documents\WindowsPowerShell\Scripts\ConfigPS.ps1 TerminalStyle
    exit
}

# Welcome
Write-Host "KERNEL IN THE SHELL - Pixel Frame Dev." -ForegroundColor DarkCyan
Write-Host @"
    ____ _       _______ __  __
   / __ \ |     / / ___// / / /
  / /_/ / | /| / /\__ \/ /_/ / 
 / ____/| |/ |/ /___/ / __  /  
/_/     |__/|__//____/_/ /_/   
"@ -ForegroundColor Cyan
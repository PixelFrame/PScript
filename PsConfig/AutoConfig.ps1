##########################################################################
##             PowerShell Auto Configuration Script v1.1b               ##
##                                                          Pixel Frame ##
##                                                                      ##
##  1. [Plug-in] oh-my-posh & posh-git                                  ##
##    1.1 ParadoxE Theme                                                ##
##  2. [Config] User Profile                                            ##
##  3. [Config] Console Color                                           ##
##  4. [Software] Chocolatey                                            ##
##    4.0 Git                                                           ##
##    4.1 Color Tool                                                    ##
##    4.2 Sudo                                                          ##
##    4.3 Cascadia Fonts                                                ##
##  5. [Config] Terminal Settings                                       ##
##    5.1 Registry                                                      ##
##    5.2 Refresh Windows PowerShell Shortcuts                          ##
##  6. [Config] Stub                                                    ##
##                                                                      ##
##########################################################################

##########################################################################
# Functions

function Invoke-Download
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SourceUri,
        
        [System.UInt32]
        $Retry = 3,
        
        [bool]
        $UseProxy = $true
    )
    $WebClient = New-Object System.Net.WebClient
    if ($UseProxy)
    {
        $Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $WebClient.Proxy = $Proxy
    }
    $FileName = $SourceUri.Substring($SourceUri.LastIndexOf('/') + 1)
    $DestPath = $PSScriptRoot + '\' + $FileName

    $AttemptCount = 0
    Do
    {
        $AttemptCount++
        $WebClient.DownloadFile($SourceUri, $DestPath)
    } while (((Test-Path $DestPath) -eq $false) -and ($AttemptCount -le $Retry))
}


# Test-Administrator function from oh-my-posh
function Test-Administrator
{
    if ($PSVersionTable.Platform -eq 'Unix')
    {
        return (whoami) -eq 'root'
    }
    elseif ($PSVersionTable.Platform -eq 'Windows')
    {
        return $false #TO-DO: find out how to distinguish this one
    }
    else
    {
        return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    }
}
##########################################################################
# Start of Script

Write-Host '############################################' -ForegroundColor Blue
Write-Host '##                                        ##' -ForegroundColor Blue
Write-Host '##      PowerShell AutoConfig Script      ##' -ForegroundColor Blue
Write-Host '##                                        ##' -ForegroundColor Blue
Write-Host '############################################' -ForegroundColor Blue
Write-Host ''

Set-Location -Path $env:USERPROFILE

if ($PSVersionTable.Platform -eq 'Unix')
{
    Write-Host 'This script can only be run on Windows OS' -ForegroundColor Red
    Pause
    Exit
}

Write-Host '[Info] Testing Administrator'
if (Test-Administrator)
{
    $IsAdmin = $true
    Write-Host '[Info] Running as Administrator'
}
else
{
    $IsAdmin = $false
    Write-Host "[Warning] You're not running this script as Administrator." -ForegroundColor Yellow
    while ($Continue = Read-Host -Prompt '[Prompt] Do you want to continue? Y/N')
    {
        if ($Continue.Equals('y') -or $Continue.Equals('Y'))
        {
            Write-Host 'Continue to execute' -ForegroundColor Yellow
            break
        }
        elseif ($Continue.Equals('n') -or $Continue.Equals('N'))
        {
            Write-Host 'Script Aborted' -ForegroundColor Red
            Pause
            Exit
        }
    }
}

if ($PSEdition -eq "Core")
{
    $ProfilePath = $env:USERPROFILE + '\Documents\PowerShell\'
    $HostTitle = "PowerShell "
    $IsCore = $true

    Write-Host '[Info] Host is PowerShell'
}
else
{
    $ProfilePath = $env:USERPROFILE + '\Documents\WindowsPowerShell\'
    $HostTitle = "Windows PowerShell "
    $IsCore = $false

    Write-Host '[Info] Host is Windows PowerShell'
}


Write-Host '[Info] Installing/Upgrading oh-my-posh & posh-git'

if ($null -eq (Get-Module -Name 'oh-my-posh'))
{
    try
    {
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
    Update-Module -Name 'posh-git' -Scope CurrentUser -Force
    Update-Module -Name 'oh-my-posh' -Scope CurrentUser -Force
}

Write-Host '[Info] Writing to User PowerShell Profile'

if (!(Test-Path -Path $ProfilePath))
{
    New-Item -Path $ProfilePath -ItemType Directory
}
$ProfilePath += 'Microsoft.PowerShell_profile.ps1'
$ProfileContent = @'
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

$ProfileContent += '$Host.UI.RawUI.WindowTitle += ' + "'$HostTitle' + " + ' $PSVersionTable.PSVersion.ToString() + " @ " + [environment]::OSVersion.VersionString'
Out-File -FilePath $ProfilePath -Encoding utf8 -InputObject $ProfileContent



Write-Host '[Info] Adding PoshTheme ParadoxCascadia'

$PoshThemeContent = 
@'
#requires -Version 2 -Modules posh-git
function Write-Theme
{
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )

    $lastColor = $sl.Colors.PromptBackgroundColor
    $prompt = Write-Prompt -Object $sl.PromptSymbols.StartSymbol -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor

    #check the last command state and indicate if failed
    If ($lastCommandFailed)
    {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $sl.Colors.CommandFailedIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    #check for elevated prompt
    If (Test-Administrator)
    {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.ElevatedSymbol) " -ForegroundColor $sl.Colors.AdminIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    $user = [System.Environment]::UserName
    $computer = [System.Environment]::MachineName
    $path = Get-FullPath -dir $pwd
    if (Test-NotDefaultUser($user))
    {
        $prompt += Write-Prompt -Object "$user@$computer " -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    if (Test-VirtualEnv)
    {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.VirtualEnvSymbol) $(Get-VirtualEnvName) " -ForegroundColor $sl.Colors.VirtualEnvForegroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.VirtualEnvBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }
    else
    {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }

    # Writes the drive portion
    $prompt += Write-Prompt -Object "$path " -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor

    $status = Get-VCSStatus
    if ($status)
    {
        $themeInfo = Get-VcsInfo -status ($status)
        $lastColor = $sl.Colors.GitBackgroundColor
        $prompt += Write-Prompt -Object $($sl.PromptSymbols.SegmentForwardSymbol) -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $lastColor
        $prompt += Write-Prompt -Object " $($themeInfo.VcInfo) " -BackgroundColor $lastColor -ForegroundColor $sl.Colors.GitForegroundColor
    }

    # Writes the postfix to the prompt
    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor

    $timeStamp = Get-Date -UFormat %R
    $timestamp = "[$timeStamp]"

    $prompt += Set-CursorForRightBlockWrite -textLength ($timestamp.Length + 1)
    $prompt += Write-Prompt $timeStamp -ForegroundColor $sl.Colors.PromptForegroundColor

    $prompt += Set-Newline

    if ($with)
    {
        $prompt += Write-Prompt -Object "$($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
    }
    $prompt += Write-Prompt -Object ($sl.PromptSymbols.PromptIndicator) -ForegroundColor $sl.Colors.PromptBackgroundColor
    $prompt += ' '
    $prompt
}

$sl = $global:ThemeSettings #local settings
$sl.PromptSymbols.StartSymbol = ' PS '
$sl.PromptSymbols.PromptIndicator = [char]::ConvertFromUtf32(0x25B6)
$sl.PromptSymbols.FailedCommandSymbol = [char]::ConvertFromUtf32(0x00D7)
$sl.PromptSymbols.SegmentForwardSymbol = [char]::ConvertFromUtf32(0xE0B0)
$sl.PromptSymbols.ElevatedSymbol = '#'
$sl.Colors.SessionInfoBackgroundColor = [ConsoleColor]::Blue
$sl.Colors.PromptForegroundColor = [ConsoleColor]::White
$sl.Colors.PromptBackgroundColor = [ConsoleColor]::DarkCyan
$sl.Colors.PromptSymbolColor = [ConsoleColor]::White
$sl.Colors.PromptHighlightColor = [ConsoleColor]::DarkCyan
$sl.Colors.GitForegroundColor = [ConsoleColor]::Black
$sl.Colors.GitBackgroundColor = [ConsoleColor]::Cyan
$sl.Colors.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.Colors.WithBackgroundColor = [ConsoleColor]::Magenta
$sl.Colors.VirtualEnvBackgroundColor = [System.ConsoleColor]::Red
$sl.Colors.VirtualEnvForegroundColor = [System.ConsoleColor]::White
'@
$PoshThemePath = $ProfilePath + '\PoshThemes\'
if (!(Test-Path $PoshThemePath))
{
    New-Item -Path $PoshThemePath -ItemType Directory
}
$PoshThemePath += 'ParadoxCascadia.psm1'
Out-File -FilePath $PoshThemePath -Encoding utf8 -InputObject $PoshThemeContent

Write-Host '[Info] Downloading ColorTool'
Invoke-Download -SourceUri "https://github.com/microsoft/terminal/releases/download/1904.29002/ColorTool.zip" -Retry 3
Expand-Archive -Path .\ColorTool.zip -DestinationPath .\ColorTool

Write-Host '[Info] Writing Theme File'
$OneHalfLightE = @'
[table]
DARK_BLACK = 55, 57, 66
DARK_BLUE = 0, 132, 188
DARK_GREEN = 79, 161, 79
DARK_CYAN = 9, 150, 179
DARK_RED = 228, 86, 73
DARK_MAGENTA = 166, 37, 164
DARK_YELLOW = 192, 132, 0
DARK_WHITE = 250, 250, 250
BRIGHT_BLACK = 97, 97, 97
BRIGHT_BLUE = 97, 175, 239
BRIGHT_GREEN = 152, 195, 121
BRIGHT_CYAN = 86, 181, 193
BRIGHT_RED = 223, 108, 117
BRIGHT_MAGENTA = 197, 119, 221
BRIGHT_YELLOW = 228, 192, 122
BRIGHT_WHITE = 255, 255, 255

[screen]
FOREGROUND = BRIGHT_BLUE
BACKGROUND = DARK_BLACK

[popup]
FOREGROUND = BRIGHT_WHITE
BACKGROUND = BRIGHT_RED
'@
$CTThemePath = $PSScriptRoot + '\ColorTool\OneHalfLightE.ini';

# Attention: ColorTool.exe only recognize UTF-8 No BOM
# For PowerShell 7, Out-File encoding utf8NoBOM is available
# Out-File -FilePath $CTThemePath -Encoding utf8NoBOM -InputObject $OneHalfLightE 
# For Windows PowerShell 5, using .NET IO is the only way
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($CTThemePath, $OneHalfLightE, $Utf8NoBomEncoding)

Write-Host '[Info] Setting Color Theme'
.\ColorTool\ColorTool.exe -b $CTThemePath

Write-Host '[Info] Removing ColorTool'
Remove-Item -Path .\ColorTool.zip
Remove-Item -Path .\ColorTool -Force -Recurse

try 
{
    Get-Command choco.exe -ErrorAction Stop
}
catch
{
    Write-Host '[Info] Chocolatey is not installed'
    Write-Host '[Info] Installing Chocolatey'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

if ($IsAdmin)
{
    Write-Host '[Info] Installing Softwares via Chocolatey'
    choco install git -y
    choco install ColorTool -y
    choco install Sudo -y
    choco install cascadiafonts -y
}
else
{
    Write-Host '[Warning] No Administrator Privilege, skipping choco install' -ForegroundColor Yellow
}

# Write Registry to change font and color
[string[]] $RegPaths += 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe'
$RegPaths += 'HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe'
$RegPaths += 'HKCU:\Console\C:_Program Files_PowerShell_7_pwsh.exe'
foreach ($RegPath in $RegPaths)
{ 
    if (!(Test-Path $RegPath)) { New-Item $RegPath }

    Set-ItemProperty -Path $RegPath -Name FaceName -Type STRING -Value "Cascadia Code PL"
    Set-ItemProperty -Path $RegPath -Name FontSize -Type DWORD -Value 0x00120000
    Set-ItemProperty -Path $RegPath -Name ScreenColors -Type DWORD -Value 0x00000001
    Set-ItemProperty -Path $RegPath -Name CodePage -Type DWORD -Value 65001
}

# Refresh Shortcuts

if (!$IsCore)
{
    $WshShell = New-Object -ComObject WScript.Shell

    $Shortcut = $env:USERPROFILE + '\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell_New.lnk'
    $WshShortcut = $WshShell.CreateShortcut($Shortcut)
    $WshShortcut.TargetPath = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe'
    $WshShortcut.Description = 'Performs object-based (command-line) functions'
    $WshShortcut.IconLocation = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe, 0'
    $WshShortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
    $WshShortcut.Save()
    Start-Sleep -Seconds 3
    Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk"
    Rename-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell_New.lnk" -NewName "Windows PowerShell.lnk"

    $Shortcut = $env:USERPROFILE + '\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86)_New.lnk'
    $WshShortcut = $WshShell.CreateShortcut($Shortcut)
    $WshShortcut.TargetPath = '%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe'
    $WshShortcut.Description = 'Performs object-based (command-line) functions'
    $WshShortcut.IconLocation = '%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe, 0'
    $WshShortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
    $WshShortcut.Save()
    Start-Sleep -Seconds 3
    Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86).lnk"
    Rename-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86)_New.lnk" -NewName "Windows PowerShell (x86).lnk"
}

# Copy this script to Scripts folder

if (!(Test-Path -Path $ProfilePath\Scripts))
{
    mkdir -Path $ProfilePath\Scripts
}
Copy-Item -Path $PSCommandPath -Destination $ProfilePath\Scripts

Write-Host 'Execution Finished'
Write-Host 'Restart Your Console Host and Check the Result'
Pause
Exit
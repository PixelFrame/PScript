##########################################################################
##             PowerShell Auto Configuration Script v0.1                ##
##                                                          Pixel Frame ##
##                                                                      ##
##  1. [Plug-in] oh-my-posh & posh-git                                  ##
##    1.1 ParadoxE Theme                                                ##
##  2. [Config] User Profile                                            ##
##  3. [Software] Chocolatey                                            ##
##    3.1 Color Tool                                                    ##
##    3.2 Sudo                                                          ##
##    3.3 Screenfetch                                                   ##
##  4. [Font] Sarasa Mono                                               ##
##                                                                      ##
##########################################################################

Write-Host '############################################'
Write-Host '##                                        ##'
Write-Host '##      PowerShell AutoConfig Script      ##'
Write-Host '##                                        ##'
Write-Host '############################################'
Write-Host ''

Set-Location -Path $env:USERPROFILE

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
            Write-Host 'Continue to execute'
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

Write-Host '[Info] Installing oh-my-posh & posh-git'

try
{
    Install-Module posh-git -Scope CurrentUser
    Install-Module oh-my-posh -Scope CurrentUser
    
}
catch
{
    $Error
    Write-Host '[Error] Unable to Install Module' -ForegroundColor Red
    Write-Host 'Script Aborted' -ForegroundColor Red
    Pause
    Exit
}

Write-Host '[Info] Adding PoshTheme ParadoxE'

$PoshThemePE = 
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
$sl.PromptSymbols.StartSymbol =  ' ' + [char]::ConvertFromUtf32(0x266F) + ' '
$sl.PromptSymbols.PromptIndicator = [char]::ConvertFromUtf32(0x276F)
$sl.PromptSymbols.SegmentForwardSymbol = [char]::ConvertFromUtf32(0xE0B0)
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
$PoshThemePEPath = $env:USERPROFILE + '\Documents\WindowsPowerShell\PoshThemes\ParadoxE.psm1'
Out-File -FilePath $PoshThemePEPath -Encoding utf8 -InputObject $PoshThemePE

Write-Host '[Info] Writing to User PowerShell Profile'
$ProfilePath = $env:USERPROFILE + '\Documents\WindowsPowerShell\Profile.ps1'
$Profile = @'
Import-Module oh-my-posh
Set-Theme ParadoxE
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

$PathNpp = ${Env:ProgramFiles(x86)} + "/Notepad++/notepad++.exe"
if (Test-Path -Path $PathNpp)
{
    New-Alias -Name npp -Value $PathNpp -Description "Notepad++"
}
else
{
    Write-Host "[WARNING] Notepad++ Not Exist"
}

# Welcome
Write-Host @"

__/\\\\\\\\\\\\\_____________________/\\\\\\\\\\\____/\\\_________        
 _\/\\\/////////\\\_________________/\\\/////////\\\_\/\\\_________       
  _\/\\\_______\/\\\________________\//\\\______\///__\/\\\_________      
   _\/\\\\\\\\\\\\\/______/\\\\\______\////\\\_________\/\\\_________     
    _\/\\\/////////______/\\\///\\\_______\////\\\______\/\\\\\\\\\\__    
     _\/\\\______________/\\\__\//\\\_________\////\\\___\/\\\/////\\\_   
      _\/\\\_____________\//\\\__/\\\___/\\\______\//\\\__\/\\\___\/\\\_  
       _\/\\\______________\///\\\\\/___\///\\\\\\\\\\\/___\/\\\___\/\\\_ 
        _\///_________________\/////_______\///////////_____\///____\///__

"@ -ForegroundColor Cyan
'@
Out-File -FilePath $ProfilePath -Encoding utf8 -InputObject $Profile

Write-Host '[Info] Downloading ColorTool'
Invoke-WebRequest -Uri "https://github.com/microsoft/terminal/releases/download/1904.29002/ColorTool.zip" -OutFile ".\ColorTool.zip"
Expand-Archive -Path .\ColorTool.zip -DestinationPath .\ColorTool

Write-Host '[Info] Setting Color Theme'
.\ColorTool\ColorTool.exe -b OneHalfLight.itermcolors

Write-Host '[Info] Removing ColorTool'
Remove-Item -Path .\ColorTool.zip
Remove-Item -Path .\ColorTool -Force -Recurse

try 
{
    Get-Command choco.exe
}
catch
{
    Write-Host '[Info] Chocolatey is not installed'
    Write-Host '[Info] Installing Chocolatey'
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

if ($IsAdmin)
{
    Write-Host '[Info] Installing Softwares via Chocolatey'
    choco install ColorTool -y
    choco install Sudo -y
    choco install Screenfetch -y
}
else
{
    Write-Host '[Warning] No Administrator Privilege, skipping choco install' -ForegroundColor Yellow
}

while ($IsInstallFont = Read-Host -Prompt 'Install Font: Sarasa Mono? Y/N')
{
    if ($IsInstallFont.Equals('y') -or $IsInstallFont.Equals('Y')) 
    {
        Write-Host '[Info] Installing Fonts'
        Invoke-Download -SourceUri "https://github.com/be5invis/Sarasa-Gothic/releases/download/v0.10.2/sarasa-gothic-ttf-0.10.2.7z" -Retry 3
        Expand-Archive -Path ".\sarasa-gothic-ttf-0.10.2.7z" -DestinationPath ".\sarasa-gothic-ttf-0.10.2.7z"
        break
    }
    elseif ($IsInstallFont.Equals('n') -or $IsInstallFont.Equals('N'))
    {
        Write-Host '[Info] Skipped Font Installation'
        break
    }
}

Write-Host 'Execution Finished'
Pause
Exit

function Invoke-Download
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SourceUri,
        [System.UInt32]
        $Retry = 3
    )
    $WebClient = New-Object system.net.webclient
    $FileName = $SourceUri.Substring($SourceUri.LastIndexOf('\') + 1)
    $DestPath = ".\" + $FileName

    $AttemptCount = 0
    Do
    {
        $AttemptCount++
        $WebClient.DownloadFile($SourceURI, $DestPath)
    } while (((Test-Path $DestPath) -eq $false) -and ($AttemptCount -le $Retry))
}
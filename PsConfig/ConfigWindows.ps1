#requires -RunAsAdministrator

#region Helper Functions
function Test-AppAvailability
{
    param (
        [string] $cmdlet
    )
    try 
    {
        Get-Command $cmdlet -ErrorAction Stop | Out-Null
        return $true
    }
    catch { return $false }
}
#endregion

#region Script Variables
$Script:Version = '0.0.2-ALPHA'
$Script:WinPsProfileDir = "$($env:USERPROFILE)\Documents\WindowsPowerShell"
$Script:PwshProfileDir = "$($env:USERPROFILE)\Documents\PowerShell"
$Script:PoshConfig = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "background": "#0050ac",
          "foreground": "#b6dcff",
          "powerline_symbol": "\ue0b8 ",
          "style": "powerline",
          "template": " \uf0e7 ",
          "type": "root"
        },
        {
          "background": "#358dff",
          "foreground": "#100e23",
          "powerline_symbol": "\ue0b8 ",
          "style": "powerline",
          "template": " {{ if .SSHSession }}\uf817 {{ end }}{{ .UserName }}@{{ .HostName }} ",
          "type": "session"
        },
        {
          "background": "#91ddff",
          "foreground": "#100e23",
          "powerline_symbol": "\ue0b8 ",
          "properties": {
            "folder_icon": "\uf115",
            "folder_separator_icon": "\\",
            "style": "full"
          },
          "style": "powerline",
          "template": " {{ .Path }} ",
          "type": "path"
        },
        {
          "background": "#b6dcff",
          "foreground": "#100e23",
          "powerline_symbol": "\ue0b8 ",
          "style": "powerline",
          "template": " {{ .HEAD }} {{ .BranchStatus }}{{ if .Working.Changed }} \u2026{{ .Working.String }}{{ end }}{{ if and (.Staging.Changed) (.Working.Changed) }} |{{ end }}{{ if .Staging.Changed }} Â·{{ .Staging.String }}{{ end }}{{ if gt .StashCount 0}} \uf692 {{ .StashCount }}{{ end }}{{ if gt .WorktreeCount 0}} \uf1bb {{ .WorktreeCount }}{{ end }} ",
          "type": "git"
        },
        {
          "type": "executiontime",
          "style": "powerline",
          "powerline_symbol": "\ue0b8 ",
          "foreground": "#100e23",
          "background": "#ccdbf1",
          "template": " <#100e23>\ufbab</> {{ .FormattedMs }} ",
          "properties": {
            "threshold": 100,
            "style": "austin"
          }
        },
        {
          "background": "#00245a",
          "foreground": "#ffffff",
          "powerline_symbol": "\ue0b8 ",
          "properties": {
            "display_exit_code": true
          },
          "style": "powerline",
          "template": " Err: {{ if gt .Code 0 }}\uf00d {{ .Code }}{{ else }}\uf42e{{ end }} ",
          "type": "exit"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "segments": [
        {
          "foreground": "#b6dcff",
          "properties": {
            "time_format": "[15:04:05]"
          },
          "style": "plain",
          "template": " {{ .CurrentDate | date .Format }} ",
          "type": "time"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "#007ACC",
          "style": "plain",
          "template": "\u276f ",
          "type": "text"
        }
      ],
      "type": "prompt"
    }
  ],
  "version": 2
}
'@
$Script:ProfilePs1 = @"
# Set Posh Theme
oh-my-posh.exe init pwsh --config ~\.poshconfig.json | Invoke-Expression
# Alias
. "$($Script:PwshProfileDir)\Scripts\Alias.ps1"
# Functions
. "$($Script:PwshProfileDir)\Scripts\Functions.ps1"
# Host Title
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    `$IsAdmin = '[Administrator] '
}
else { `$IsAdmin = '' }
`$Host.UI.RawUI.WindowTitle = `$IsAdmin + `$env:USERDOMAIN + '\' + `$env:USERNAME + ' PowerShell ' +  `$PSVersionTable.PSVersion.ToString() + " @ " + [environment]::OSVersion.VersionString

# Welcome
Write-Host @'
    ____ _       _______ __  __
   / __ \ |     / / ___// / / /
  / /_/ / | /| / /\__ \/ /_/ / 
 / ____/| |/ |/ /___/ / __  /  
/_/     |__/|__//____/_/ /_/   

'@ -ForegroundColor Blue
"@
#endregion

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

#region Install winget
if (!(Test-AppAvailability winget))
{
    if (!(Get-AppxPackage Microsoft.DesktopAppInstaller))
    {
        Add-AppxPackage 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

        $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $releases = Invoke-RestMethod -Uri "$($releases_url)"
        $latestMsix = ($releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1).browser_download_url
        try { Add-AppPackage -Path $latestMsix -ErrorAction Stop }
        catch
        {
            $_.Exception.InnerException.Message
            "Please download and install Microsoft.UI.Xaml manually and try again."
            exit
        }
    }
    else
    {
        "Appx installation has finished while winget cli is still not available..."
        "Restart the terminal and try again. If the error continues, try Add-ProvisionedAppxPackage."
        exit
    }
}
#endregion

#region Install Chocolatey
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#endregion

#region Install git, VSCode, Notepad3, Windows Terminal, pwsh, gsudo
if (!(Test-AppAvailability git)) { winget install 'Git.Git' -h }
if (!(Test-AppAvailability code.cmd)) { winget install 'Microsoft.VisualStudioCode' -h }
choco install 'Notepad3' -y
if (!(Test-AppAvailability wt)) { winget install 'Microsoft.WindowsTerminal' -h }
if (!(Test-AppAvailability pwsh)) { winget install 'Microsoft.PowerShell' -h }
if (!(Test-AppAvailability gsudo)) { winget install 'gerardog.gsudo' -h }
if (!(Test-AppAvailability oh-my-posh)) { winget install 'JanDeDobbeleer.OhMyPosh' -h }
if (!(Test-AppAvailability nanazip)) { winget install 'M2Team.NanaZip' -h }
#endregion

#region Install fonts
choco install 'cascadiafonts' 'cascadia-code-nerd-font' -y
#endregion

#region Configure oh-my-posh
$Utf8WithoutBom = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$($env:USERPROFILE)\.poshconfig.json", $Script:PoshConfig, $Utf8WithoutBom)
#endregion

#region Configure PS profile
if (!(Test-Path $Script:PwshProfileDir )) { New-Item $Script:PwshProfileDir -ItemType Directory | Out-Null }
if (!(Test-Path $Script:PwshProfileDir\Scripts )) { New-Item $Script:PwshProfileDir\Scripts -ItemType Directory | Out-Null }
if ((Test-Path $Script:WinPsProfileDir )) { Remove-Item $Script:WinPsProfileDir -Recurse -Force }
New-Item -Path $Script:WinPsProfileDir -ItemType Junction -Value $Script:PwshProfileDir
$Utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines("$Script:PwshProfileDir\Microsoft.PowerShell_profile.ps1", $Script:ProfilePs1, $Utf8WithBom)
'# User Defined Functions' | Out-File "$Script:PwshProfileDir\Scripts\Functions.ps1"
'# User Defined Aliases' | Out-File "$Script:PwshProfileDir\Scripts\Alias.ps1"
#endregion

#region Configure Windows Terminal
$WinTermJson = $env:LOCALAPPDATA + '\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$WinTermSetting = ConvertFrom-Json (Get-Content $WinTermJson -Raw)
$WinTermSetting | Add-Member @{tabWidthMode = 'compact' } -Force
$WinTermSetting.profiles.defaults | Add-Member @{font = @{face = 'CaskaydiaCove NF' } } -Force
$WinTermSetting | ConvertTo-Json -Depth 4 | Set-Content $WinTermJson
#endregion

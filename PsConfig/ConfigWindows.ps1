#requires -RunAsAdministrator

[CmdletBinding()]
param (
  [Parameter()]
  [ValidateSet('Base', 'Coding', 'Media', 'Extra', 'All')]
  [string[]]
  $AppSet = 'Base',

  [switch]
  $SkipProfileConfig
)

#region Helper Functions
function Test-AppAvailability
{
  param (
    [string] $App,
    [int] $Mode = 0
  )
  if ($mode -eq 0)
  {
    try 
    {
      Get-Command $App -ErrorAction Stop | Out-Null
      return $true
    }
    catch { return $false }
  }
  else
  {
    return Test-Path($App)
  }
}
#endregion

#region Script Variables
$Script:Version = '0.0.4-ALPHA'
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
    $latestLicense = ($releases.assets | Where-Object { $_.browser_download_url -Like "*License*.xml" } | Select-Object -First 1).browser_download_url
    try { Add-ProvisionedAppxPackage -Online -PackagePath $latestMsix -LicensePath $latestLicense -ErrorAction Stop }
    catch
    {
      $_.Exception.InnerException.Message
      "Please download and install Microsoft.UI.Xaml manually and try again."
      exit
    }
    "winget installation completed. Restart the terminal to refresh the environment variables."
    exit
  }
  else
  {
    "Appx installation has finished while winget cli is still not available..."
    "Restart the terminal and try again."
    exit
  }
}
#endregion

#region Install Chocolatey
if (!(Test-AppAvailability choco))
{
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
#endregion

#region Application Table
class App
{
  App (
    [string] $FullName,
    [int] $Source,
    [string] $AvailabilityTestString,
    [int] $AvailabilityTestMode
  )
  {
    $this.FullName = $FullName
    $this.Source = $Source
    $this.AvailabilityTestString = $AvailabilityTestString
    $this.AvailabilityTestMode = $AvailabilityTestMode
  }
  [string] $FullName;
  [int] $Source; # 0: winget, 1: choco, 2: manual
  [string] $AvailabilityTestString;
  [int] $AvailabilityTestMode; # 0: Get-Command, 1: Test-Path
}

$AppTable = @()
$AppTableBase = @()
$AppTableMedia = @()
$AppTableCoding = @()
$AppTableExtra = @()

$AppTableBase += [App]::new('gerardog.gsudo', 0, 'gsudo', 0)
$AppTableBase += [App]::new('Microsoft.WindowsTerminal', 0, 'wt', 0)
$AppTableBase += [App]::new('Microsoft.PowerShell', 0, 'pwsh', 0)
$AppTableBase += [App]::new('JanDeDobbeleer.OhMyPosh', 0, 'oh-my-posh', 0)
$AppTableBase += [App]::new('M2Team.NanaZip', 0, 'nanazip', 0)
$AppTableBase += [App]::new('Rizonesoft.Notepad3', 0, 'notepad3', 0)
$AppTableBase += [App]::new('DuongDieuPhap.ImageGlass', 0, "$env:ProgramFiles/ImageGlass", 1)

$AppTableCoding += [App]::new('Microsoft.VisualStudioCode', 0, 'code.cmd', 0)
$AppTableCoding += [App]::new('Git.Git', 0, 'git', 0)

$AppTableMedia += [App]::new('CodecGuide.K-LiteCodecPack.Mega', 0, "${env:ProgramFiles(x86)}\K-Lite Codec Pack", 1)

$AppTableExtra += [App]::new('Microsoft.PowerToys', 0, "$env:ProgramFiles/PowerToys", 1)

if ($AppSet -contains 'All')
{
  $AppTable = $AppTableBase + $AppTableCoding + $AppTableMedia + $AppTableExtra
}
else
{
  $AppTable += $AppTableBase
  if ($AppSet -contains 'Coding') { $AppTable += $AppTableCoding }
  if ($AppSet -contains 'Media') { $AppTable += $AppTableMedia }
  if ($AppSet -contains 'Extra') { $AppTable += $AppTableExtra }
}
#endregion

#region Application Installation
foreach ($App in $AppTable)
{
  if ($App.Source -eq 0)
  {
    if (!(Test-AppAvailability $App.AvailabilityTestString -Mode $App.AvailabilityTestMode))
    {
      "Installing $($App.FullName) from winget"
      winget install $App.FullName -h
    }
  }
  else
  {
    if (!(Test-AppAvailability $App.AvailabilityTestString -Mode $App.AvailabilityTestMode))
    {
      "Installing $($App.FullName) from choco"
      choco install $App.FullName -y
    }
  }
}

#endregion

#region Install fonts
choco install 'cascadiafonts' 'cascadia-code-nerd-font' -y
#endregion

#region Configure oh-my-posh
$Utf8WithoutBom = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$($env:USERPROFILE)\.poshconfig.json", $Script:PoshConfig, $Utf8WithoutBom)
#endregion

#region Configure PS profile
if (!$SkipProfileConfig)
{
  if (!(Test-Path $Script:PwshProfileDir )) { New-Item $Script:PwshProfileDir -ItemType Directory | Out-Null }
  if (!(Test-Path $Script:PwshProfileDir\Scripts )) { New-Item $Script:PwshProfileDir\Scripts -ItemType Directory | Out-Null }
  if ((Get-Item $Script:WinPsProfileDir).LinkType -ne 'Junction')
  {
    if ((Test-Path $Script:WinPsProfileDir )) { Move-Item -LiteralPath $Script:WinPsProfileDir -Destination $Script:PwshProfileDir\WinPsProfileBackup -Force }
    New-Item -Path $Script:WinPsProfileDir -ItemType Junction -Value $Script:PwshProfileDir
  }
  $Utf8WithBom = New-Object System.Text.UTF8Encoding $true
  [System.IO.File]::WriteAllLines("$Script:PwshProfileDir\Microsoft.PowerShell_profile.ps1", $Script:ProfilePs1, $Utf8WithBom)
  if (!(Test-Path $Script:PwshProfileDir\Scripts\Functions.ps1 )) { '# User Defined Functions' | Out-File "$Script:PwshProfileDir\Scripts\Functions.ps1" }
  if (!(Test-Path $Script:PwshProfileDir\Scripts\Alias.ps1 )) { '# User Defined Aliases' | Out-File "$Script:PwshProfileDir\Scripts\Alias.ps1" }
}
#endregion

#region Configure Windows Terminal
$WinTermJson = $env:LOCALAPPDATA + '\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (!(Test-Path($WinTermJson)))
{
  "Windows Terminal setting file not found. Please run wt once and then run this script again."
  exit
}
$WinTermSetting = ConvertFrom-Json (Get-Content $WinTermJson -Raw)
$WinTermSetting | Add-Member @{tabWidthMode = 'compact' } -Force
$WinTermSetting.profiles.defaults | Add-Member @{font = @{face = 'CaskaydiaCove NF' } } -Force
$WinTermSetting | ConvertTo-Json -Depth 4 | Set-Content $WinTermJson
#endregion

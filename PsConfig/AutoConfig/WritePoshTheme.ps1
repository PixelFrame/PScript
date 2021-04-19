[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PSType,
    
    [switch]
    $PoshV3
)


$ProfilePath = $env:USERPROFILE + '\Documents\' + $PSType
Write-Host '[Info] Adding PoshTheme ParadoxCascadia'

$PoshV2ThemeContent = 
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

$PoshV3ThemeContent =
@'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "background": "#0050ac",
          "foreground": "#b6dcff",
          "powerline_symbol": "\ue0b0",
          "style": "powerline",
          "type": "root",
          "properties": {
            "root_icon": "#"
          }
        },
        {
          "background": "#358dff",
          "foreground": "#100e23",
          "powerline_symbol": "\ue0b0",
          "style": "powerline",
          "type": "session"
        },
        {
          "background": "#91ddff",
          "foreground": "#100e23",
          "powerline_symbol": "\ue0b0",
          "properties": {
            "folder_icon": "\uf115",
            "folder_separator_icon": "\\",
            "style": "full"
          },
          "style": "powerline",
          "type": "path"
        },
        {
          "background": "#b6dcff",
          "foreground": "#100e23",
          "powerline_symbol": "\ue0b0",
          "style": "powerline",
          "type": "git",
          "properties": {
            "local_working_icon": " \u2026",
            "local_staged_icon": " \u00b7"
          }
        },
        {
          "background": "#00245a",
          "foreground": "#ffffff",
          "powerline_symbol": "\ue0b0",
          "properties": {
            "prefix": " Err: ",
            "display_exit_code": true,
            "always_numeric": true
          },
          "style": "powerline",
          "type": "exit"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "segments": [
        {
          "style": "plain",
          "foreground": "#b6dcff",
          "type": "time",
          "properties": {
            "time_format": "[15:04:05]"
          }
        }
      ],
      "type": "prompt"
    },
    {
      "type": "newline"
    },
    {
      "alignment": "left",
      "segments": [
        {
          "foreground": "#007ACC",
          "properties": {
            "prefix": "",
            "text": "\u276f"
          },
          "style": "plain",
          "type": "text"
        }
      ],
      "type": "prompt"
    }
  ],
  "final_space": false
}
'@

$PoshV2ThemePath = $ProfilePath + '\PoshThemes\'
if (!(Test-Path $PoshV2ThemePath))
{
    New-Item -Path $PoshV2ThemePath -ItemType Directory | Out-Null
}
$PoshV2ThemePath += 'ParadoxCascadia.psm1'

$PoshV3ThemePath = $env:USERPROFILE + '\.poshthemes\'
if (!(Test-Path $PoshV3ThemePath))
{
    New-Item -Path $PoshV3ThemePath -ItemType Directory | Out-Null
}
$PoshV3ThemePath += 'ParadoxCascadiaV3.json'

if ($PoshV3)
{
    Out-File -FilePath $PoshV3ThemePath -Encoding utf8 -InputObject $PoshV3ThemeContent
}
else
{
    Out-File -FilePath $PoshV2ThemePath -Encoding utf8 -InputObject $PoshV2ThemeContent
}
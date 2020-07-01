# PowerShell Customize

## Module: oh-my-posh and posh-git

oh-my-posh is a module for PowerShell to customize prompt style. You can check the themes from its [Project page](https://github.com/JanDeDobbeleer/oh-my-posh#themes).
To install, run the command below. The scope can be user or machine(need Administrator privilege) and the installation location will change accordingly.

```PowerShell
Install-Module oh-my-posh -Scope CurrentUser
```

Then we will import the modules and the theme.

```PowerShell
Import-Module oh-my-posh
Set-Theme Paradox
```

Note you have to install git to make posh-git module work properly, even if you do not use git. Otherwise, every time you import oh-my-posh there will be error.

My theme is edited based on the Paradox theme. Changed the color scheme and replaced some symbols to make it capable with Cascadia Code font. Custom themes need to be saved under `$Env:UserProfile\Documents\WindowsPowerShell\PoshThemes` to be loaded automatically.
[ParadoxCascadia](https://github.com/PixelFrame/PScript/blob/master/PsTheme/ParadoxCascadia.psm1)

## Profile

The 2 modules mentioned above needs to be imported every time PowerShell is launched. So we will need Profile files.
The profile file is basically a script that will be executed every time PowerShell launches. Make sure you have Execution Policy set to bypass.
According to the user and host type, there'll be 4 [different profiles](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles). Usually, we just need to use Current user's normal host, so just save the script as `Microsoft.PowerShell_profile.ps1` under `$Env:UserProfile\Documents\WindowsPowerShell`

In the profile, we will import the module, set the theme and display the welcome banner. I also changed host title with domain, username and OS. If needed we can add some alias for quick launches.

```PowerShell
Import-Module oh-my-posh
Set-Theme ParadoxCascadia
$ThemeSettings.Options.ConsoleTitle = $false

Write-Host @"
 _       _______   ______  _____
| |     / /  _/ | / / __ \/ ___/
| | /| / // //  |/ / /_/ /\__ \
| |/ |/ // // /|  / ____/___/ /
|__/|__/___/_/ |_/_/    /____/

"@ -ForegroundColor Blue

$Host.UI.RawUI.WindowTitle = $env:USERDOMAIN + '\'
if (Test-Administrator)
{
    $Host.UI.RawUI.WindowTitle += 'Administrator: '
}
else
{
    $Host.UI.RawUI.WindowTitle += $env:USERNAME + ': '
}
$Host.UI.RawUI.WindowTitle += $HostTitle + ' ' + $PSVersionTable.PSVersion.ToString() + ' @ ' + [environment]::OSVersion.VersionString
```

## Coloring

For Windows default console host(conhost.exe), we will use [ColorTool](https://github.com/microsoft/terminal/releases/tag/1904.29002) to quickly apply the color scheme.
My color theme is edited from OneHalfLight theme.

Download ColorTool and save the ini color scheme in the same folder. Open conhost and run the command.

```PowerShell
colortool.exe -b .\OneHalfLightE.ini
```

```ini
[table]
DARK_BLACK = 55,57,66
DARK_BLUE = 0,132,188
DARK_GREEN = 79,161,79
DARK_CYAN = 9,150,179
DARK_RED = 228,86,73
DARK_MAGENTA = 166,37,164
DARK_YELLOW = 192,132,0
DARK_WHITE = 250,250,250
BRIGHT_BLACK = 97,97,97
BRIGHT_BLUE = 97,175,239
BRIGHT_GREEN = 152,195,121
BRIGHT_CYAN = 86,181,193
BRIGHT_RED = 223,108,117
BRIGHT_MAGENTA = 197,119,221
BRIGHT_YELLOW = 228,192,122
BRIGHT_WHITE = 255,255,255

[screen]
FOREGROUND = BRIGHT_BLUE
BACKGROUND = DARK_BLACK

[popup]
FOREGROUND = BRIGHT_WHITE
BACKGROUND = BRIGHT_RED
```

## Terminal

After run the ColorTool, the color scheme is changed. However the color for foreground and background will not be changed automatically. Also we will need to change the font for better effect. The font used is [Cascadia Code PL](https://github.com/microsoft/cascadia-code/releases).
These settings are stored registry keys. The following script will set the configuration of both 32bit and 64bit Windows PowerShell and PowerShell 7.

```PowerShell
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
```

However, if the PowerShell instance is launched from a shortcut(.lnk), the lnk file itself would contain stand alone configurations that overwrite the registry settings. So after changing the registry, a refresh of the shortcuts will be necessary. The following script will refresh the shortcuts in Start Menu. It is also effective for the shortcut in Win+X Menu, although Win+X Menu has its own shortcut files but somehow it seems they are linked to Start Menu shortcuts.

```PowerShell
$WshShell = New-Object -ComObject WScript.Shell

$Shortcut = $env:USERPROFILE + '\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell_New.lnk'
$WshShortcut = $WshShell.CreateShortcut($Shortcut)
$WshShortcut.TargetPath = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe'
$WshShortcut.Description = 'Performs object-based (command-line) functions'
$WshShortcut.IconLocation = '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe,0'
$WshShortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
$WshShortcut.Save()
Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk"
Rename-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell_New.lnk" -NewName "Windows PowerShell.lnk"

$Shortcut = $env:USERPROFILE + '\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86)_New.lnk'
$WshShortcut = $WshShell.CreateShortcut($Shortcut)
$WshShortcut.TargetPath = '%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe'
$WshShortcut.Description = 'Performs object-based (command-line) functions'
$WshShortcut.IconLocation = '%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe,0'
$WshShortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
$WshShortcut.Save()
Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86).lnk"
Rename-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell (x86)_New.lnk" -NewName "Windows PowerShell (x86).lnk"
```

## AutoConfig

The auto configuration script for all the steps above. Will use chocolatey to install git, Cascadia Code font and ColorTool.

[AutoConfig.ps1](https://github.com/PixelFrame/PScript/blob/master/PsConfig/AutoConfig.ps1)

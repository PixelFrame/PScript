. $PSScriptRoot\Invoke-Download.ps1

try
{
    Get-Command -Name 'ColorTool.exe' -ErrorAction Stop | Out-Null
}
catch
{
    Write-Host '[Info] Downloading ColorTool'
    Invoke-Download -SourceUri "https://github.com/microsoft/terminal/releases/download/1904.29002/ColorTool.zip" -Destination $Env:USERPROFILE -Retry 3
    Expand-Archive -Path $Env:USERPROFILE\ColorTool.zip -DestinationPath $Env:USERPROFILE\ColorTool
    $NoColorToolInstallation = $true
}


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
$CTThemePath = $Env:USERPROFILE + '\OneHalfLightE.ini';

# Attention: ColorTool.exe only recognize UTF-8 No BOM
# For PowerShell 7, Out-File encoding utf8NoBOM is available
# Out-File -FilePath $CTThemePath -Encoding utf8NoBOM -InputObject $OneHalfLightE 
# For Windows PowerShell 5, using .NET IO is the only way
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($CTThemePath, $OneHalfLightE, $Utf8NoBomEncoding)

Write-Host '[Info] Setting Color Theme'
if ($NoColorToolInstallation)
{
    & $Env:USERPROFILE\ColorTool\ColorTool.exe -b $CTThemePath
}
else
{ 
    ColorTool.exe -b $CTThemePath
}

Write-Host '[Info] Removing ColorTool Temp Files'
Remove-Item -Path $Env:USERPROFILE\OneHalfLightE.ini -ErrorAction SilentlyContinue
Remove-Item -Path $Env:USERPROFILE\ColorTool.zip -ErrorAction SilentlyContinue
Remove-Item -Path $Env:USERPROFILE\ColorTool -Force -Recurse -ErrorAction SilentlyContinue
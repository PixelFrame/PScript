# Import oh-my-posh
try
{
    Import-Module oh-my-posh
    Set-Theme ParadoxE
}
catch
{
    Write-Host "[WARNING] Missing Module oh-my-posh"
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
Write-Host "KERNEL IN THE SHELL - Pixel Frame Dev." -ForegroundColor DarkCyan
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

# try
# {
#     Screenfetch
# }
# catch
# { }
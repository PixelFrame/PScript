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

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $InterfaceAlias = "Ethernet",

    [Parameter()]
    [string]
    $ScriptPath = "$PSScriptRoot\Enable-DAIsatapRouter.ps1"
)

$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -ExecutionPolicy Bypass -File $ScriptPath -InterfaceAlias $InterfaceAlias -Transcript"
$principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId SYSTEM
$trigger = New-ScheduledTaskTrigger -AtStartup
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask -TaskName "Enable ISATAP Router" -InputObject $task
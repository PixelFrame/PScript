[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $OutPath = $env:SystemDrive + '\PortMonitor',

    [Parameter()]
    [int]
    $LogLimit = 50
)

if (!(Test-Path $OutPath))
{ 
    try
    {
        mkdir $OutPath
    }
    catch
    {
        'Cannot create output path.'
        $Error[0]
        exit
    }
}

$Ports = Get-NetTCPConnection | Select-Object -Property LocalPort, OwningProcess, State | Sort-Object -Property LocalPort

$PortWithProcess = @()
foreach ($Port in $Ports)
{
    $Process = Get-Process -PID $Port.OwningProcess
    $PortWithProcess += New-Object PSObject -Property @{'LocalPort' = $Port.LocalPort; 'PortState' = $Port.State; 'PID' = $Port.OwningProcess; 'ProcessName' = $Process.Name; 'CommandLine' = $Process.Path; 'Handles' = $Process.Handles; } 
}

$LogFile = $OutPath + '\PortUsage-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log'

try
{
    'Ports:' | Out-File -FilePath $LogFile -Encoding utf8 -Force 
    $PortWithProcess | Format-Table -Property LocalPort, PID, ProcessName, PortState, CommandLine -AutoSize | Out-File -FilePath $LogFile -Encoding utf8 -Append
    '' | Out-File -FilePath $LogFile -Encoding utf8 -Append
    'Statics:' | Out-File -FilePath $LogFile -Encoding utf8 -Append
    $PortWithProcess | Group-Object -Property ProcessName | Out-File -FilePath $LogFile -Encoding utf8 -Append

}
catch
{
    'Unable to write to log file.'
    $Error[0]
    exit
}

$Logs = Get-ChildItem $OutPath'\PortUsage*'
if ($Logs.Count -gt $LogLimit) { Remove-Item $Logs[0] -Force }
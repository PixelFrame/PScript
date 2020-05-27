if (!(Test-Path 'C:\PortMonitor')) { mkdir 'C:\PortMonitor' }

$Ports = Get-NetTCPConnection | Select-Object -Property LocalPort, OwningProcess, State | Sort-Object -Property LocalPort

$PortWithProcess = @()
foreach ($Port in $Ports)
{
    $Process = Get-Process -PID $Port.OwningProcess
    $PortWithProcess += New-Object PSObject -Property @{'LocalPort' = $Port.LocalPort; 'PortState' = $Port.State; 'PID' = $Port.OwningProcess; 'ProcessName' = $Process.Name; 'CommandLine' = $Process.Path; 'Handles' = $Process.Handles; } 
}

$LogFile = 'C:\PortMonitor\PortUsage-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log'

'Ports:' | Out-File -FilePath $LogFile -Encoding utf8 -Force 
$PortWithProcess | Format-Table -Property LocalPort, PID, ProcessName, PortState, CommandLine -AutoSize | Out-File -FilePath $LogFile -Encoding utf8 -Append
'' | Out-File -FilePath $LogFile -Encoding utf8 -Append
'Statics:' | Out-File -FilePath $LogFile -Encoding utf8 -Append
$PortWithProcess | Group-Object -Property ProcessName | Out-File -FilePath $LogFile -Encoding utf8 -Append

$Logs = Get-ChildItem 'C:\PortMonitor\PortUsage*'
if($Logs.Count -gt 50) {Remove-Item $Logs[0] -Force}
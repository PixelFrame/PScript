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
        mkdir $OutPath | Out-Null
    }
    catch
    {
        'Cannot create output path.'
        $Error[0]
        exit
    }
}

$TCPConns = Get-NetTCPConnection
$UDPEps = Get-NetUDPEndpoint

$ConnInfo = @()
foreach ($TCPConn in $TCPConns)
{
    $Proc = Get-Process -PID $TCPConn.OwningProcess
    $PropTable = [Ordered]@{
        Protocol      = 'TCP';
        LocalAddress  = $TCPConn.LocalAddress; 
        LocalPort     = $TCPConn.LocalPort; 
        RemoteAddress = $TCPConn.RemoteAddress;
        RemotePort    = $TCPConn.RemotePort;
        State         = $TCPConn.State;
        ProcessId     = $Proc.Id;
        ProcessName   = $Proc.ProcessName;
        ProcessHandle = $Proc.HandleCount;
        CommandLine   = $Proc.Path
    } 
    $ConnInfo += New-Object PSObject -Property $PropTable
}

foreach ($UDPEp in $UDPEps)
{
    $Proc = Get-Process -PID $UDPEp.OwningProcess
    $PropTable = [Ordered]@{
        Protocol      = 'UDP';
        LocalAddress  = $UDPEp.LocalAddress; 
        LocalPort     = $UDPEp.LocalPort; 
        RemoteAddress = 'N/A'
        RemotePort    = 'N/A'
        State         = 'N/A'
        ProcessId     = $Proc.Id;
        ProcessName   = $Proc.ProcessName;
        ProcessHandle = $Proc.HandleCount;
        CommandLine   = $Proc.Path
    } 
    $ConnInfo += New-Object PSObject -Property $PropTable
}

$BaseFile = $OutPath + '\PortUsage-' + (Get-Date -Format 'yyyyMMdd-HHmmssffff')
$CsvFile = $BaseFile + '.csv'

try
{
    $ConnInfo | Export-Csv -Path $CsvFile
}
catch
{
    'Unable to write to log file.'
    $Error[0]
    exit
}

$Logs = Get-ChildItem $OutPath'\PortUsage*'
if ($Logs.Count -gt $LogLimit) { Remove-Item $Logs[0] -Force }
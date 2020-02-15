# PowerShell TCP Port Test Script
# by Liuyi Sun <v-liuysu@microsoft.com>

# Parameters

# [int] CltMax : Maximum Client Socket Number
# [bool] SlowMode: Sleep when Sockets Connecting
# [double] SlowModeInterval: Sleep Interval in Second
# [string] RemoteIP: IPv4 Address to be Tested
# [int] RemotePort: Port to be Tested

# This script calls .NET Framework Socket API

[CmdletBinding()]
param (
    [int]
    $CltMax = 200,
    [bool]
    $SlowMode = $false,
    [double]
    $SlowModeInterval = 1,
    [string]
    $RemoteIP = "127.0.0.1",
    [int]
    $RemotePort = 80
)

function ClientOn
{
    param (
        
    )
    # Create Socket 
    $Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
    $Stype = [System.Net.Sockets.SocketType]::Stream
    $Ptype = [System.Net.Sockets.ProtocolType]::Tcp
    $Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

    return $Socket
}

function Test-IPv4AddressString
{
    param (
        [string]
        $TestStr
    )
    $RegExIPv4Str = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    return $TestStr -match $RegExIPv4Str
}

function CleanUp
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.Sockets.Socket[]]
        $CltSocketArray
    )
    foreach ($CltSocket in $CltSocketArray)
    {
        $CltSocket.Close()
    }
}

Clear-Host
"******************************** PowerShell TCP Test ********************************"
""
"Configuration"
"Test Endpoint At       : $($RemoteIP):$($RemotePort)"
"Client Maximum Number  : $CltMax"
"Slow Mode              : $SlowMode"
"Slow Mode Interval     : $SlowModeInterval sec"
""
"*************************************************************************************"
Pause

if (!(Test-IPv4AddressString $RemoteIP))
{
    Write-Host "[ERR] Invalid IPv4 Address" -ForegroundColor Red
    Pause
    Exit
}

if (($RemotePort -lt 1) -or ($RemotePort -gt 65536))
{
    Write-Host "[ERR] Port Number Error" -ForegroundColor Red
    Pause
    Exit
}

"[CLT] Starting Clients"
$CltSocketArray = @()

$RemoteAddress = [System.Net.IPAddress]::Parse($RemoteIP)
$RemoteEndpoint = New-Object System.Net.IPEndPoint $RemoteAddress, $RemotePort

for ($i = 1; $i -le $CltMax; ++$i)
{
    $CltSocket = ClientOn
    $CltSocketArray += $CltSocket
    "[CLT] Socket Created {0}/{1}" -f $i, $CltMax
}

Pause

$ConCnt = 0
$ErrCnt = 0
foreach ($CltSocket in $CltSocketArray)
{
    try
    {
        if ($SlowMode) { Start-Sleep -Seconds $SlowModeInterval }
        $CltSocket.Connect($RemoteEndpoint)
        ++$ConCnt
        "[CLT] Socket Connect: {0}/{1}" -f $ConCnt, $CltMax
    }
    catch
    {
        ++$ErrCnt
        Write-Host "Connection Failed: " $_.Exception.Message -ForegroundColor Red
        if ($ErrCnt -gt 3)
        {
            Write-Host "[ERR] More than 3 failures. Exiting..." -ForegroundColor Red
            Pause
            CleanUp -CltSocketArray $CltSocketArray
            Write-Host "[INFO] Socket Clean Up Completed"
            Pause
            Exit
        }
    }
}

Pause
CleanUp -CltSocketArray $CltSocketArray
"[CLT] Sockets Closed"
Pause
Exit
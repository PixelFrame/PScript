[CmdletBinding()]
param (
    [int]
    $CltMax = 200,
    [bool]
    $SlowMode = $false,
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

if (($RemotePort -lt 1) -or ($RemotePort -gt 65536))
{
    Write-Host "Port Number Error" -ForegroundColor Red
    Pause
    Exit
}

"[CLT] Starting Clients"
$CltSocketArray = @()

$RemoteIP = "127.0.0.1"
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
        if ($SlowMode) { Start-Sleep -Seconds 1 }
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
            "More than 3 failures. Exiting..."
            Pause
            CleanUp -CltSocketArray $CltSocketArray
            "Socket Clean Up Completed"
            Pause
            Exit
        }
    }
}

Pause
CleanUp -CltSocketArray $CltSocketArray
"Socket Closed"
Pause
Exit
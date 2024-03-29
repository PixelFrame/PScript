[CmdletBinding()]
param (
    [int]
    $BackLogMax = 200,

    [int]
    $CltMax = 200,

    [int]
    $LisPort = 2501
)

function ServerOn
{
    param (
        [int]
        $BackLog
    )
    $LocalPort = [int] $LisPort
    $LocalIP = [IPAddress]::Any
    $LocalAddress = [System.Net.IPAddress]::Parse($LocalIP)
    $LocalEndpoint = New-Object System.Net.IPEndPoint $LocalAddress, $LocalPort 
    $Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
    $Stype = [System.Net.Sockets.SocketType]::Stream
    $Ptype = [System.Net.Sockets.ProtocolType]::Tcp

    $Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype
    try
    {
        $Socket.Bind($LocalEndpoint)    
    }
    catch
    {
        Write-Host "[ERR] Server Listen Socket Bind Failure" -ForegroundColor Red
        Write-Host "[ERR] Port $LisPort has been used" -ForegroundColor Red
        Write-Host "[ERR] Please close this PowerShell instance and try again" -ForegroundColor Red
        Pause
        Exit
    }
    $Socket.Listen($Backlog)

    return $Socket
}

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
        [System.Net.Sockets.Socket]
        $SrvSocket,
        [Parameter(Mandatory = $true)]
        [System.Net.Sockets.Socket[]]
        $CltSocketArray
    )
    $SrvSocket.Close()
    foreach ($CltSocket in $CltSocketArray)
    {
        $CltSocket.Close()
    }
}

Clear-Host
"******************************** PowerShell Socket Test ********************************"
""
"Configuration"
"Server Listen At       : 0.0.0.0:$LisPort"
"Server Maximum Backlog : $BackLogMax"
"Client Maximum Number  : $CltMax"
""
"****************************************************************************************"
Pause

if (($LisPort -lt 1) -or ($LisPort -gt 65536))
{
    Write-Host "[ERR] Port Number Error" -ForegroundColor Red
    Pause
    Exit
}
while ($BackLogMax -gt 200)
{
    Write-Host "[WARNING] Backlog number larger than 200. Continue?" -ForegroundColor Yellow
    $YoN = Read-Host -Prompt "Y/N"
    if (($YoN -eq 'N') -or ($YoN -eq 'n'))
    {
        Exit
    }
    elseif (($YoN -eq 'Y') -or ($YoN -eq 'y'))
    {
        break
    }
}

$SrvLisSocket = ServerOn -BackLog $BackLogMax
$BackLogCnt = 0
"[SRV] Server Started: Listening at {0}" -f $SrvLisSocket.LocalEndPoint.ToString()
"[SRV] Backlog: {0}/{1}" -f $BackLogCnt, $BackLogMax

Pause

"[CLT] Starting Clients"
$CltSocketArray = @()

$RemotePort = $LisPort
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

$ErrCnt = 0
foreach ($CltSocket in $CltSocketArray)
{
    try
    {
        $CltSocket.Connect($RemoteEndpoint)
        ++$BackLogCnt
        "[SRV&CLT] Backlog & Socket Connect: {0}/{1}" -f $BackLogCnt, $BackLogMax
    }
    catch
    {
        ++$ErrCnt
        Write-Host "Connection Failed: " $_.Exception.Message -ForegroundColor Red
        if ($ErrCnt -gt 3)
        {
            Write-Host "[ERR] More than 3 failures. Exiting..." -ForegroundColor Red
            Pause
            CleanUp -SrvSocket $SrvLisSocket -CltSocketArray $CltSocketArray
            Write-Host "[INFO] Socket Clean Up Completed"
            Pause
            Exit
        }
    }
}

Pause

$SrvAccSocketArray = @()
$AccCnt = 0
for ($i = 0; $i -lt $CltMax; $i++)
{
    $SrvAccSocket = $SrvLisSocket.Accept()
    ++$AccCnt
    $SrvAccSocketArray += $SrvAccSocket
    "[SRV] Accepted Connection {0}/{1}" -f $AccCnt, $CltMax
}

Pause

foreach ($CltSocket in $CltSocketArray)
{
    try
    {     
        $CltSocket.Close()
        "[SRV&CLT] Backlog & Socket Closed: {0}/{1}" -f $BackLogCnt, $BackLogMax
        --$BackLogCnt
    }
    catch
    {
        Write-Host "[ERR] Close Failed: " + $_.Exception.Message -ForegroundColor Red
    }    
}

Pause

foreach ($SrvAccSocket in $SrvAccSocketArray)
{
    $SrvAccSocket.Close()
    "[SRV] Accept Socket Closed {0}/{1}" -f $AccCnt, $CltMax
    --$AccCnt
}

Pause

$SrvLisSocket.Close()
"[SRV] Listen Socket Closed"
""
Pause
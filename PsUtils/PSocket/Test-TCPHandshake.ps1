[CmdletBinding()]
param (
    [string]
    $RemoteIP = "127.0.0.1",
    [int]
    $RemotePort = 80,
    [string]
    $LocalIP,
    [int]
    $LocalPort = 0
)

$LocalIP = $LocalIP.Trim()
if ($LocalIP -eq [string]::Empty) {
    $LocalIP = '0.0.0.0'
}
if ($LocalIP -ne '0.0.0.0') {
    if ((Get-NetIPAddress).IPAddress -notcontains $LocalIP)
    {
        Write-Host "WARNING: $LocalIP is not a valid local IP address!" -ForegroundColor Yellow
    }
}

# Define Port and target IP address
$RemoteAddress = [System.Net.IPAddress]::Parse($RemoteIP) 
$LocalAddress = [System.Net.IPAddress]::Parse($LocalIP) 

# Create IP Endpoint 
$RemoteEndpoint = New-Object System.Net.IPEndPoint $RemoteAddress, $RemotePort
$LocalEndpoint = New-Object System.Net.IPEndPoint $LocalAddress, $LocalPort

# Create Socket 
$Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
$Stype = [System.Net.Sockets.SocketType]::Stream
$Ptype = [System.Net.Sockets.ProtocolType]::Tcp
$Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

# Bind
$Socket.Bind($LocalEndpoint)
if (!$Socket.IsBound) {
    "Socket.Bind() failed"
    $Socket.Close()
    exit
}
"Bound Socket on $($Socket.LocalEndPoint)" 

# Connect
"Attempt to connect"
$Socket.Connect($RemoteEndpoint)
if (!$Socket.Connected)
{
    "Socket.Connect() Failed"
    $Socket.Close()
    exit
}
"Connected to $($RemoteIP):$RemotePort"

$Socket.Disconnect($false)
$Socket.Close()
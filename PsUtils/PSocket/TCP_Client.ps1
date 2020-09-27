# Define Port and target IP address
$RemotePort = [int] 20000
# $LocalPort = [int] 0
$RemoteIP = "127.0.0.1"
# $LocalIP = [IPAddress]::Any
$RemoteAddress = [System.Net.IPAddress]::Parse($RemoteIP) 
# $LocalAddress = [System.Net.IPAddress]::Parse($LocalIP) 

# Create IP Endpoint 
$RemoteEndpoint = New-Object System.Net.IPEndPoint $RemoteAddress, $RemotePort
# $LocalEndpoint = New-Object System.Net.IPEndPoint $LocalAddress, $LocalPort

# Create Socket 
$Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
$Stype = [System.Net.Sockets.SocketType]::Stream
$Ptype = [System.Net.Sockets.ProtocolType]::Tcp
$Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

# Bind
# $Socket.Bind($LocalEndpoint)
# "Bound Socket on {0}" -f $Socket.LocalEndPoint

# Connect
$Socket.Connect($RemoteEndpoint)
if ($Socket.Connected -eq $false)
{
    "Connection Failed"
    $Socket.Close()
    Pause
    exit
}
"Connected to Server"

Pause

# Create encoded buffer
$Enc = [System.Text.Encoding]::ASCII 
$Message = "Create a Socket with PowerShell"
$Buffer = $Enc.GetBytes($Message) 

# Send the buffer
$Count = $Socket.Send($Buffer)
"Sent {0} bytes to: {1}:{2} " -f $Count, $RemoteIP, $RemotePort
"------------------------------------------------------------------"
"Message: " 
$Message

$Socket.Disconnect($false)
$Socket.Close()

Pause
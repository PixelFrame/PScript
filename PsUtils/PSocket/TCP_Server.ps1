# Define RemotePort and target IP address  
# $RemotePort = [int] 0
$LocalPort = [int] 20000
# $RemoteIP = "127.0.0.1"
$LocalIP = [IPAddress]::Any
# $RemoteAddress = [System.Net.IPAddress]::Parse($RemoteIP) 
$LocalAddress = [System.Net.IPAddress]::Parse($LocalIP)
$Backlog = [int] 65535

# Create IP Endpoint 
# $RemoteEndpoint = New-Object System.Net.IPEndPoint $RemoteAddress, $RemotePort
$LocalEndpoint = New-Object System.Net.IPEndPoint $LocalAddress, $LocalPort 

# Create Socket 
$Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
$Stype = [System.Net.Sockets.SocketType]::Stream
$Ptype = [System.Net.Sockets.ProtocolType]::Tcp
$Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

# Bind
$Socket.Bind($LocalEndpoint)
"Bound Socket on {0}:{1}" -f $LocalIP, $LocalPort

# Listen
$Socket.Listen($Backlog)
"Listening"
"Waiting for Message Now..."
$TransSocket = $Socket.Accept()

# Receive
$Count = 0
$Buffer = New-Object Byte[] 2048
$Count = $TransSocket.Receive($Buffer)
"Received {0} bytes from {1}" -f $Count, $TransSocket.RemoteEndPoint
"------------------------------------------------------------------"
"Message: "
[Text.Encoding]::ASCII.GetString($Buffer)

$TransSocket.Close()
$Socket.Close()
Pause
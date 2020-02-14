# Define RemotePort and target IP address  
$RemotePort = [int] 0
$LocalPort = [int] 20000
$RemoteIP = "127.0.0.1"
$LocalIP = [IPAddress]::Any
$RemoteAddress = [System.Net.IPAddress]::Parse($RemoteIP) 
$LocalAddress = [System.Net.IPAddress]::Parse($LocalIP) 

# Create IP Endpoint 
$RemoteEndpoint = New-Object System.Net.IPEndPoint $RemoteAddress, $RemotePort
$LocalEndpoint = New-Object System.Net.IPEndPoint $LocalAddress, $LocalPort 

# Create Socket 
$Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
$Stype = [System.Net.Sockets.SocketType]::Dgram 
$Ptype = [System.Net.Sockets.ProtocolType]::UDP 
$Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

# Bind
$Socket.Bind($LocalEndpoint)
"Bound Socket on {0}:{1}" -f $LocalIP, $LocalPort

# Receive 
$Count = 0
$Buffer = New-Object Byte[] 2048
while ($Count -eq 0) {
    "Waiting for Message Now..."
    $Count = $Socket.ReceiveFrom($Buffer, [ref]$RemoteEndpoint)
}
$Socket.Close()
"Received {0} bytes from {1}: {2}" -f $Count, $RemoteIP, $RemoteEndpoint.Port
"------------------------------------------------------------------"
"Message: "
[Text.Encoding]::ASCII.GetString($Buffer)

Pause
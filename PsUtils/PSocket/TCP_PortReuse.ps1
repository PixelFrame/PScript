[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateSet('Sender', 'Receiver')]
    $Role,

    [Parameter()]
    [int]
    $RemotePort = 10000,
    
    [Parameter()]
    [int]
    $LocalPort = 20000,

    [Parameter()]
    [string]
    $RemoteIP = "127.0.0.1"
)

try
{
    $TIME_WAIT = Get-ItemPropertyValue -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\ -Name TcpTimedWaitDelay    
}
catch
{
    $TIME_WAIT = 120
}

$LocalIP = [IPAddress]::Any
$RemoteAddress = [System.Net.IPAddress]::Parse($RemoteIP) 
$LocalAddress = [System.Net.IPAddress]::Parse($LocalIP)
$Backlog = [int] 200

# Create IP Endpoint 
$RemoteEndpoint = New-Object System.Net.IPEndPoint $RemoteAddress, $RemotePort
$LocalEndpoint = New-Object System.Net.IPEndPoint $LocalAddress, $LocalPort 

$Saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork 
$Stype = [System.Net.Sockets.SocketType]::Stream
$Ptype = [System.Net.Sockets.ProtocolType]::Tcp

if ($Role -eq 'Sender')
{
    while ($true)
    {
        if ([console]::KeyAvailable)
        {
            if ([System.Console]::ReadKey().KeyChar -in @('Q', 'q'))
            {
                break   
            }
        }
        else
        {
            # Create Socket 
            $Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

            # Bind
            $Socket.Bind($LocalEndpoint)
            "Bound Socket on {0}:{1}" -f $LocalIP, $LocalPort

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

            # Create encoded buffer
            $Enc = [System.Text.Encoding]::ASCII 
            $Message = "Create a Socket with PowerShell"
            $Buffer = $Enc.GetBytes($Message) 

            # Send the buffer
            $Count = $Socket.Send($Buffer)
            "Sent {0} bytes to: {1}:{2} " -f $Count, $RemoteIP, $RemotePort
            "Message: " 
            $Message
            "------------------------------------------------------------------"

            $Socket.Disconnect($false)
            $Socket.Close()

            Start-Sleep -Seconds $TIME_WAIT
        }
    }
    Pause
}
else
{
    # Create Socket 
    $Socket = New-Object System.Net.Sockets.Socket $Saddrf, $Stype, $Ptype

    # Bind
    $Socket.Bind($LocalEndpoint)
    "Bound Socket on {0}:{1}" -f $LocalIP, $LocalPort

    # Listen
    $Socket.Listen($Backlog)
    "Listening"
    "Waiting for Message Now..."

    while ($true)
    {
        if ([console]::KeyAvailable)
        {
            if ([System.Console]::ReadKey().KeyChar -in @('Q', 'q'))
            {
                break   
            }
        }
        else
        {
            $TransSocket = $Socket.Accept()

            # Receive
            $Count = 0
            $Buffer = New-Object Byte[] 2048
            $Count = $TransSocket.Receive($Buffer)
            "Received {0} bytes from {1}" -f $Count, $TransSocket.RemoteEndPoint
            "Message: "
            [Text.Encoding]::ASCII.GetString($Buffer)
            "------------------------------------------------------------------"
            
            $TransSocket.Close()
        }    
    }

    $Socket.Close()

    Pause
}
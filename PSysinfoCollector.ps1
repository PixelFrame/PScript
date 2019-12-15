New-Item -Path $Env:SystemDrive\NetLog -ItemType Directory

# Code Page change to 437
chcp 437

# Network Basic Info
$IpConfig = ipconfig.exe /all
$Adapters = Get-NetAdapter
$Interfaces = Get-NetIPInterface
$TCPConnections = Get-NetTCPConnection
$UDPEndpoints = Get-NetUDPEndpoint
$TCPSetting = Get-NetTCPSetting
$TransFilters = Get-NetTransportFilter

# Registries
$RegSrvTcpip = Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip"

# Event Logs
$Env:windir

# Set PublishAddresses to prevent DNS service from registring AnyCast address to SOA/NS
$listenAddrs = ((Get-DnsServerSetting).ListeningIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetwork' }).IPAddressToString -join ' ' # IPv4 Only
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\DNS\Parameter -Name PublishAddresses -Value $listenAddrs -Force

$primary_interface = (Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and !$_.Virtual}).Name
$loopback_ipv4 = '10.10.10.10'
$loopback_ipv4_length = '32'
$loopback_name = 'Loopback'
Install-Module -Name LoopbackAdapter -MinimumVersion 1.2.0.0 -Force
Import-Module -Name LoopbackAdapter
New-LoopbackAdapter -Name $loopback_name -Force
$interface_loopback = Get-NetAdapter -Name $loopback_name
$interface_main = Get-NetAdapter -Name $primary_interface
# Since the receiving adapter(primary interface) and the sending adapter(loopback adapter) are different, we need to enable WeakHostReceive/Send 
Set-NetIPInterface -InterfaceIndex $interface_loopback.ifIndex -InterfaceMetric "254" -WeakHostReceive Enabled -WeakHostSend Enabled -Dhcp Disabled
Set-NetIPInterface -InterfaceIndex $interface_main.ifIndex -WeakHostReceive Enabled -WeakHostSend Enabled
# Avoid other process use the loopback adapter
Set-NetIPAddress -InterfaceIndex $interface_loopback.ifIndex -SkipAsSource $True
# Disable DNS registration, but this is actually not working as DNS service is listening on this address
# So we need to set PublishAddresses registry
Get-NetAdapter $loopback_name | Set-DNSClient -RegisterThisConnectionsAddress $False
# Set IP address to adapter
New-NetIPAddress -InterfaceAlias $loopback_name -IPAddress $loopback_ipv4 -PrefixLength $loopback_ipv4_length -AddressFamily ipv4
# Remove unnecessary bindings
Disable-NetAdapterBinding -Name $loopback_name -ComponentID ms_msclient
Disable-NetAdapterBinding -Name $loopback_name -ComponentID ms_pacer
Disable-NetAdapterBinding -Name $loopback_name -ComponentID ms_server
Disable-NetAdapterBinding -Name $loopback_name -ComponentID ms_lltdio
Disable-NetAdapterBinding -Name $loopback_name -ComponentID ms_rspndr
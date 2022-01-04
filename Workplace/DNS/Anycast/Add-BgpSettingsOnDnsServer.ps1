$pNICName = 'Ethernet'
$pNICAddress = Get-NetIPAddress -InterfaceAlias $pNICName -AddressFamily IPv4
$gwAddress = 10.1.1.254
$localASN = 65531
$gwASN = 65530

Install-WindowsFeature RemoteAccess -IncludeManagementTools
Install-RemoteAccess -VpnType RoutingOnly
Add-BgpRouter -BgpIdentifier $pNICAddress.IPAddress -LocalASN $localASN
Add-BgpPeer -Name "VIRT-VGW" -LocalIPAddress $pNICAddress.IPAddress -PeerIPAddress $gwAddress -PeerASN $gwASN –LocalASN $localASN
Add-BgpCustomRoute -Network 10.10.10.10/32
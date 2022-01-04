$DnsServers = @(
	[PSCustomObject]@{Name='VIRT-PDC'; Addr='10.1.1.1'}, 
	[PSCustomObject]@{Name='VIRT-DC1'; Addr='10.1.1.50'}
	[PSCustomObject]@{Name='VIRT-DC2'; Addr='10.1.1.100'}
)
$pNICName = 'Ethernet'
$pNICAddress = Get-NetIPAddress -InterfaceAlias $pNICName -AddressFamily IPv4
$localASN = 65530
$dnsSrvASN = 65531

Add-BgpRouter -BgpIdentifier $pNICAddress.IPAddress -LocalASN $localASN
$DnsServers| % {
	Add-BgpPeer -Name $_.Name -LocalIPAddress $pNICAddress.IPAddress -PeerIPAddress $_.Addr -PeerASN $dnsSrvASN –LocalASN $localASN
}
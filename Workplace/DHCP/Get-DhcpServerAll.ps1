mkdir C:\DHCPServer\
Export-DhcpServer -File C:\DHCPServer\Server.xml -Leases
Get-DhcpServerv4Failover | Format-List * > C:\DHCPServer\Failover.txt

Get-DhcpServerv4Scope | Format-Table -AutoSize                                      > C:\DHCPServer\Scopesv4.txt
Get-DhcpServerv4Scope | Get-DhcpServerv4Lease -AllLeases | Format-Table -AutoSize   > C:\DHCPServer\Leasesv4.txt
Get-DhcpServerv4Binding | Format-List *                                             > C:\DHCPServer\Bindingv4.txt

mkdir C:\DHCPServer\Audit
$AuditLogs = Get-ChildItem -Path ((Get-DhcpServerAuditLog).Path + '\Dhcp*.log') 
Copy-Item -Path $AuditLogs -Destination C:\DHCPServer\Audit -Force

mkdir C:\DHCPServer\Event
$EventLogs = Get-ChildItem -Path ($Env:SystemRoot + '\System32\winevt\Logs\*') -Include ('DhcpAdmin*', '*Dhcp-Server*')
Copy-Item -Path $EventLogs -Destination C:\DHCPServer\Event -Force


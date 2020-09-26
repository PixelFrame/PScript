mkdir C:\NetTrace
netsh trace start capture=yes PacketTruncateBytes=80 maxsize=2000M tracefile=D:\PacketCapture.etl overwrite=yes
Logman create counter Perf-1Second -f bincirc -max 512 -c "\LogicalDisk(*)\*" "\Memory\*" "\Network Interface(*)\*" "\Paging File(*)\*" "\PhysicalDisk(*)\*" "\System\*" "\Process(*)\*" "\Processor(*)\*" "\Cache\*" -si 00:00:01 -o C:\NetTrace\Perf-1Second.blg
Logman start Perf-1second

netsh interface tcp show global > C:\NetTrace\tcpglobal.txt
netsh interface ipv4 show global > C:\NetTrace\ipv4global.txt
Get-NetAdapter | Format-List * > C:\NetTrace\Adapters.txt
Get-NetAdapterAdvancedProperty | Format-List * > C:\NetTrace\AdapterAdv.txt
Get-NetAdapterChecksumOffload > C:\NetTrace\AdapterOffload.txt
Get-NetAdapterRss > C:\NetTrace\AdapterRss.txt
Get-NetTCPSetting > C:\NetTrace\TCPSetting.txt
Get-NetTransportFilter > C:\NetTrace\TransFilter.txt
Get-NetIPConfiguration > C:\NetTrace\IPConfig.txt
reg export HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip\Parameters C:\NetTrace\tcp.reg

netsh trace stop
Logman stop Perf-1second
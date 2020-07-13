## Packet Monitor Examples
## Tested with version 10.0.20161.1000

## Capture

# Single file in circular mode
PktMon.exe start -c -f $Env:SystemDrive\PktCap\NetTracePM.etl -m circular -s 2048

# Multiple files
pktmon.exe start -c -f $Env:SystemDrive\PktCap\NetTracePMChn.etl -m multi-file -s 1024

# High Performance
#! Using memory for capture buffer
pktmon.exe start -c -f $Env:SystemDrive\PktMonCap\NetTracePM.etl -m memory -s 1024

# Packet capture with TCP/IP providers
PktMon.exe start -c -t `
    -p '{eb004a05-9b1a-11d4-9123-0050047759bc}' -k 0x3ffff -l 0xff `
    -p '{e53c6823-7bb8-44bb-90dc-3f86090d48a6}' -k 0x800000000000003f  -l 0xff `
    -p '{2f07e2ee-15db-40f1-90ef-9d7ba282188a}' -k 0x80007fff000000ff  -l 0xff `
    -f $Env:SystemDrive\NetTrace_w_TCPIP.etl -s 2048

# Verbose
PktMon.exe start -c `
    --flags 0x31 `
    -t `
    -p '{eb004a05-9b1a-11d4-9123-0050047759bc}' -k 0x3ffff -l 0xff `
    -p '{e53c6823-7bb8-44bb-90dc-3f86090d48a6}' -k 0x800000000000003f  -l 0xff `
    -p '{2f07e2ee-15db-40f1-90ef-9d7ba282188a}' -k 0x80007fff000000ff  -l 0xff `
    -f $Env:SystemDrive\NetTrace_w_TCPIP_verbose.etl -s 2048

# Counter Only. No capture file will be generated.
PktMon.exe start -o

## Filter

# Ping
PktMon.exe filter add Ping -i 10.1.1.1 -t ICMP

# ARP
PktMon.exe filter add ARP -i 10.1.1.1 -d ARP

# TCP Flag
PktMon.exe filter add TcpFlag -i 10.1.1.1 -t TCP SYN

# TCP Port
PktMon.exe filter add TcpFlag -i 10.1.1.1 -t TCP -p 445

# Subnet
PktMon.exe filter add Subnet -i 10.1.1.0/24

# MAC and VLAN
PktMon.exe filter add Ethernet -m 00-15-5D-1F-38-00 -v 1

# Failover Cluster Heartbeat
PktMon.exe filter add Heartbeat -b

## Convert

# Statistic, Timestamp, Metadata
.\PktMon.exe etl2txt $Env:SystemDrive\NetTrace_w_TCPIP.etl -s -t -m

# TMF
.\PktMon.exe etl2txt $Env:SystemDrive\NetTrace_w_TCPIP.etl -p $Env:SystemDrive\Users\Public\TMF -v 3

# pcapng
PktMon.exe etl2pcap .\PktCap.etl -o .\PktCap.pcapng
PktMon.exe etl2pcap .\PktCap.etl -o .\PktCap-Dropped.pcapng -d

# Decode Hex
.\PktMon.exe hex2pkt -t Ethernet 00155D1F380100155D1F380208004500003C6AB20000800100000A0001330A00010108004D5A000100016162636465666768696A6B6C6D6E6F7071727374757677616263646566676869

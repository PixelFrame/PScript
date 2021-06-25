$RRs = Get-DnsServerResourceRecord -ZoneName 'RXLAB.NET' -RRType A
foreach ($RR in $RRs)
{
    $RRAddr = $RR.RecordData.IPv4Address.IPAddressToString
    if ($RRAddr -like "192.168.10.*" -and $RR.Hostname -ne '@' -and $RR.Hostname -ne 'DomainDnsZones' -and $RR.Hostname -ne 'ForestDnsZones')
    {
        $PTRHostName = $RRAddr.Split('.')[3]
        $PTRDomainName = $RR.HostName + '.RXLAB.NET.'
        Add-DnsServerResourceRecordPtr -Name $PTRHostName -ZoneName '10.168.192.in-addr.arpa' -PtrDomainName $PTRDomainName -AgeRecord
        
    }
}
Out-File -FilePath 'C:\ExportedDns.csv' -Force -InputObject '"HostName","Zone","RecordType","RecordData","Timestamp","TimeToLive"' -Encoding ascii
$Zones = Get-DnsServerZone
foreach ($Zone in $Zones)
{
    $RRs = $Zone | Get-DnsServerResourceRecord -RRType A
    foreach ($RR in $RRs)
    {
        $Line = '"' + $RR.Hostname + '"' + ',' + '"' + $Zone.ZoneName + '"' + ',' + '"' + $RR.RecordType + '"' + ',' + '"' + $RR.RecordData.IPv4Address.ToString() + '"' + ',' + '"' + $RR.Timestamp + '"' + ',' + '"' + $RR.TimeToLive + '"'
        Out-File -FilePath 'C:\ExportedDns.csv' -Append -InputObject $Line -Encoding ascii
    }    
}

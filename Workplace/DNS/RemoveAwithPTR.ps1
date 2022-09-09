[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string] $HostName,
    [Parameter(Mandatory = $true)][string] $ZoneName
)

function FindPtrInAllReverseLookupZones
{
    # Note: This function will not find PTR record as a zone (e.g. 1.1.168.192.in-addr.arpa as a zone)
    param (
        [string] $IPv4Addr,
        [string] $Fqdn
    )
    
    $IPv4AddrOcts = $IPAddress.Split('.')
    $RRList = @()
    $ReverseZoneName = "in-addr.arpa"
    for ($i = 0; $i -lt 3; $i++)
    {
        $ReverseZoneName = $IPv4AddrOcts[$i] + '.' + $ReverseZoneName
        try
        { 
            Get-DnsServerZone $ReverseZoneName -ErrorAction Stop | Out-Null
            Write-Verbose "Zone $ReverseZoneName Found!"
            try
            {
                $RRName = $IPv4AddrOcts[3]
                $j = 2
                while ($j -gt $i)
                {
                    $RRName += ".$($IPv4AddrOcts[$j])"
                    $j--
                }
                $RR = Get-DnsServerResourceRecord -Name $RRName -RRType Ptr -ZoneName $ReverseZoneName -ErrorAction Stop
                if ($RR.RecordData.PtrDomainName -ne $Fqdn)
                {
                    Write-Verbose "Data of record $RRName does not match $Fqdn... Skipping"
                    continue
                }
                $RRList += [PSCustomObject]@{
                    Record = $RR;
                    Zone   = $ReverseZoneName;
                }
                Write-Verbose "Record $RRName Found in $ReverseZoneName!"
            }
            catch
            {
                Write-Verbose "Record $RRName Not Found in $ReverseZoneName!"
            }
        }
        catch
        {
            Write-Verbose "Zone $ReverseZoneName Not Found!"
        }
    }
    return $RRList
}

try
{
    $RR_A = Get-DnsServerResourceRecord -Name $HostName -ZoneName $ZoneName -RRType A -ErrorAction Stop
    Write-Verbose "Record $HostName Found in $ZoneName!"
}
catch
{
    Write-Host "A Record Not Found!" -ForegroundColor Red
    exit
}
$IPAddress = $RR_A.RecordData.IPv4Address.IPAddressToString
$RR_PTR = FindPtrInAllReverseLookupZones -IPv4Addr $IPAddress -Fqdn "$HostName.$ZoneName."

Write-Host "Records to be removed:"
$RR_A
$RR_PTR.Record

$confirm = Read-Host -Prompt "Confirm Deletion? Y/N"
if (@('y', 'Y') -contains $confirm) 
{
    $RR_A | Remove-DnsServerResourceRecord -ZoneName $ZoneName -Force
    $RR_PTR | ForEach-Object { 
        try { Remove-DnsServerResourceRecord -Name $_.Record.HostName -ZoneName $_.Zone -RRType Ptr -Force -ErrorAction SilentlyContinue }
        catch {}
        # Removing A record may automatically remove PTR if update associated PTR is selected, so here catch any exception to avoid showing error
    }
}
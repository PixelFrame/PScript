# Get-ADDnsObject -Filter 'Name -eq "@"' -SearchBase 'DC=vlab.local,CN=MicrosoftDNS,DC=DomainDnsZones,DC=vlab,DC=local'

param (
    [Parameter(Mandatory = $true)]
    [String]
    $Filter,

    [Parameter(Mandatory = $true)]
    [String]
    $SearchBase,

    [Parameter()]
    [int]
    $Style = 0
)

$AdObj = Get-ADObject -Filter $Filter -SearchBase $SearchBase -Properties * 
$DnsRecord = $AdObj.dnsRecord
$cnt = 0
Foreach ($record in $DnsRecord) {
    
    $Output = [BitConverter]::ToString($record)
    switch ($Style) {
        1 { 
            $Output = $Output.Replace('-', '\')
            $Output = '\' + $Output
        }
        2 {
            $Output = $Output.Replace('-', ' ')
        }
        Default { }
    }
    $Output = '[' + $cnt + ']: ' + $Output
    
    ++$cnt
    Write-Host $Output
}
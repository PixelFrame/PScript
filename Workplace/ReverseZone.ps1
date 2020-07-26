[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Beginning,

    [Parameter()]
    [string]
    $Ending,

    [Parameter()]
    [string]
    $DnsSrv
)

Import-Module -Name ..\PsUtils\IPConverter.psm1

$BeginningNum = Convert-IPv4ToUInt32 $Beginning
$EndingNum = Convert-IPv4ToUInt32 $Ending

for ($Ipv4Addr = $BeginningNum; $Ipv4Addr -lt $EndingNum; $Ipv4Addr++)
{
    $Name = Convert-UInt32ToIPv4 -Num $Ipv4Addr
    "Now querying $Name"
    Resolve-DnsName -Server $DnsSrv -Name $Name -Type PTR -QuickTimeout -DnsOnly
}

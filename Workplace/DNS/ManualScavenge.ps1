[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string] $ZoneName,
    [Parameter(Mandatory = $true)][string] $TimeBefore,
    [Parameter()][string] $ZoneScope,
    [Parameter()][string] $RRType = "A",
    [Parameter()][string] $ComputerName = "localhost",
    [switch] $ConfirmEveryRecord
)

if ($ZoneScope -eq "")
{
    $ZoneScope = $ZoneName
}
$Records = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType $RRType -ComputerName $ComputerName -ZoneScope $ZoneScope | Where-Object {
    ($_.Timestamp -lt (Get-Date $TimeBefore)) -and 
    ($_.Timestamp -ne $null)
}
"RECORDS TO BE REMOVED"
"=================================================================="
$Records
"=================================================================="
if ($ConfirmEveryRecord)
{
    $Records | Remove-DnsServerResourceRecord -ZoneName $ZoneName -ZoneScope $ZoneScope -Confirm:$ConfirmEveryRecord -ComputerName $ComputerName
}
else
{
    $Continue = Read-Host -Prompt "Continue? Y/N "
    if ($Continue -in @('y', 'Y') )
    {
        $Records | Remove-DnsServerResourceRecord -ZoneName $ZoneName -ZoneScope $ZoneScope -Force -ComputerName $ComputerName
    }
}


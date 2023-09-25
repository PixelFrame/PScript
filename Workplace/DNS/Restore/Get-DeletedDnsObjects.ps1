#requires -Module ActiveDirectory

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ZoneName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Domain', 'Forest', 'System')]
    [string]
    $Partition,

    [string]
    $DomainName
)

if ($DomainName.Length -eq 0)
{
    Write-Verbose 'DomainName not specified, using ZoneName as DomainName'
    $DomainName = $ZoneName
}
$DomainName.Split('.') | ForEach-Object { $SearchBase += "DC=$($_)," }
$SearchBase = $SearchBase.Remove($SearchBase.Length - 1)

switch ($Partition)
{
    'Domain' { $SearchBase = 'DC=DomainDnsZones,' + $SearchBase }
    'Forest' { $SearchBase = 'DC=ForestDnsZones,' + $SearchBase }
    Default {}
}
Write-Debug "SearchBase: $SearchBase"

$LdapFilter = '(&(isDeleted=TRUE)(ObjectClass=dnsZone)(msds-lastKnownRdn=..Deleted-{0}))' -f $ZoneName
Write-Debug "Filter: $LdapFilter"
$ZoneObj = Get-ADObject `
    -LDAPFilter $LdapFilter `
    -IncludeDeletedObjects `
    -SearchBase $SearchBase `
    -Property DistinguishedName, msDS-LastKnownRDN, LastKnownParent, Name, ObjectClass, ObjectGUID, whenChanged, whenCreated

if ($null -eq $ZoneObj)
{
    $errMsg = 
    "dnsZone object not found with LDAP filter
$LdapFilter
in SearchBase
$SearchBase"
    throw (New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException $errMsg)
}

$ZoneDnEscaped = $ZoneObj.DistinguishedName.Replace('\0A', '\\0A')
$LdapFilter = '(&(isDeleted=TRUE)(ObjectClass=dnsNode)(LastKnownParent={0}))' -f $ZoneDnEscaped
Write-Debug "Filter: $LdapFilter"
$RecordObj = Get-ADObject `
    -LDAPFilter $LdapFilter `
    -IncludeDeletedObjects `
    -SearchBase $SearchBase `
    -Property DistinguishedName, msDS-LastKnownRDN, LastKnownParent, Name, ObjectClass, ObjectGUID, whenChanged, whenCreated

if ($null -eq $RecordObj)
{
    Write-Output "Warning: No records found in the zone $([System.Environment]::NewLine)"
}

Write-Output -InputObject $ZoneObj
Write-Output -InputObject $RecordObj
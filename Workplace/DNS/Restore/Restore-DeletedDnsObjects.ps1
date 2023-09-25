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
    $DomainName,

    [switch]
    $Force
)

if ($DomainName.Length -eq 0)
{
    Write-Host 'DomainName not specified, using ZoneName as DomainName' -ForegroundColor Yellow
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
    -Property *

if ($null -eq $ZoneObj)
{
    $errMsg = 
    "dnsZone object not found with LDAP filter
$LdapFilter
in SearchBase
$SearchBase"
    throw (New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException $errMsg)
}

if (!$Force)
{
    Write-Host "Do you confirm to restore AD object $($ZoneObj.DistinguishedName)?" -ForegroundColor Blue
    $confirm = Read-Host 'y/N'
    if ($confirm -notin @('y', 'Y'))
    {
        Write-Host 'Zone restore cancelled!' -ForegroundColor Yellow
        exit
    }
}

Write-Host "Restoring $($ZoneObj.DistinguishedName)" -ForegroundColor Green
$ZoneObj | Restore-ADObject -ErrorAction Stop

$LdapFilter = '(&(ObjectClass=dnsZone)(Name=..Deleted-{0}))' -f $ZoneName
Write-Debug "Filter: $LdapFilter"
$RestoredZoneObj = Get-ADObject `
    -LDAPFilter $LdapFilter `
    -SearchBase $SearchBase `
    -Property *
    
if ($null -eq $RestoredZoneObj)
{
    $errMsg = 'Restore command executed but cannot find the restored object'
    throw (New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryOperationException $errMsg)
}
Write-Host "Restored $($ZoneObj.DistinguishedName) to $($RestoredZoneObj.DistinguishedName)" -ForegroundColor Green

$LdapFilter = '(&(isDeleted=TRUE)(ObjectClass=dnsNode)(LastKnownParent={0}))' -f $RestoredZoneObj.DistinguishedName
Write-Debug "Filter: $LdapFilter"
$RecordObj = Get-ADObject `
    -LDAPFilter $LdapFilter `
    -IncludeDeletedObjects `
    -SearchBase $SearchBase `
    -Property DistinguishedName, msDS-LastKnownRDN, LastKnownParent, Name, ObjectClass, ObjectGUID, whenChanged, whenCreated

if ($null -eq $RecordObj)
{
    Write-Host 'No records found in zone!' -ForegroundColor Yellow
}
else
{
    if (!$Force)
    {
        Write-Host 'Do you confirm to restore the following AD objects?' -ForegroundColor Blue
        Write-Host '-----------------------------------------------------------------------------------------' -ForegroundColor Blue
        $RecordObj.DistinguishedName
        Write-Host '-----------------------------------------------------------------------------------------' -ForegroundColor Blue
        $confirm = Read-Host 'y/N'
        if ($confirm -notin @('y', 'Y'))
        {
            Write-Host 'Record restore cancelled!' -ForegroundColor Yellow
            exit
        }
    }

    foreach ($record in $RecordObj)
    {
        Write-Host "Restoring $($record.DistinguishedName)" -ForegroundColor Green
        $record | Restore-ADObject -ErrorAction Inquire
        Write-Host "Restored $($record.DistinguishedName)" -ForegroundColor Green
    }
}

Write-Host 'Renaming zone object to original name' -ForegroundColor Green
Rename-ADObject -Identity $RestoredZoneObj -NewName $ZoneName
Write-Host 'Renamed zone object to original name' -ForegroundColor Green

Write-Host 'Operations completed! Restart DNS service and see if zone is back!' -ForegroundColor Green
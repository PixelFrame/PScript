[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Domain,

    [string]
    $Namespace = '*'
)

if (Test-Path $PSScriptRoot\pKTClass.ps1)
{
    . $PSScriptRoot\pKTClass.ps1
}
else
{
    throw 'Cannot find pKTClass.ps1!'
}

if ($Namespace -eq '*')
{
    $DN = "CN=Dfs-Configuration,CN=System"
}
else
{
    $DN = "CN=$Namespace,CN=Dfs-Configuration,CN=System"
}
$DomainSplits = $Domain.Split('.')
foreach ($DomainSplit in $DomainSplits)
{
    $DN += ",DC=$DomainSplit"
}

Write-Host "Search DN: $DN"
$ObjNamespaces = Get-ADObject -Filter 'ObjectClass -eq "fTDfs"' -SearchBase $DN -SearchScope Subtree -Properties *

$pKTArr = @()
foreach ($ObjNamespace in $ObjNamespaces)
{
    $pKTObj = [pKT]::new($ObjNamespace.pKT)
    $pKTArr += $pKTObj
}

return $pKTArr
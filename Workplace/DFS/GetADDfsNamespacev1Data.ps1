[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Domain,

    [string]
    $Namespace = '*'
)

if (Test-Path $PSScriptRoot\PKT.ps1)
{
    . $PSScriptRoot\PKT.ps1
}
else
{
    throw 'Cannot find PKT.ps1!'
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

$PKTArr = @()
foreach ($ObjNamespace in $ObjNamespaces)
{
    $PKTObj = [PKT]::new($ObjNamespace.pKT)
    $PKTObj.PrintTree()
    $PKTArr += $PKTObj
}

return $PKTArr
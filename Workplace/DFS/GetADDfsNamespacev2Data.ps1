[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Domain,

    [string]
    $Namespace = '*',

    [string]
    $TargetDC
)

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

if ($TargetDC -eq '')
{
    $TargetDC = (Get-ADDomainController).HostName
}

"Search DN: $DN"
$ObjNamespaces = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Namespacev2"' -SearchBase $DN -SearchScope Subtree -Properties * -Server $TargetDC
$Links = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Linkv2"' -SearchBase $DN -SearchScope Subtree -Properties * -Server $TargetDC

$ArrNamespace = @()
foreach ($ObjNamespace in $ObjNamespaces)
{
    $Targets = [System.Text.Encoding]::Unicode.GetString($ObjNamespace.'msDFS-TargetListv2')
    $ArrNamespace += [PSCustomObject] @{
        CN      = $ObjNamespace.cn
        Prop    = $ObjNamespace.'msDFS-Propertiesv2';
        Targets = $Targets;
        TTL     = $ObjNamespace.'msDFS-Ttlv2';
    }
}

$ArrLink = @()
foreach ($Link in $Links)
{
    $Namespace = $Link.DistinguishedName.Split(',')[1].Substring(3)
    $Path = $Namespace + $Link.'msDFS-LinkPathv2'
    $Targets = [System.Text.Encoding]::Unicode.GetString($Link.'msDFS-TargetListv2')
    $ArrLink += [PSCustomObject] @{
        CN      = $Link.cn;
        Path    = $Path;
        Prop    = $Link.'msDFS-Propertiesv2';
        Targets = $Targets;
        TTL     = $Link.'msDFS-Ttlv2'
    }
}

$ArrNamespace | Out-GridView -Title 'DFS Namespaces'
$ArrLink | Out-GridView -Title 'DFS Folder Targets'
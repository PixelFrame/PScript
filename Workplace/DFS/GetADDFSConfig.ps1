$Namespaces = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Namespacev2"' -SearchBase 'CN=Dfs-Configuration,CN=System,DC=shlth,DC=vlab' -SearchScope Subtree -Properties *
$Links = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Linkv2"' -SearchBase 'CN=Dfs-Configuration,CN=System,DC=shlth,DC=vlab' -SearchScope Subtree -Properties *

$ArrNamespace = @()
foreach ($Namespace in $Namespaces)
{
    $Targets = [System.Text.Encoding]::Unicode.GetString($Namespace.'msDFS-TargetListv2')
    $ArrNamespace += [PSCustomObject] @{
        CN      = $Namespace.cn
        Prop    = $Namespace.'msDFS-Propertiesv2';
        Targets = $Targets;
        TTL     = $Namespace.'msDFS-Ttlv2'
    }
}

$ArrLink = @()
foreach ($Link in $Links)
{
    $Namespace = $Link.DistinguishedName.Split(',')[1].Substring(3)
    $Path = $Namespace + $Link.'msDFS-LinkPathv2'
    $Targets = [System.Text.Encoding]::Unicode.GetString($Link.'msDFS-TargetListv2')
    $ArrLink += [PSCustomObject] @{
        Path    = $Path;
        Prop    = $Link.'msDFS-Propertiesv2';
        Targets = $Targets;
        TTL     = $Link.'msDFS-Ttlv2'
    }
}

$ArrNamespace | Format-List
$ArrLink | Format-List
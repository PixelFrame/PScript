$Namespaces = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Namespacev2"' -SearchBase 'CN=Dfs-Configuration,CN=System,DC=shlth,DC=vlab' -SearchScope Subtree -Properties *
$Links = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Linkv2"' -SearchBase 'CN=Dfs-Configuration,CN=System,DC=shlth,DC=vlab' -SearchScope Subtree -Properties *

foreach ($Namespace in $Namespaces)
{
    $CN = $Namespace.cn
    $Prop = $Namespace.'msDFS-Propertiesv2'
    $Targets = [System.Text.Encoding]::Unicode.GetString($Namespace.'msDFS-TargetListv2')
    [PSCustomObject] @{
        CN      = $CN;
        Prop    = $Prop;
        Targets = $Targets
    }
}

foreach ($Link in $Links)
{
    $Namespace = $Link.DistinguishedName.Split(',')[1].Substring(3)
    $Path = $Namespace + $Link.'msDFS-LinkPathv2'
    $Targets = [System.Text.Encoding]::Unicode.GetString($Link.'msDFS-TargetListv2')
    [PSCustomObject] @{
        Path    = $Path;
        Targets = $Targets
    }
}
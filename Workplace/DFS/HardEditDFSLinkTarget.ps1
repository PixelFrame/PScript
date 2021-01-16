# ToDo: Namespace v1 Support

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Domain,

    [Parameter(Mandatory = $true)]
    [string]
    $Namespace
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

$ObjNamespace = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Namespacev2"' -SearchBase $DN -SearchScope Subtree -Properties * -ErrorAction Stop

[PSCustomObject] @{
    CN      = $ObjNamespace.cn
    Prop    = $ObjNamespace.'msDFS-Propertiesv2';
    Targets = [System.Text.Encoding]::Unicode.GetString($ObjNamespace.'msDFS-TargetListv2');
    TTL     = $ObjNamespace.'msDFS-Ttlv2'
} | Out-GridView

Pause

$DeadServer = Read-Host -Prompt 'Input the server name you want to disable '

$ADSIComObj = [ADSI]"LDAP://$($ObjNamespace.DistinguishedName)"
$ByteTargetList = $ADSIComObj.InvokeGet('msDFS-TargetListv2')
$StrTargetList = [System.Text.Encoding]::Unicode.GetString($ByteTargetList)
$NewStrTargetList = [Regex]::Replace($StrTargetList, "(online)(.*(?:$DeadServer))", 'offline$2')
$NewByteTargetList = [System.Text.Encoding]::Unicode.GetBytes($NewStrTargetList)
$ByteTargetList = $ADSIComObj.InvokeSet('msDFS-TargetListv2', $NewByteTargetList)

"The Target List for "

$ADSIComObj.CommitChanges()

$NewObjNamespace = Get-ADObject -Filter 'ObjectClass -eq "msDFS-Namespacev2"' -SearchBase $DN -SearchScope Subtree -Properties * -ErrorAction Stop
[PSCustomObject] @{
    CN      = $NewObjNamespace.cn
    Prop    = $NewObjNamespace.'msDFS-Propertiesv2';
    Targets = [System.Text.Encoding]::Unicode.GetString($NewObjNamespace.'msDFS-TargetListv2');
    TTL     = $NewObjNamespace.'msDFS-Ttlv2'
} | Out-GridView
Clear-Variable RegPaths -ErrorAction SilentlyContinue

[string[]] $RegPaths += "HKLM:\SYSTEM"

foreach ($RegPath in $RegPaths)
{
    $ACL = Get-Acl -Path $RegPath
    $SDDL = $ACL.Sddl + '(A;CIID;KR;;;S-1-15-3-1024-1065365936-1281604716-3511738428-1654721687-432734479-3232135806-4053264122-3456934681)'
    $ACL.SetSecurityDescriptorSddlForm($SDDL)
    Set-Acl -Path $RegPath -AclObject $ACL
}

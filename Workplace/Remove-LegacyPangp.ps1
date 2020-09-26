$Interface = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\NetworkSetup2\Interfaces\*\Kernel'
foreach ($if in $Interface)
{
    if ($if.GetValue('IfAlias') -like '*PANGP*')
    {
        Remove-Item $if.PSParentPath -Recurse
    }
}

if ((Get-WmiObject Win32_OperatingSystem).Name -like '*Server*')
{
    $Class = 'VLAB SERVER'
}
else
{
    $Class = 'VLAB WORKSTATION'
}

Get-NetAdapter | Where-Object { $_.MediaType -eq '802.3' -and $_.InterfaceAlias -notlike '*loopback*' } | ForEach-Object {
    ipconfig /setclassid $_.InterfaceAlias $Class
}
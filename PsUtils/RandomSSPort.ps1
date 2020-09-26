$SSconfig = Get-Content -Path /etc/shadowsocks.json | ConvertFrom-Json
$NewPort = Get-Random -Maximum 65535 -Minimum 1024
while ($SSconfig.server_port -eq $NewPort)
{
    $NewPort = Get-Random -Maximum 65535 -Minimum 1024
}
$SSconfig.server_port = $NewPort
$SSconfig | ConvertTo-Json | Out-File -FilePath /etc/shadowsocks.json -Force
/etc/init.d/shadowsocks restart
"SS Server Port has been changed to $NewPort"
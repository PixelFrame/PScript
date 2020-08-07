$Hosts = Get-Content -Path $env:SystemRoot\System32\drivers\etc\hosts
$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain

if (!($Hosts -contains '255.255.255.255 wpad'))
{
    $Hosts += '255.255.255.255 wpad'
}

if (!($Hosts -contains "255.255.255.255 wpad.$DomainName"))
{
    $Hosts += "255.255.255.255 wpad.$DomainName"
}

$Hosts | Out-File -FilePath $env:SystemRoot\System32\drivers\etc\hosts -Encoding ascii
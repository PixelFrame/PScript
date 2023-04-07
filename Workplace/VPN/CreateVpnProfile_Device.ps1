#requires -modules ProfileXMLBuilder.PS

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $VPNServer,

    [Parameter(Mandatory = $true)]
    [string]
    $DomainName,

    [Parameter(Mandatory = $true)]
    [string[]]
    $DCAddrs,

    [Parameter()]
    [string]
    $OutFile = '.\Profile-Device.XML'
)

$rt = @() 
foreach ($dc in $DCAddrs)
{
    $rt += New-ProfileXMLRoute -Address $dc -Prefix 32
}
$auth = New-ProfileXMLAuthentication -MachineAuth -ComputerMethod MachineCert

$builder = New-ProfileXMLBuilder -Servers $VPNServer `
    -DnsSuffix $DomainName `
    -TrustedNetworkDetection $DomainName `
    -RoutingPolicy SplitTunnel `
    -Authentication $auth `
    -NativeProtocol IKEv2 `
    -DeviceTunnel `
    -DisableClassBasedDefaultRoutes `
    -Routes $rt

$builder | Get-ProfileXML | Tee-Object -FilePath $OutFile
Pause
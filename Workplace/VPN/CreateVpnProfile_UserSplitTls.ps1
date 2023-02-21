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
    [string]
    $NPSServer,

    [Parameter(Mandatory = $true)]
    [string]
    $RootCA,

    [Parameter(Mandatory = $true)]
    [string]
    $DNSServer,

    [Parameter(Mandatory = $true)]
    [string[]]
    $DomainSubnets,

    [switch]
    $PEAP,

    [Parameter()]
    [string]
    $OutFile = '.\Profile.XML'
)

$rt = @() 
foreach ($net in $DomainSubnets)
{
    $rt += New-ProfileXMLRoute -Address $net.Split('/')[0] -Prefix $net.Split('/')[1]
}
$dni0 = New-ProfileXMLDomainNameInformation -DomainName $DomainName -DnsServers $DNSServer
$dni1 = New-ProfileXMLDomainNameInformation -DomainName ".$DomainName" -DnsServers $DNSServer
$authmethod = if ($PEAP) { 'UserPeapTls' } else { 'UserEapTls' }
$auth = New-ProfileXMLAuthentication -UserAuth -UserMethod $authmethod `
    -RadiusServerNames $NPSServer -RadiusServerRootCA $RootCA `
    -CertSelectionCA $RootCA

$builder = New-ProfileXMLBuilder -Servers $VPNServer `
    -DnsSuffix $DomainName `
    -TrustedNetworkDetection $DomainName `
    -RoutingPolicy SplitTunnel `
    -Authentication $auth `
    -DomainNameInformation $dni0, $dni1 `
    -Routes $rt

$builder | Get-ProfileXML | Tee-Object -FilePath $OutFile
Pause
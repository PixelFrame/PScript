# Virtual Lab ALWAYS ON VPN

# Tunnel: IKEv2
# Authentication: Machine Certificate
# IPsec Crypto: Custom
# Routing: SplitTunnel
# Scope: Device / All users

$ProfileName = 'VirtLab AlwaysOnVPN'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

<#-- Define VPN ProfileXML --#>
$ProfileXML = '<VPNProfile>
    <RememberCredentials>true</RememberCredentials>
    <DnsSuffix>vlab.int</DnsSuffix>
    <AlwaysOn>true</AlwaysOn>
    <TrustedNetworkDetection>vlab.int</TrustedNetworkDetection>
    <NativeProfile>
        <Servers>vlb-ras.vlab.ext</Servers>
        <RoutingPolicyType>SplitTunnel</RoutingPolicyType>
        <NativeProtocolType>IKEv2</NativeProtocolType>
        <Authentication>
            <MachineMethod>Certificate</MachineMethod>
        </Authentication>
        <CryptographySuite>
            <AuthenticationTransformConstants>GCMAES256</AuthenticationTransformConstants>
            <CipherTransformConstants>GCMAES256</CipherTransformConstants>
            <EncryptionMethod>AES_GCM_256</EncryptionMethod>
            <IntegrityCheckMethod>SHA256</IntegrityCheckMethod>
            <DHGroup>Group14</DHGroup>
            <PfsGroup>PFS2048</PfsGroup>
        </CryptographySuite>
    </NativeProfile>
    <Route>
        <Address>10.1.1.0</Address>
        <PrefixSize>24</PrefixSize>
    </Route>
    <!--
    <AppTriggerList>
        <App>
            <Id>C:\windows\system32\ping.exe</Id>
        </App>
    </AppTriggerList>
    <DeviceTunnel>true</DeviceTunnel>
    -->
</VPNProfile>'

<#-- Convert ProfileXML to Escaped Format --#>
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

<#-- Define WMI-to-CSP Bridge Properties --#>
$nodeCSPURI = './Vendor/MSFT/VPNv2'
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_VPNv2_01"

<#-- Define WMI Session --#>
$session = New-CimSession

<#-- Detect and Delete Previous VPN Profile --#>
try
{
    $deleteInstances = $session.EnumerateInstances($namespaceName, $className, $options)
    foreach ($deleteInstance in $deleteInstances)
    {
        $InstanceId = $deleteInstance.InstanceID
        if ("$InstanceId" -eq "$ProfileNameEscaped")
        {
            $session.DeleteInstance($namespaceName, $deleteInstance, $options)
            $Message = "Removed $ProfileName profile $InstanceId"
            Write-Host "$Message"
        }
        else
        {
            $Message = "Ignoring existing VPN profile $InstanceId"
            Write-Host "$Message"
        }
    }
}
catch [Exception]
{
    $Message = "Unable to remove existing outdated instance(s) of $ProfileName profile: $_"
    Write-Host "$Message"
    exit
}

<#-- Create VPN Profile --#>
try
{
    $newInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $className, $namespaceName
    $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ParentID", "$nodeCSPURI", 'String', 'Key')
    $newInstance.CimInstanceProperties.Add($property)
    $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("InstanceID", "$ProfileNameEscaped", 'String', 'Key')
    $newInstance.CimInstanceProperties.Add($property)
    $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ProfileXML", "$ProfileXML", 'String', 'Property')
    $newInstance.CimInstanceProperties.Add($property)

    $session.CreateInstance($namespaceName, $newInstance, $options)
    $Message = "Created $ProfileName profile."
    Write-Host "$Message"
    Write-Host "$ProfileName profile summary:"  
    $session.EnumerateInstances($namespaceName, $className, $options)
}
catch [Exception]
{
    $Message = "Unable to create $ProfileName profile: $_"
    Write-Host "$Message"
    exit
}

$Message = "Script Complete"
Write-Host "$Message"
# NHV LAB ALWAYS ON VPN

# Tunnel: IKEv2
# Authentication: User Tunnel EAP-TLS / Certificate
# Crypto: Custom
# Routing: SplitTunnel

$ProfileName = 'NHV AlwaysOnVPN User Tunnel'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

<#-- Define VPN ProfileXML --#>
$ProfileXML = '<VPNProfile>
    <RememberCredentials>true</RememberCredentials>
    <DnsSuffix>nvlab.local</DnsSuffix>
    <AlwaysOn>true</AlwaysOn>
    <TrustedNetworkDetection>nvlab.local</TrustedNetworkDetection>
    <NativeProfile>
        <Servers>nhv-ras.nvlab.pub</Servers>
        <RoutingPolicyType>SplitTunnel</RoutingPolicyType>
        <NativeProtocolType>IKEv2</NativeProtocolType>
        <Authentication>
            <UserMethod>Eap</UserMethod>
            <Eap>
                <Configuration>
                    <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
                        <EapMethod>
                            <Type xmlns="http://www.microsoft.com/provisioning/EapCommon">25</Type>
                            <VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId>
                            <VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType>
                            <AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId>
                        </EapMethod>
                        <Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig">
                            <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                                <Type>25</Type>
                                <EapType xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV1">
                                    <ServerValidation>
                                        <DisableUserPromptForServerValidation>true</DisableUserPromptForServerValidation>
                                        <ServerNames>nhv-ras.nvlab.pub</ServerNames>
                                        <TrustedRootCA>48 a9 c5 46 34 54 18 9b f8 d7 4c 76 60 c9 37 d9 47 ba 08 0f </TrustedRootCA>
                                    </ServerValidation>
                                    <FastReconnect>true</FastReconnect>
                                    <InnerEapOptional>false</InnerEapOptional>
                                    <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                                        <Type>13</Type>
                                        <EapType xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1">
                                            <CredentialsSource>
                                                <CertificateStore>
                                                    <SimpleCertSelection>true</SimpleCertSelection>
                                                </CertificateStore>
                                            </CredentialsSource>
                                            <ServerValidation>
                                                <DisableUserPromptForServerValidation>true</DisableUserPromptForServerValidation>
                                                <ServerNames>nhv-ras.nvlab.pub</ServerNames>
                                                <TrustedRootCA>48 a9 c5 46 34 54 18 9b f8 d7 4c 76 60 c9 37 d9 47 ba 08 0f </TrustedRootCA>
                                            </ServerValidation>
                                            <DifferentUsername>false</DifferentUsername>
                                            <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</PerformServerValidation>
                                            <AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</AcceptServerName>
                                            <TLSExtensions xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">
                                                <FilteringInfo xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV3">
                                                    <AllPurposeEnabled>true</AllPurposeEnabled>
                                                    <CAHashList Enabled="true">
                                                        <IssuerHash>70 f0 41 a9 9f 6b f6 6a 12 3d e6 56 fe 1d b7 0b 3c 6c ee 7e </IssuerHash>
                                                    </CAHashList>
                                                    <EKUMapping>
                                                        <EKUMap>
                                                            <EKUName>Client Authentication</EKUName>
                                                            <EKUOID>1.3.6.1.5.5.7.3.2</EKUOID>
                                                        </EKUMap>
                                                    </EKUMapping>
                                                    <ClientAuthEKUList Enabled="true" />
                                                    <AnyPurposeEKUList Enabled="true">
                                                        <EKUMapInList>
                                                            <EKUName>Client Authentication</EKUName>
                                                        </EKUMapInList>
                                                    </AnyPurposeEKUList>
                                                </FilteringInfo>
                                            </TLSExtensions>
                                        </EapType>
                                    </Eap>
                                    <EnableQuarantineChecks>false</EnableQuarantineChecks>
                                    <RequireCryptoBinding>false</RequireCryptoBinding>
                                    <PeapExtensions>
                                        <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</PerformServerValidation>
                                        <AcceptServerName xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">false</AcceptServerName>
                                    </PeapExtensions>
                                </EapType>
                            </Eap>
                        </Config>
                    </EapHostConfig>
                </Configuration>
            </Eap>
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
    <DeviceTunnel>false</DeviceTunnel>
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

$RASPhone = $RASPhone = ( $env:ALLUSERSPROFILE ) + '\Microsoft\Network\Connections\Pbk\rasphone.pbk'
$RasphoneContent = Get-Content $RASPhone
$ReachedUserTunnel = $false
$lineNum = 0
foreach ($line in $RasphoneContent)
{
    if ($ReachedUserTunnel)
    {
        if ($line -like 'VpnStrategy=?')
        {
            $RasphoneContent[$lineNum] = 'VpnStrategy=14'
            break
        }
    }
    elseif ($line -eq '[NHV AlwaysOnVPN User Tunnel]')
    {
        $ReachedUserTunnel = $true
    }
    ++$lineNum
}
$RasphoneContent | Set-Content $RASPhone

$Message = "Script Complete"
Write-Host "$Message"
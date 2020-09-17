# Virtual Lab ALWAYS ON VPN

# Tunnel: Automatic (Strategy 14) 
# Authentication: PEAP-MSCHAPv2
# IPsec Crypto: Custom
# Routing: SplitTunnel
# Scope: User

$ProfileName = 'VirtLab AlwaysOnVPN User Tunnel'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

<#-- Define VPN ProfileXML --#>
$ProfileXML = 
@'
<VPNProfile>
    <RememberCredentials>true</RememberCredentials>
    <DnsSuffix>vlab.int</DnsSuffix>
    <AlwaysOn>true</AlwaysOn>
    <TrustedNetworkDetection>vlab.int</TrustedNetworkDetection>
    <NativeProfile>
        <Servers>vpn.vlab.ext</Servers>
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
                                        <DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation>
                                        <ServerNames>vpn.vlab.ext;VLB-SV2.vlab.int</ServerNames>
                                        <TrustedRootCA>4b 78 0a a5 13 76 64 9e ad 0e 91 47 67 86 50 42 f0 80 b1 61 </TrustedRootCA>
                                    </ServerValidation>
                                    <FastReconnect>true</FastReconnect>
                                    <InnerEapOptional>false</InnerEapOptional>
                                    <Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1">
                                        <Type>26</Type>
                                        <EapType xmlns="http://www.microsoft.com/provisioning/MsChapV2ConnectionPropertiesV1">
                                            <UseWinLogonCredentials>true</UseWinLogonCredentials>
                                        </EapType>
                                    </Eap>
                                    <EnableQuarantineChecks>false</EnableQuarantineChecks>
                                    <RequireCryptoBinding>false</RequireCryptoBinding>
                                    <PeapExtensions>
                                        <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</PerformServerValidation>
                                        <AcceptServerName xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">true</AcceptServerName>
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
</VPNProfile>
'@


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

<#-- Clean up registry keys --#>
$SearchPattern = '*/Vendor/MSFT/VPNv2/' + $ProfileNameEscaped
$RegPath = 'HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\*\*\*'
$RegItems = Get-Item -Path $RegPath

foreach ($RegItem in $RegItems)
{
    $RegItem.Property | ForEach-Object {
        if ($RegItem.GetValue($_) -like $SearchPattern)
        {
            "Removed Registry $_ : " + $RegItem.GetValue($_)
            $CurrentRegPath = $RegItem.Name.Replace('HKEY_LOCAL_MACHINE', 'HKLM:')
            Remove-ItemProperty -Name $_ -Path $CurrentRegPath
        }
    }
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

<#-- Change Strategy to 14 --#>
[string[]] $RasPhoneBooks += ( $env:ALLUSERSPROFILE ) + '\Microsoft\Network\Connections\Pbk\RasPhone.pbk'
$RasPhoneBooks += ( $env:APPDATA ) + '\Microsoft\Network\Connections\Pbk\RasPhone.pbk'
$RasPhoneBooks += ( $env:APPDATA ) + '\Microsoft\Network\Connections\Pbk\_hiddenPbk\RasPhone.pbk'

foreach ($RasPhone in $RasPhoneBooks)
{
    if (!(Test-Path $RasPhone)) { continue }
    $RasPhoneContent = Get-Content $RasPhone
    $ReachedUserTunnel = $false
    $lineNum = 0
    foreach ($line in $RasPhoneContent)
    {
        if ($ReachedUserTunnel)
        {
            if ($line -like 'VpnStrategy=?')
            {
                $RasPhoneContent[$lineNum] = 'VpnStrategy=14'
                'Changed VPN Strategy to 14'
                break
            }
        }
        elseif ($line -eq ('[' + $ProfileName + ']'))
        {
            $ReachedUserTunnel = $true
            "Found Profile in $RasPhone"
        }
        ++$lineNum
    }
    $RasPhoneContent | Set-Content $RasPhone    
}

$Message = "Script Complete"
Write-Host "$Message"
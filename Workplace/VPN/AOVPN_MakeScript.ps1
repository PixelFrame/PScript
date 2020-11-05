$ProfileName = 'VLAB AoVPN PEAP-TLS UT'
$VpnServer = 'vpn.vlab.ext'
$NpsServer = 'VML-MPSRV-01.vlab.int'
$RootCAHash = '24 21 39 6E 6F A9 1E 19 52 01 01 AD 35 C6 7E B6 D3 1F DB CE '
$DnsSuffix = 'vlab.int'
$RoutingTunnel = 'ForceTunnel'
$EapType = 'TLS'

class CryptographySuite
{
    [string] $AuthenticationTransformConstants;
    [string] $CipherTransformConstants;
    [string] $EncryptionMethod;
    [string] $IntegrityCheckMethod;
    [string] $DHGroup;
    [string] $PfsGroup;

    [string] ToString()
    {
        $RES = '<CryptographySuite>'
        if ($null -ne $this.AuthenticationTransformConstants) { $RES += '    <AuthenticationTransformConstants>$($CryptSuite.AuthenticationTransformConstants)</AuthenticationTransformConstants>' }
        if ($null -ne $this.CipherTransformConstants) { $RES += '    <CipherTransformConstants>$($CryptSuite.CipherTransformConstants)</CipherTransformConstants>' }
        if ($null -ne $this.EncryptionMethod) { $RES += '    <EncryptionMethod>$($CryptSuite.EncryptionMethod)</EncryptionMethod>' }
        if ($null -ne $this.IntegrityCheckMethod) { $RES += '    <IntegrityCheckMethod>$($CryptSuite.IntegrityCheckMethod)</IntegrityCheckMethod>' }
        if ($null -ne $this.DHGroup) { $RES += '    <DHGroup>$($CryptSuite.DHGroup)</DHGroup>' }
        if ($null -ne $this.PfsGroup) { $RES += '    <PfsGroup>$($CryptSuite.PfsGroup)</PfsGroup>' }
        $RES += '</CryptographySuite>'
        return $RES
    }
}

class RoutingEntry
{
    [string] $Destination;
    [int] $Prefix;
    [int] $Metric;
    [bool] $Exclusion;
}

[CryptographySuite] $CryptSuite
[RoutingEntry[]] $Routing

$PEAP_MSCHAPv2_STRUCT = @"
<VPNProfile>
    <RememberCredentials>true</RememberCredentials>
    <DnsSuffix>$DnsSuffix</DnsSuffix>
    <AlwaysOn>true</AlwaysOn>
    <TrustedNetworkDetection>$DnsSuffix</TrustedNetworkDetection>
    <NativeProfile>
        <Servers>$VpnServer</Servers>
        <RoutingPolicyType>$RoutingTunnel</RoutingPolicyType>
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
                                        <ServerNames>$VpnServer;$NpsServer</ServerNames>
                                        <TrustedRootCA>$RootCAHash</TrustedRootCA>
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
        $CryptSuite
    </NativeProfile>
    <DeviceTunnel>false</DeviceTunnel>
</VPNProfile>
"@

$PEAP_TLS_STRUCT = @"
<VPNProfile>
    <RememberCredentials>true</RememberCredentials>
    <DnsSuffix>$DnsSuffix</DnsSuffix>
    <AlwaysOn>true</AlwaysOn>
    <TrustedNetworkDetection>$DnsSuffix</TrustedNetworkDetection>
    <NativeProfile>
        <Servers>$VpnServer</Servers>
        <RoutingPolicyType>$RoutingTunnel</RoutingPolicyType>
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
                                        <ServerNames>$VpnServer</ServerNames>
                                        <TrustedRootCA>$RootCAHash</TrustedRootCA>
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
                                                <DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation>
                                                <ServerNames>$NpsServer</ServerNames>
                                                <TrustedRootCA>$RootCAHash</TrustedRootCA>
                                            </ServerValidation>
                                            <DifferentUsername>false</DifferentUsername>
                                            <PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</PerformServerValidation>
                                            <AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</AcceptServerName>
                                            <TLSExtensions xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">
                                                <FilteringInfo xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV3">
                                                    <AllPurposeEnabled>true</AllPurposeEnabled>
                                                    <CAHashList Enabled="true">
                                                        <IssuerHash>$RootCAHash</IssuerHash>
                                                    </CAHashList>
                                                    <EKUMapping>
                                                        <EKUMap>
                                                            <EKUName>Client Authentication</EKUName>
                                                            <EKUOID>1.3.6.1.5.5.7.3.2</EKUOID>
                                                        </EKUMap>
                                                    </EKUMapping>
                                                    <ClientAuthEKUList Enabled="true" />
                                                    <AnyPurposeEKUList Enabled="true" />
                                                </FilteringInfo>
                                            </TLSExtensions>
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
        $CryptSuite
    </NativeProfile>
    <DeviceTunnel>false</DeviceTunnel>
</VPNProfile>
"@

$SCRIPT_STRUCT = @'
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
'@

if ($EapType -eq 'MSCHAPv2')
{
    $SCRIPT_STRUCT = @"

<#-- Define VPN ProfileXML --#>
`$ProfileXML = @'
$PEAP_MSCHAPv2_STRUCT
'@

"@ + $SCRIPT_STRUCT
}
else
{
    $SCRIPT_STRUCT = @"

<#-- Define VPN ProfileXML --#>
`$ProfileXML = @'
$PEAP_TLS_STRUCT
'@

"@ + $SCRIPT_STRUCT
}

$SCRIPT_STRUCT = @"
`$ProfileName = '$ProfileName'
`$ProfileNameEscaped = `$ProfileName -replace ' ', '%20'
"@ + $SCRIPT_STRUCT

Out-File .\DEPLOYMENT_TEST.ps1 -Encoding utf8NoBOM -InputObject $SCRIPT_STRUCT -Force
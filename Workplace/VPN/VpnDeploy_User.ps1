[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ProfileName,

    [Parameter(Mandatory = $true)]
    [string]
    $ProfileXMLFile
)

$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

<#-- Define VPN ProfileXML --#>
$ProfileXML = Get-Content $ProfileXMLFile

<#-- Convert ProfileXML to Escaped Format --#>
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

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

<#-- Determine user SID for VPN profile --#>

# This step is mainly for User Tunnel profile creation under System context
# But this won't work if the user is logged on over Remote Desktop
# So for manual deployment under User context, this can be removed directly

try
{
    $username = Get-WmiObject -Class Win32_ComputerSystem | Select-Object username
    $objuser = New-Object System.Security.Principal.NTAccount($username.username)
    $sid = $objuser.Translate([System.Security.Principal.SecurityIdentifier])
    $SidValue = $sid.Value
    $Message = "User SID is $SidValue."
    Write-Host "$Message"
}
catch [Exception]
{
    $Message = "Unable to get user SID. User may be logged on over Remote Desktop: $_"
    Write-Host "$Message"
    exit
}

<#-- Define WMI-to-CSP Bridge Properties --#>
$nodeCSPURI = './Vendor/MSFT/VPNv2'
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_VPNv2_01"

<#-- Define WMI Session --#>
$session = New-CimSession
$options = New-Object Microsoft.Management.Infrastructure.Options.CimOperationOptions
$options.SetCustomOption("PolicyPlatformContext_PrincipalContext_Type", "PolicyPlatform_UserContext", $false)
$options.SetCustomOption("PolicyPlatformContext_PrincipalContext_Id", "$SidValue", $false)

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
Pause
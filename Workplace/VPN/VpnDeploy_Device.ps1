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

<#-- Define WMI-to-CSP Bridge Properties --#>
$nodeCSPURI = './Vendor/MSFT/VPNv2'
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_VPNv2_01"

<#-- Define WMI Session --#>
$session = New-CimSession

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
Pause
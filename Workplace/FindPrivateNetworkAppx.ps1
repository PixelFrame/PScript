$Appxes = Get-AppxPackage
$Result = @()
foreach ($Appx in $Appxes)
{
    try
    {
        $Capability = (Get-AppxPackage $Appx.Name | Get-AppxPackageManifest).Package.Capabilities.Capability
    }
    catch
    {
        "$($Appx.PackageFullName) cannot find manifest"
    }
    if (($Capability.Name -contains 'privateNetworkClientServer') -and `
        ($Capability.Name -notcontains 'internetClient') -and `
        ($Capability.Name -notcontains 'internetClientServer'))
    {
        $Result += $Appx
    }
}
"Apps has only Private Network access: $($Result.Count)"
$Result.PackageFullName
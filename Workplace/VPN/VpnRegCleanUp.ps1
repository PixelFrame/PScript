$ProfileName = 'VirtLab AlwaysOnVPN'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$SearchPattern = '*VPNv2/' + $ProfileNameEscaped + '*'
$RegPath = 'HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\*\*\*'
$RegItems = Get-Item -Path $RegPath

foreach ($RegItem in $RegItems)
{
    $RegItem.Property | ForEach-Object {
        if ($RegItem.GetValue($_) -like $SearchPattern)
        {
            Remove-ItemProperty -Name $_ -Path $RegPath
        }
    }
}
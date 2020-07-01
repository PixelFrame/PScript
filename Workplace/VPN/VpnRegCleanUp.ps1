$ProfileName = 'VirtLab AlwaysOnVPN'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$SearchPattern = '*/Vendor/MSFT/VPNv2/' + $ProfileNameEscaped
$RegPath = 'HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked\*\*\*'
'[DEBUG]: '
'Search Pattern:' + $SearchPattern
'RegPath:' + $RegPath

$RegItems = Get-Item -Path $RegPath

'[DEBUG]: Registries found'
$RegItems

foreach ($RegItem in $RegItems)
{
    '[DEBUG]: Now Processing: ' + $RegItem
    $RegItem.Property | ForEach-Object {
        if ($RegItem.GetValue($_) -like $SearchPattern)
        {
            $CurrentRegPath = $RegItem.Name.Replace('HKEY_LOCAL_MACHINE', 'HKLM:')
            Remove-ItemProperty -Name $_ -Path $CurrentRegPath
            '[DEBUG]: Removed!'
        }
        else
        {
            '[DEBUG]: Not matching, skipped'
        }
    }
}
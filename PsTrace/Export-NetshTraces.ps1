$WppTraceReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\NetDiagFx\Microsoft\HostDLLs\WPPTrace\HelperClasses\'
$Scenarios = Get-ChildItem $WppTraceReg

$ScenarioObjects = @()
foreach ($Scenario in $Scenarios)
{
    $ScenarioName = $Scenario.Name.Substring($Scenario.Name.LastIndexOf('\') + 1)
    $Providers = $Scenario.OpenSubKey('Providers')
    $ProviderGuids = $Providers.GetSubKeyNames()
    $ProviderObjects = @()
    foreach ($ProviderGuid in $ProviderGuids)
    {
        $Provider = $Providers.OpenSubKey($ProviderGuid)
        $ProviderObjects += [PSCustomObject]@{
            Guid     = $ProviderGuid;
            Keywords = $Provider.GetValue('Keywords');
            Level    = $Provider.GetValue('Level');
            Name     = $Provider.GetValue('Name')
        }
    }
    $ScenarioObjects += [PSCustomObject]@{
        Name      = $ScenarioName;
        Providers = $ProviderObjects
    }
}
$ScenarioObjects
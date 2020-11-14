$WppTraceReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\NetDiagFx\Microsoft\HostDLLs\*\HelperClasses\*'
$Scenarios = Get-ChildItem $WppTraceReg

$ScenarioObjects = @{}
foreach ($Scenario in $Scenarios)
{
    $ScenarioName = $Scenario.Name.Substring($Scenario.Name.LastIndexOf('\') + 1)
    $Providers = $Scenario.OpenSubKey('Providers')
    if ($null -ne $Providers)
    {
        $ProviderGuids = $Providers.GetSubKeyNames()
        $ProviderObjects = New-Object System.Collections.ArrayList
        foreach ($ProviderGuid in $ProviderGuids)
        {
            $Provider = $Providers.OpenSubKey($ProviderGuid)
            $ProviderObjects.Add([PSCustomObject]@{
                    Guid     = $ProviderGuid;
                    Keywords = $Provider.GetValue('Keywords');
                    Level    = $Provider.GetValue('Level');
                    Name     = $Provider.GetValue('Name')
                }) | Out-Null
        }
        $ScenarioObjects[$ScenarioName] = $ProviderObjects
    }
    else
    {
        $ScenarioObjects[$ScenarioName] = @()
        "No provider for this scenario"
    }
}
foreach ($Scenario in $Scenarios)
{
    $ScenarioName = $Scenario.Name.Substring($Scenario.Name.LastIndexOf('\') + 1)
    $Dependencies = $Scenario.OpenSubKey('Dependencies')
    if ($null -ne $Dependencies)
    {
        $DependencyNames = $Dependencies.GetSubKeyNames()
        foreach ($DependencyName in $DependencyNames)
        {
            $ScenarioObjects[$ScenarioName].AddRange($ScenarioObjects[$DependencyName]) | Out-Null
        }
    }
    else
    {
        "No dependency for this scenario"
    }
}

$ScenarioObjects.GetEnumerator() | ForEach-Object {
    'Scenario: ' + $_.Name
    $_.Value | fl
}
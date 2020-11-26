function CreateScenario
{
    param (
        $Scenario,
        [ref] $RefScenarioObjects
    )

    $ScenarioName = $Scenario.Name.Substring($Scenario.Name.LastIndexOf('\') + 1)
    if ($RefScenarioObjects.Value.Contains($ScenarioName))
    {
        return
    }
    $Providers = $Scenario.OpenSubKey('Providers')
    $Dependencies = $Scenario.OpenSubKey('Dependencies')
    if ($null -ne $Providers)
    {
        $ProviderGuids = $Providers.GetSubKeyNames()
        $ProviderObjects = New-Object System.Collections.Hashtable
        foreach ($ProviderGuid in $ProviderGuids)
        {
            $Provider = $Providers.OpenSubKey($ProviderGuid)
            $ProviderObjects[$ProviderGuid] = [PSCustomObject]@{
                Guid     = $ProviderGuid;
                Keywords = '0x{0:x}' -f $Provider.GetValue('Keywords');
                Level    = $Provider.GetValue('Level');
                Name     = $Provider.GetValue('Name')
            }
        }
        $RefScenarioObjects.Value[$ScenarioName] = $ProviderObjects
    }
    else
    {
        $RefScenarioObjects.Value[$ScenarioName] = New-Object System.Collections.Hashtable
    }
    if ($null -ne $Dependencies)
    {
        $DependencyNames = $Dependencies.GetValueNames()
        foreach ($DependencyName in $DependencyNames)
        {
            if (!$RefScenarioObjects.Value.Contains($DependencyName))
            {
                $Dependency = Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\NetDiagFx\Microsoft\HostDLLs\*\HelperClasses\$DependencyName"
                if ($null -eq $Dependency)
                {
                    "Inexistent Scenario: $DependencyName"
                    continue
                }
                else
                {
                    CreateScenario -Scenario $Dependency -RefScenarioObjects ([ref]$RefScenarioObjects.Value)
                }
            }
            $RefScenarioObjects.Value[$DependencyName].GetEnumerator() | ForEach-Object {
                if (!$RefScenarioObjects.Value[$ScenarioName].Contains($_.Name))
                {
                    $RefScenarioObjects.Value[$ScenarioName][$_.Name] = $_.Value
                }
            }
        }
    }
}

$WppTraceReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\NetDiagFx\Microsoft\HostDLLs\*\HelperClasses\*'
$Scenarios = Get-ChildItem $WppTraceReg

$ScenarioObjects = New-Object System.Collections.Hashtable
foreach ($Scenario in $Scenarios)
{
    CreateScenario -Scenario $Scenario -RefScenarioObjects ([ref]$ScenarioObjects)
}

$ScenarioObjects.GetEnumerator() | ForEach-Object {
    'Scenario: ' + $_.Name + "`n"
    if ($_.Value.Count -gt 0)
    { 
        $_.Value.GetEnumerator() | ForEach-Object {
            $_.Value
        }
    }
    else { 'No provider for this scenario' }
    '-----------------------------------------------------------'
}
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $OutPath = '.\NetshTraces'
)

class Provider
{
    [string] $Name;
    [Guid] $Guid;
    [int] $Level;
    [long] $Flags;
}

class HelperClass 
{
    [string] $Name;
    [HelperClass[]] $Dependencies;
    [Provider[]] $Providers;
}

$HelperClasses = @()

$WppTraceReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\NetDiagFx\Microsoft\HostDLLs\*\HelperClasses\*'
$WppTraceRegs = Get-ChildItem $WppTraceReg

foreach ($reg in $WppTraceRegs)
{
    $HelperClass = New-Object HelperClass
    $HelperClass.Name = $reg.Name.Substring($reg.Name.LastIndexOf('\') + 1)
    $HelperClass.Providers = @()

    $Providers = $reg.OpenSubKey('Providers')
    if ($null -ne $Providers)
    {
        $ProviderGuids = $Providers.GetSubKeyNames()
        foreach ($ProviderGuid in $ProviderGuids)
        {
            $Provider = $Providers.OpenSubKey($ProviderGuid)
            $ProviderObject = New-Object Provider
            $ProviderObject.Guid = [Guid]::Parse($ProviderGuid)
            $ProviderObject.Name = $Provider.GetValue('Name')
            $ProviderObject.Level = $Provider.GetValue('Level', 0xff)
            $ProviderObject.Flags = $Provider.GetValue('Keywords', -1)
            $HelperClass.Providers += $ProviderObject
        }
    }

    $HelperClasses += $HelperClass
}

for ($i = 0; $i -lt $HelperClasses.Count; $i++)
{
    $reg = $WppTraceRegs[$i]
    $HelperClass = $HelperClasses[$i]

    $Dependencies = $reg.OpenSubKey('Dependencies')
    if ($null -ne $Dependencies)
    {
        $DependencyNames = $Dependencies.GetValueNames()
        foreach ($DependencyName in $DependencyNames)
        {
            $Dependency = $HelperClasses | Where-Object { $_.Name -eq $DependencyName }
            if ($null -eq $Dependency)
            {
                "Inexistent Scenario: $DependencyName"
                continue
            }
            else
            {
                $HelperClass.Dependencies += $Dependency
            }
        }
    }
}

# IDK why ref is just not working here, but global varible is so simple, so **** off ref
function PrintHelperClass
{
    param (
        [HelperClass] $class
    )
    
    $Script:AllDependecies = @()
    GetAllDependencies -class $class
    foreach ($dep in $Script:AllDependecies)
    {
        Out-File -InputObject $dep.Name -FilePath "$OutPath\$($class.Name).txt" -Append
        foreach ($prov in $dep.Providers)
        {
            Out-File -InputObject "    $($prov.Guid)`t0x$($prov.Level.ToString('X'))`t0x$($prov.Flags.ToString('X'))`t$($prov.Name)" -FilePath "$OutPath\$($class.Name).txt" -Append
        }
    }
}

function GetAllDependencies()
{
    param (
        [HelperClass] $class
    )

    $Script:AllDependecies += $class
    if ($null -ne $class.Dependencies)
    {
        foreach ($dependency in $class.Dependencies)
        {
            if ($Script:AllDependecies -notcontains $dependency -and $dependency.Providers.Count -gt 0)
            {
                GetAllDependencies -class $dependency
            }
        }
    }
}

if (![System.IO.Directory]::Exists($OutPath))
{
    [System.IO.Directory]::CreateDirectory($OutPath)
}
foreach ($hc in $HelperClasses)
{
    Write-Host "Exporting $($hc.Name)"
    PrintHelperClass -class $hc
}
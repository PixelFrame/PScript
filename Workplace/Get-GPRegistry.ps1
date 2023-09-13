#requires -modules GroupPolicy

[CmdletBinding()]
param (
    [string]
    $GPOName
)

$GPO = Get-GPO $GPOName -ErrorAction Stop
$xml = [xml]$GPO.GenerateReport([Microsoft.GroupPolicy.ReportType]::Xml)

$namespace = @{ 
    gp = 'http://www.microsoft.com/GroupPolicy/Settings';
    q3 = 'http://www.microsoft.com/GroupPolicy/Settings/Registry';
}
$compRegNodes = (Select-Xml -XPath '//gp:Computer//q3:RegistrySetting' -Namespace $namespace -Xml $xml).Node
$userRegNodes = (Select-Xml -XPath '//gp:User//q3:RegistrySetting' -Namespace $namespace -Xml $xml).Node

$regs = @()

foreach ($regNode in $compRegNodes)
{
    $regs += Get-GPRegistryValue -Name $GPOName -Key "HKLM\$($regNode.KeyPath)" -ValueName "$($regNode.Value.Name)" -ErrorAction SilentlyContinue
}

foreach ($regNode in $userRegNodes)
{
    $regs += Get-GPRegistryValue -Name $GPOName -Key "HKCU\$($regNode.KeyPath)" -ValueName "$($regNode.Value.Name)" -ErrorAction SilentlyContinue
}

$regs
[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline, Mandatory = $true)]
    [Object]
    $InputObject
)

$Properties = $InputObject | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' }

foreach ($Property in $Properties)
{
    if ($IniString -ne '')
    {
        $IniString += "`n"
    }
    $IniString += '[' + $Property.Name + ']' + "`n"
    $ItemObj = $InputObject.($Property.Name)
    $ItemProperties = $ItemObj | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' }

    foreach ($ItemProperty in $ItemProperties)
    {
        $IniString += $ItemProperty.Name + '=' + $ItemObj.($ItemProperty.Name) + "`n"
    }
}

return $IniString
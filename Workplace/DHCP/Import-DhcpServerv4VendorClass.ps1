[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path = 'C:\DhcpClassOption'
)

$Classes = [string] (Get-Content -Path $Path\Classes.json) | ConvertFrom-Json
$LocalClasses = Get-DhcpServerv4Class
foreach ($Class in $Classes)
{
    if ($LocalClasses.Name -notcontains $Class.Name)
    {
        Add-DhcpServerv4Class -Name $Class.Name -Type $Class.Type -Data $Class.Data -Description $Class.Description
        "Added Class " + $Class.Name
    }
    else
    {
        "Skipped Class " + $Class.Name
    }
}
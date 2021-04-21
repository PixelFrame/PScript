[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PlanName = 'High'
)

$Plan = powercfg.exe /LIST | Where-Object { $_ -like "*$PlanName*" }
if (($Plan -ne [String]::Empty) -or ($null -ne $Plan))
{
    $PlanGuid = $Plan.SubString(19, 36)
    powercfg.exe /SETACTIVE $PlanGuid
}

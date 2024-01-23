[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Source,

    [Parameter(Mandatory)]
    [string]
    $Destination,

    [Parameter(Mandatory)]
    [string]
    $Filter
)

if (!(Test-Path $Destination)) { New-Item -Path $Destination -ItemType Directory -Force }
$files = Get-ChildItem -Path $Source -Filter $Filter -Recurse
$files | ForEach-Object { Move-Item  -Path $_ -Destination $Destination }
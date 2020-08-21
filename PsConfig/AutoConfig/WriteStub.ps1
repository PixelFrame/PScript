[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PSType
)

$ProfilePath = $env:USERPROFILE + '\Documents\' + $PSType
if (!(Test-Path -Path $ProfilePath\Scripts))
{
    New-Item -Path $ProfilePath\Scripts -ItemType Directory | Out-Null
}
Copy-Item -Path $PSScriptRoot\..\ConfigPS.ps1 -Destination $ProfilePath\Scripts -Force -ErrorAction SilentlyContinue
Copy-Item -Path $PSScriptRoot -Destination $ProfilePath\Scripts -Recurse -Force -ErrorAction SilentlyContinue
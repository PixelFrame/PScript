[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $PSType
)

$ProfilePath = $env:USERPROFILE + '\Documents\' + $PSType
Copy-Item -Path $PSScriptRoot\..\ConfigPS.ps1 -Destination $ProfilePath\Scripts -Force -ErrorAction SilentlyContinue
Copy-Item -Path $PSScriptRoot -Destination $ProfilePath\Scripts -Recurse -Force -ErrorAction SilentlyContinue
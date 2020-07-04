[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ProfilePath
)

if (!(Test-Path -Path $ProfilePath\Scripts))
{
    New-Item -Path $ProfilePath\Scripts -ItemType Directory 
}
Copy-Item -Path $PSScriptRoot\..\ConfigPS.ps1 -Destination $ProfilePath\Scripts
Copy-Item -Path $PSScriptRoot -Destination $ProfilePath\Scripts\AutoConfig -Recurse
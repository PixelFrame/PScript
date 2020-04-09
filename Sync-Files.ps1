[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $SourcePath,

    [Parameter(Mandatory = $true)]
    [string]
    $DestPath
)

$SourceFiles = Get-ChildItem -Path $SourcePath
$DestPath = Get-ChildItem -Path $DestPath


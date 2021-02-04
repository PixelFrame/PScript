#Requires -Version 7

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    [ValidateScript( { Test-Path $_ })]
    $Path,

    [Parameter(Mandatory = $true)]
    [string]
    $Output,
    
    [Parameter]
    [uint]
    $ThreadCount = 8
)

$Result = [System.Collections.Generic.SortedDictionary[string, string]]@{}
$Files = Get-ChildItem -Path $Path -File -Recurse

$Files | ForEach-Object -Parallel {
    $File = $_.FullName.Replace('[', '`[').Replace(']', '`]')
    $Hash = Get-FileHash -Path $File -Algorithm SHA512
    $($using:Result).Add($Hash.Path, $Hash.Hash)
} -ThrottleLimit $ThreadCount

$Result.GetEnumerator() | Select-Object @{N = 'Path'; E = { $_.Key } }, @{N = 'SHA512'; E = { $_.Value } } | Export-Csv -Path $Output
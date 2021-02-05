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
    
    [Parameter()]
    [int]
    $ThreadCount = 8
)

$Files = Get-ChildItem -Path $Path -File -Recurse
$Total = $Files.Length
$Result = New-Object 'System.Collections.Concurrent.ConcurrentDictionary[string, string]' -ArgumentList @($ThreadCount, $Total)

"Total File Count: $Total"

$Job = $Files | ForEach-Object -Parallel {
    $ResultCopy = $($using:Result)
    $File = $_.FullName.Replace('[', '`[').Replace(']', '`]')
    $Hash = Get-FileHash -Path $File -Algorithm SHA512
    $ResultCopy[$File] = $Hash.Hash
} -ThrottleLimit $ThreadCount -AsJob

while ($Job.State -eq 'Running')
{
    $Percent = $Result.Count / $Total * 100
    Write-Progress -Activity "Calculating File Hash using $ThreadCount Threads" -PercentComplete $Percent -Status "Hashed File: $($Result.Count) / $Total"

    Start-Sleep -Seconds 0.1
}

"Hash Completed"
"Writing Output"
$Result.GetEnumerator() | Sort-Object -Property Key | Select-Object @{N = 'Path'; E = { $_.Key } }, @{N = 'SHA512'; E = { $_.Value } } | Export-Csv -Path $Output
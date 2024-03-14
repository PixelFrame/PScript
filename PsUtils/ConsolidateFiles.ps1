[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Source,

    [Parameter(Mandatory)]
    [string]
    $Destination,

    [Parameter()]
    [string]
    $Filter = '*',

    [Parameter()]
    [string[]]
    $FullNameRegexIncludeFilters,

    [Parameter()]
    [string[]]
    $FileNameRegexIncludeFilters,

    [Parameter()]
    [string[]]
    $FullNameRegexExcludeFilters,

    [Parameter()]
    [string[]]
    $FileNameRegexExcludeFilters,

    [switch]
    $Preview
)

if (!(Test-Path $Destination)) { New-Item -Path $Destination -ItemType Directory -Force }
$files = Get-ChildItem -Path $Source -Filter $Filter -Recurse

foreach ($FullNameRegexIncludeFilter in $FullNameRegexIncludeFilters)
{
    $files = $files | Where-Object { $_.FullName -match $FullNameRegexIncludeFilter }
}

foreach ($FullNameRegexExcludeFilter in $FullNameRegexExcludeFilters)
{
    $files = $files | Where-Object { $_.FullName -notmatch $FullNameRegexExcludeFilter }
}

foreach ($FileNameRegexIncludeFilter in $FileNameRegexIncludeFilters)
{
    $files = $files | Where-Object { $_.Name -match $FileNameRegexIncludeFilter }
}

foreach ($FileNameRegexExcludeFilter in $FileNameRegexExcludeFilters)
{
    $files = $files | Where-Object { $_.Name -notmatch $FileNameRegexExcludeFilter }
}

if ($Preview)
{
    $files | Select-Object FullName
}
else
{
    $files | ForEach-Object { Move-Item  -Path $_ -Destination $Destination }
}
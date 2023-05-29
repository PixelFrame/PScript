[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0)]
    [string]
    $ArchiveLiteralPath,

    [Parameter()]
    [string]
    $OutputPath
)

try
{
    Get-Command 7z.exe -ErrorAction Stop | Out-Null
}
catch
{
    throw "7z.exe not found. Please install 7-Zip or Nanazip and try again."
}

$tempdir = $env:TEMP + "\ArcToZip"
try
{
    mkdir $tempdir -ErrorAction Stop | Out-Null
}
catch
{
    try
    {
        Get-ChildItem $tempdir | Remove-Item -Recurse -Force -ErrorAction Stop
    }
    catch
    {
        throw "Unable to create or clean temporary directory."
    }
}

Push-Location
Set-Location $tempdir

try
{
    $archive = Get-Item -LiteralPath $ArchiveLiteralPath -ErrorAction Stop
}
catch
{
    Pop-Location
    throw "Archive not found."
}

if ([string]::IsNullOrEmpty($OutputPath))
{
    $OutputPath = $archive.DirectoryName
}

$cmd = "7z.exe x -o'.\' '$($archive.FullName)'"
Write-Host "Invoke command: $cmd" -BackgroundColor Green -ForegroundColor White
Invoke-Expression -Command $cmd

$fileList = ''
Get-ChildItem .\* | ForEach-Object { $fileList += "'$($_.FullName)' " }
$cmd = "7z.exe a -tzip -mx=7 -r '$OutputPath\$($archive.BaseName)' $fileList"
Write-Host "Invoke command: $cmd" -BackgroundColor Green -ForegroundColor White
Invoke-Expression -Command $cmd

Pop-Location

Remove-Item $tempdir -Recurse -Force
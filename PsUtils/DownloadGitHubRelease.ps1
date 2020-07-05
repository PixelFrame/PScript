[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Author,

    [Parameter(Mandatory = $true)]
    [string]
    $Repository,

    [Parameter()]
    [string]
    $OutPath = '.\',

    [Parameter()]
    [string]
    $FileFilter,

    [Parameter()]
    [string]
    $Tag = 'latest',

    [Parameter()]
    [string]
    $Proxy
)

$AuthRepo = $Author + '/' + $Repository

if ($Tag -eq 'latest')
{
    $Releases = "https://api.github.com/repos/$AuthRepo/releases/latest"    
}
else
{
    $Releases = "https://api.github.com/repos/$AuthRepo/releases/tags/$Tag"
}

try
{
    if ($Proxy -ne '')
    {
        $Response = Invoke-WebRequest $Releases -Proxy $Proxy -ErrorAction Stop | ConvertFrom-Json
    }
    else
    {
        $Response = Invoke-WebRequest $Releases -ErrorAction Stop | ConvertFrom-Json
    }
}
catch
{
    $_
    Write-Host 'Retrieve Repository Information Failed' -ForegroundColor Red
    Exit
}

$Tag = $Response.tag_name

if ($null -eq $FileFilter)
{
    $DownloadFiles = $Response.assets | Select-Object -Property name, download_count, size, created_at, updated_at, browser_download_url
}
else
{
    $ResponseFiles = $Response.assets | Select-Object -Property name, download_count, size, created_at, updated_at, browser_download_url
    $DownloadFiles = $ResponseFiles | Where-Object -FilterScript { $_.name -like $FileFilter }
}

if ($DownloadFiles.Count -eq 0)
{
    Write-Host 'WARNING: NO FILES TO BE DOWNLOADED' -ForegroundColor DarkYellow
    if ((Read-Host -Prompt 'Downloaded all the assets? Y or exit') -in @('Y', 'y')) { $DownloadFiles = $ResponseFiles }
    else { exit }
}

Write-Host '************ Files to be downloaded ************'
$DownloadFiles | Format-Table * -AutoSize
Write-Host '************************************************'

if ((Read-Host -Prompt 'Continue? Y or exit') -notin @('Y', 'y')) { exit }

ForEach-Object -InputObject $DownloadFiles -Parallel {
    $AbsOutPath = $OutPath + $_.name.Substring(0, $_.name.LastIndexOf('.')) + '-' + $Tag + $_.name.Substring($_.name.LastIndexOf('.'))
    Invoke-WebRequest $_.browser_download_url -Out $AbsOutPath -Proxy $Proxy
}

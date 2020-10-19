$HTML = Get-Content .\Playlist.html
$Counter = 1
$Reached = $false
$Titles = @()

$Titles += 'Index,Title'
foreach ($line in $HTML)
{
    if ($line.Contains('span id="video-title"'))
    {
        $Reached = $true
        continue
    }
    if ($Reached)
    {
        $Titles += $Counter.ToString() + ",`"" + $line.Trim() + "`""
        ++$Counter
        $Reached = $false
    }
}

$Titles | Out-File .\Playlist.csv

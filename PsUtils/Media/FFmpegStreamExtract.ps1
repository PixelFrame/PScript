$MediaFolder = 'X:\Movie\James.Bond.1-24.BluRay.720p.3Audio.x264-CMCT'
$Videos = Get-ChildItem $MediaFolder

foreach ($Video in $Videos)
{
    $StreamInfo = (ffprobe.exe -v quiet -show_streams -of json $Video.FullName | ConvertFrom-Json).streams
    $TargetStream = $StreamInfo | Where-Object { $_.codec_name -eq 'ass' -and $_.tags.title -eq '中上英下' }
    if ($null -ne $TargetStream)
    {
        #Write-Host "ffmpeg.exe -i $($Video.FullName) -map 0:$($TargetStream.index) -c copy $($Video.BaseName).ass"
        Invoke-Expression "ffmpeg.exe -i $($Video.FullName) -map 0:$($TargetStream.index) -c copy $($Video.BaseName).ass"
    }
    else
    {
        Write-Host 'Target Stream Not Found'
    }
}
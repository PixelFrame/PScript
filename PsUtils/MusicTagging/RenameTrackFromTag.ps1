$TagLibSharpDll = Resolve-Path $PSScriptRoot\..\Bin\TagLibSharp.dll
[Reflection.Assembly]::LoadFrom($TagLibSharpDll)

$Files = Get-ChildItem "C:\Users\pm421\OneDrive\Media\Music\Lossless\Shiro SAGISU Music from ''SHIN EVANGELION'' EVANGELION- 3.0 + 1.0\FLAC"

foreach ($File in $Files)
{
    $media = [TagLib.File]::Create($File.FullName)
    $Disc = $media.Tag.Disc 
    $Track = $media.Tag.Track.ToString('00')
    $Title = $media.Tag.Title
    $Extension = $File.Extension

    try
    {
        Rename-Item -Path $File.FullName -NewName "$Disc.$Track $Title$Extension" -ErrorAction Stop
    }
    catch
    {
        $Title = $Title.Replace(':', '-')
        $Title = $Title.Replace('"', '-')
        $Title = $Title.Replace('\', '-')
        $Title = $Title.Replace('/', '-')
        $Title = $Title.Replace('?', '-')
        $Title = $Title.Replace('|', '-')
        $Title = $Title.Replace('*', '-')
        $Title = $Title.Replace('<', '-')
        $Title = $Title.Replace('>', '-')
        Rename-Item -Path $File.FullName -NewName "$Disc.$Track $Title$Extension"
    }
    $media.Dispose()
}
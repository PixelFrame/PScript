# Load TagLibSharp.dll
# https://github.com/mono/taglib-sharp/
$TagLibSharpDll = Resolve-Path $PSScriptRoot\..\Bin\TagLibSharp.dll
[Reflection.Assembly]::LoadFrom($TagLibSharpDll)

$Files = Get-ChildItem 'C:\Video\PMD RTDX'
$Counter = 1

foreach ($File in $Files)
{
    $Title = $File.BaseName.Substring($File.BaseName.IndexOf(' ') + 1)

    $media = [TagLib.File]::Create($File.FullName)
    $media.Tag.Title = $Title
    $media.Tag.Album = 'Pokémon Mystery Dungeon Rescue Team DX'
    $media.Tag.Artists = 'Keisuke Ito'
    $media.Tag.AlbumArtists = 'Keisuke Ito'
    $media.Tag.Track = $Counter++
    $media.Tag.TrackCount = 89
    $media.Save()
}
# Load TagLibSharp.dll
# https://github.com/mono/taglib-sharp/
$TagLibSharpDll = Resolve-Path $PSScriptRoot\..\Bin\TagLibSharp.dll
[Reflection.Assembly]::LoadFrom($TagLibSharpDll)

$Files = Get-ChildItem 'C:\Video\PMD RTDX'

foreach ($File in $Files)
{
    $Title = $File.BaseName.Substring($File.BaseName.IndexOf(' ') + 1)
    $Track = [Int32]::Parse($File.BaseName.Substring(0, $File.BaseName.IndexOf('.')))

    $media = [TagLib.File]::Create($File.FullName)
    $media.Tag.Title = $Title
    $media.Tag.Album = 'Pokémon Mystery Dungeon Rescue Team DX'
    $media.Tag.Artists = 'Keisuke Ito'
    $media.Tag.AlbumArtists = 'Keisuke Ito'
    $media.Tag.Track = $Track
    $media.Tag.TrackCount = 89
    $media.Save()
}
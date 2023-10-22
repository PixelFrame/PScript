[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

$TagLibSharpDll = (Resolve-Path $PSScriptRoot\..\..\Bin\TagLibSharp.dll).ToString().Replace('Microsoft.PowerShell.Core\FileSystem::', '')
[Reflection.Assembly]::LoadFrom($TagLibSharpDll)

$Files = Get-ChildItem $Path

foreach ($File in $Files)
{
    $media = [TagLib.File]::Create($File.FullName)
    $Disc = $media.Tag.Disc 
    $Track = $media.Tag.Track.ToString('00')
    $Title = $media.Tag.Title
    $Extension = $File.Extension

    try
    {
        Rename-Item -Path $File.FullName -NewName "$Disc.$Track - $Title$Extension" -ErrorAction Stop
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
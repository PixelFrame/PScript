[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $DirLiteralPath,

    [Parameter()]
    [string]
    [ValidateSet('srt', 'ass', 'ssa')]
    $SubtitleExt = 'ass',

    [Parameter]
    [string]
    [ValidateSet('mkv', 'mp4', 'avi')]
    $VideoExt = 'mkv',

    [Parameter]
    [string]
    [ValidateSet('SingleLang', 'SC+TC', 'TC+SC')]
    $Mode = 'SingleLang'
)

$Subtitles = Get-ChildItem -LiteralPath $DirLiteralPath -Filter "*.$SubtitleExt"
$Videos = Get-ChildItem -LiteralPath $DirLiteralPath -Filter "*.$VideoExt"

if ($Mode -eq 'SingleLang')
{
    for ($i = 0; $i -lt $VideoExt.Count; $i++) 
    {
        Rename-Item -LiteralPath $Subtitles[$i].FullName -NewName "$($Videos[$i].BaseName).$SubtitleExt"
    }
}
else 
{
    for ($i = 0; $i -lt $VideoExt.Count; $i++) 
    {
        if ($Mode -eq 'SC+TC')
        {
            Rename-Item -LiteralPath $Subtitles[$i * 2].FullName -NewName "$($Videos[$i].BaseName).sc.$SubtitleExt"
            Rename-Item -LiteralPath $Subtitles[$i * 2 + 1].FullName -NewName "$($Videos[$i].BaseName).tc.$SubtitleExt"
        }
        else
        {
            Rename-Item -LiteralPath $Subtitles[$i * 2].FullName -NewName "$($Videos[$i].BaseName).tc.$SubtitleExt"
            Rename-Item -LiteralPath $Subtitles[$i * 2 + 1].FullName -NewName "$($Videos[$i].BaseName).sc.$SubtitleExt"
        }
    }
}
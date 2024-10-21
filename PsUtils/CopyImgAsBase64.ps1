[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Path,

    [Parameter()]
    [ValidateSet('Raw', 'Markdown', 'HTML')]
    [string]
    $Format = 'Raw',
    
    [string]
    $Title
)

$File = Get-Item $Path
if ($Format -ne 'Raw')
{
    switch ($File.Extension)
    {
        '.png' { $MIME = 'image/png'; break; }
        '.gif' { $MIME = 'image/gif'; break; }
        '.jpg' { $MIME = 'image/jpeg'; break; }
        '.jpeg' { $MIME = 'image/jpeg'; break; }
        '.webp' { $MIME = 'image/webp'; break; }
        Default
        {
            Write-Host 'Unknown image type. Possible wrong MIME.'
            $MIME = "image/$($File.Extension.Substring(1))"
        }
    }
}
$b64 = [convert]::ToBase64String([System.IO.File]::ReadAllBytes($Path))

if([string]::IsNullOrEmpty($Title)) { $Title = $File.BaseName }
switch ($Format) {
    'Raw' { Set-Clipboard -Value $b64; return; }
    'Markdown' { Set-Clipboard -Value "![$Title](data:$MIME;base64,$b64)"; return; }
    'HTML' { Set-Clipboard -Value "<img src=""data:$MIME;base64,$b64"" alt=""$Title"""; return; }
    Default {}
}
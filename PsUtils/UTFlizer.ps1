# All file operations are based on .NET in this script
# So DO NOT escape '[' & ']'

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline)]
    [string]
    $Path,

    [float]
    [ValidateRange(0, 1)]
    $Threshold = 0.8,

    [switch]
    $Overwrite
)

function ConvertTo-UTF8
{
    param (
        [string]
        $File,

        [string]
        $EncodingName
    )
    
    $Encoding = [System.Text.Encoding]::GetEncoding($EncodingName)
    if ($Overwrite)
    {
        $NewFile = $File + '.tmp'
    }
    else
    {
        $NewFile = $File.Substring(0, $File.LastIndexOf('.')) + '-UTF8' + $File.Substring($File.LastIndexOf('.'))
    }
    try
    {
        $sr = New-Object System.IO.StreamReader -ArgumentList @($File, $Encoding, $false)
        $sw = New-Object System.IO.StreamWriter -ArgumentList @($NewFile, $false, [System.Text.Encoding]::UTF8)
        $buffer = New-Object char[] -ArgumentList (1024)
        [int] $charsRead = 0
        while (($charsRead = $sr.ReadBlock($buffer, 0, $buffer.Length)) -gt 0)
        {
            $sw.Write($buffer, 0, $charsRead);
        }
    }
    catch
    {
        "Error Happened During Converting File"
        $_
        $sr.Dispose()
        $sw.Dispose()
    }
    $sr.Dispose()
    $sw.Dispose()
    if ($Overwrite)
    {
        [System.IO.File]::Delete($File)
        [System.IO.File]::Move($NewFile, $File)
    }
}

"Processing file: $path"

# Load Ude.dll
# https://github.com/errepi/ude
$UdeDll = Resolve-Path $PSScriptRoot\..\Bin\Ude.dll
[Reflection.Assembly]::LoadFrom($UdeDll) | Out-Null

$fs = [System.IO.File]::OpenRead($path)
$cdet = New-Object Ude.CharsetDetector
$cdet.Feed($fs);
$cdet.DataEnd();
if ($null -ne $cdet.Charset)
{
    if ($cdet.Confidence -lt $Threshold)
    {
        "Untrustable detection: {0} @ {1}" -f $cdet.Charset, $cdet.Confidence
        if ((Read-Host -Prompt 'Continue conversion? Y/N') -in @('y', 'Y'))
        {
            ConvertTo-UTF8 -File $path -EncodingName $cdet.Charset
        }
    }
    elseif ($cdet.Charset -ne 'UTF-8')
    {
        "Trustable detection: {0} @ {1}" -f $cdet.Charset, $cdet.Confidence
        ConvertTo-UTF8 -File $path -EncodingName $cdet.Charset
    }
    else
    {
        "UTF-8 File. No need for conversion."
    }
}
else
{
    "Detection failed. No action is done.";
}
$fs.Dispose()
"Process Completed"
""
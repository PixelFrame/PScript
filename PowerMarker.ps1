param 
(
    [parameter(Mandatory = $true)]
    [string]
    $MarkdownFile,

    [string]
    $CssFile
)

function ConvertLine([string]$line)
{
    $result = ""
    $line = $line.TrimStart()
}
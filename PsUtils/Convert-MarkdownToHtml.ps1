# Using Markdig to perform Markdown to HTML conversion, of course the built-in cmdlet ConvertFrom-Markdown should do the same
# Create a full HTML document
# Embed CSS to HTML

[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [string]
    $MarkdownDocument,

    [string]
    $CSS,

    [string]
    $Title
)

$HtmlTemplate = @'
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>@Title</title>
    <style type="text/css">
        @CSS
    </style>
</head>
<body>
    <div class="markdown">
        @MarkdownHtml
    </div>
</body>
'@

$MarkdigDll = Resolve-Path $PSScriptRoot\..\Bin\Markdig.dll
[Reflection.Assembly]::LoadFrom($MarkdigDll)

$MarkdownHtml = [Markdig.Markdown]::ToHtml($MarkdownDocument)

$Result = $HtmlTemplate.Replace('@Title', $Title).Replace('@CSS',$CSS).Replace('@MarkdownHtml', $MarkdownHtml)
$Result | Out-File "$PSScriptRoot\$Title.html"
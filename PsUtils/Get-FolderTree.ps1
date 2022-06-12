[CmdletBinding()]
param (
    [Parameter()] [string] $Path = $PSScriptRoot
)

$Script:IndentFileNosub = '    '
$Script:IndentFileSub = '│   '
$Script:IndentDirLast = '└───'
$Script:IndentDirMid = '├───'

function GenerateTree
{
    param (
        [ref] $BuilderRef,
        [string] $CurrentDir,
        [string] $Indent = '',
        [int] $DirType = 0
    )
    
    $CurrentDirName = (Get-Item $CurrentDir).Name
    $SubFiles = Get-ChildItem $CurrentDir -File -Force
    $SubDirs = Get-ChildItem $CurrentDir -Directory -Force
    
    switch ($DirType)
    {
        0 { $IndentDir = ''; }
        1 { $IndentDir = $Script:IndentDirMid; $IndentNext = $Script:IndentFileSub }
        2 { $IndentDir = $Script:IndentDirLast; $IndentNext = $Script:IndentFileNosub }
        Default {}
    }
    $BuilderRef.Value.AppendLine($Indent + $IndentDir + $CurrentDirName) | Out-Null
    if ($SubDirs.Count -gt 0) { $IndentFile = $IndentNext + $Script:IndentFileSub }
    else { $IndentFile = $IndentNext + $Script:IndentFileNosub }
    if ($SubFiles.Count -gt 0)
    {
        foreach ($SubFile in $SubFiles)
        {
            $BuilderRef.Value.AppendLine($Indent + $IndentFile + $SubFile.Name + " | $($SubFile.Mode) | $($SubFile.LastWriteTimeUtc)") | Out-Null
        }
        $BuilderRef.Value.AppendLine($Indent + $IndentFile) | Out-Null
    }
    if ($SubDirs.Count -gt 0)
    { 
        for ($i = 0; $i -lt $SubDirs.Count - 1; $i++)
        {
            GenerateTree -BuilderRef $BuilderRef -CurrentDir $SubDirs[$i] -Indent ($Indent + $IndentNext) -DirType 1
        }
        GenerateTree -BuilderRef $BuilderRef  -CurrentDir $SubDirs[$SubDirs.Count - 1] -Indent ($Indent + $IndentNext) -DirType 2
    }
}

$sb = New-Object System.Text.StringBuilder 
GenerateTree -BuilderRef ([ref]$sb) -CurrentDir $Path
$sb.ToString()
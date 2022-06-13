[CmdletBinding()]
param (
    [Parameter()] [string] $Path = $PSScriptRoot,
    [Parameter()] [string] $Output = '',
    [switch] $FileProp,
    [switch] $DirProp
)

$Script:IndentFileNosub = '    '
$Script:IndentFileSub = '│   '
$Script:IndentDirLast = '└───'
$Script:IndentDirMid = '├───'

function GenerateTree
{
    param (
        [string] $CurrentDir,
        [string] $Indent = '',
        [int] $DirType = 0
    )
    
    $CurrentDir = $CurrentDir.Replace('[', '`[').Replace(']', '`]')
    $CurrentDirObj = Get-Item $CurrentDir -Force
    $SubFiles = Get-ChildItem $CurrentDir -File -Force
    $SubDirs = Get-ChildItem $CurrentDir -Directory -Force
    
    switch ($DirType)
    {
        0 { $IndentDir = ''; }
        1 { $IndentDir = $Script:IndentDirMid; $IndentNext = $Script:IndentFileSub }
        2 { $IndentDir = $Script:IndentDirLast; $IndentNext = $Script:IndentFileNosub }
        Default {}
    }
    if ($DirProp) { Write-Output ($Indent + $IndentDir + $CurrentDirObj.Name + " | $($CurrentDirObj.Mode) | $($CurrentDirObj.CreationTimeUtc) | $($CurrentDirObj.LastWriteTimeUtc)") }
    else
    { Write-Output ($Indent + $IndentDir + $CurrentDirObj.Name) }
    if ($SubDirs.Count -gt 0) { $IndentFile = $IndentNext + $Script:IndentFileSub }
    else { $IndentFile = $IndentNext + $Script:IndentFileNosub }
    if ($SubFiles.Count -gt 0)
    {
        foreach ($SubFile in $SubFiles)
        {
            if ($FileProp) { Write-Output ($Indent + $IndentFile + $SubFile.Name + " | $($SubFile.Length) | $($SubFile.Mode)  | $($SubFile.CreationTimeUtc) | $($SubFile.LastWriteTimeUtc)") }
            else { Write-Output ($Indent + $IndentFile + $SubFile.Name) }
        }
        Write-Output ($Indent + $IndentFile)
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

GenerateTree -CurrentDir $Path
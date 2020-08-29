[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $SourcePath,

    [Parameter(Mandatory = $true)]
    [string]
    $DestPath
)

function SyncFolder
{
    param (
        [string] $SourceFolder,
        [string] $DestFolder
    )
    

}

function SyncFile
{
    param (
        [string] $SourceFile,
        [string] $DestFile
    )
    if (Test-Path $DestFile)
    {
        $SourceHash = Get-FileHash $SourceFile
        $DestHash = Get-FileHash $DestFile
        if ($DestHash -ne $SourceHash)
        {
            Copy-Item $SourceFile $DestFile -Force
            "Copied $Source"
        }
        else
        {
            "Skipped $Source"
        }
    }
    else
    {
        Copy-Item $SourceFile $DestFile -Force
        "Copied $Source"
    }
}

$SourceFiles = Get-ChildItem -Path $SourcePath
$DestPath = Get-ChildItem -Path $DestPath


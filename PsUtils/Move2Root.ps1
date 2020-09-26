function Move2Parent
{
    #Requires -Version 6.0
    
    param (
        [string] $Path,
        [bool] $IsRoot = $false
    )

    #! Escape [], only works on PowerShell Core due to bug of Get-ChildItem on Windows PowerShell
    $Path = $Path.Replace('[', '`[')
    $Path = $Path.Replace(']', '`]')
    $child = Get-ChildItem $Path
    if ($child.Count -eq 1 -and $child[0].GetType().Name -eq 'DirectoryInfo')
    {
        Move2Parent -Path $child[0]
    }
    if ($IsRoot -eq $false)
    {
        Move-Item -Path $child -Destination $Path\.. -Confirm:$true -ErrorAction SilentlyContinue
        Remove-Item -Path $Path -Confirm:$true
    }
}

$RootFolders = Get-ChildItem -Directory .\
foreach ($RootFolder in $RootFolders)
{
    Move2Parent -Path $RootFolder -IsRoot $true
}
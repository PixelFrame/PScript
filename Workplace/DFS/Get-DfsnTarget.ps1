Get-DfsnRoot | Get-DfsnRootTarget
Get-DfsnRoot | ForEach-Object {
    Get-DfsnFolder -Path "$_\*" | Get-DfsnFolderTarget
}
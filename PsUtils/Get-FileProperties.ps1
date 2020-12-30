# function Get-FileProperties
# {
param (
    [Parameter()]
    [string]
    $Path
)

$Item = Get-Item $Path -ErrorAction Stop
$ShellObj = New-Object -com Shell.Application
    
if ($Item.GetType().ToString() -eq 'System.IO.DirectoryInfo')
{
    $Folder = $ShellObj.NameSpace($Item.ToString())
    $Folder.Self.InvokeVerb("Properties")
}
elseif ($Item.GetType().ToString() -eq 'System.IO.FileInfo')
{
    $Folder = $ShellObj.NameSpace($Item.Directory.ToString())
    $File = $Folder.ParseName($Item.Name)
    $File.InvokeVerb("Properties")
}
else
{
    throw 'Not a FileSystem Item!'
}
# }
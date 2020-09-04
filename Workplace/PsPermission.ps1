$Path = C:\Temp

$AclObj = Get-Acl -Path $Path
$AclAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SHLTH\Domain Admins", "FullControl", "Allow")
$AclObj.AddAccessRule($AclAccessRule)
$AclObj | Set-Acl $Path


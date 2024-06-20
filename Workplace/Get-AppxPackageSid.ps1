[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $PackageFamilyName = 'MSTeams_8wekyb3d8bbwe'
)

$PInvokeDef = @'
using System;
using System.Runtime.InteropServices;

public class Win32API {
    [DllImport("userenv.dll", CharSet = CharSet.Unicode)]
    public static extern int DeriveAppContainerSidFromAppContainerName(string appContainerName, out IntPtr pSid);

    [DllImport("advapi32.dll")]
    public static extern IntPtr FreeSid(IntPtr pSid);
}
'@

Add-Type -TypeDefinition $PInvokeDef -ErrorAction Stop

[System.IntPtr] $pSid = [System.IntPtr]::Zero
$HRES = [Win32API]::DeriveAppContainerSidFromAppContainerName($PackageFamilyName, [ref]$pSid)
if ($HRES -ne 0)
{
    throw "Fail to get app container SID with HRESULT $HRES"
}
else
{
    $Sid = [System.Security.Principal.SecurityIdentifier]::new($pSid)
    [Win32API]::FreeSid($pSid) | Out-Null # Free unmanaged memory
    $Sid.Value
}
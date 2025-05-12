[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$AccountName
)

$Win32 = @"
using System;
using System.Runtime.InteropServices;

public class ADVAPI32
{
    [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)][return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool LookupAccountName(
        string lpSystemName,
        string lpAccountName,
        IntPtr Sid,
        ref uint cbSid,
        IntPtr ReferencedDomainName,
        ref uint cchReferencedDomainName,
        out SID_NAME_USE peUse
    );

    [DllImport("Advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)][return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ConvertSidToStringSid(
        IntPtr Sid,
        out string StringSid
    );

    public enum SID_NAME_USE
    {
        SidTypeUser = 1,
        SidTypeGroup,
        SidTypeDomain,
        SidTypeAlias,
        SidTypeWellKnownGroup,
        SidTypeDeletedAccount,
        SidTypeInvalid,
        SidTypeUnknown,
        SidTypeComputer
    }
}
"@

Add-Type -TypeDefinition $Win32 -Language CSharp -ErrorAction SilentlyContinue

$Sid = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(1024)
$cbSid = 1024
$ReferencedDomainName = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(2048)
$cchReferencedDomainName = 1024
$peUse = [ADVAPI32+SID_NAME_USE]::SidTypeUser

$Result = [ADVAPI32]::LookupAccountName(
    $null,
    $AccountName,
    $Sid,
    [ref]$cbSid,
    $ReferencedDomainName,
    [ref]$cchReferencedDomainName,
    [ref]$peUse
)

if (!$Result) {
    throw "LookupAccountName failed with error code: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())"
}

$StringSid = ""
$Result = [ADVAPI32]::ConvertSidToStringSid($Sid, [ref]$StringSid)
if (!$Result) {
    throw "ConvertSidToStringSid failed with error code: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())"
}

$Output = @{
    SID    = $StringSid;
    Type   = $peUse;
    Domain = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ReferencedDomainName)
}

[System.Runtime.InteropServices.Marshal]::FreeHGlobal($Sid)
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($ReferencedDomainName)

return $Output
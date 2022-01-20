[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline, Mandatory = $true)]
    [Object]
    $SDDL
)

[Flags()] 
enum SdAceAccessMask
{
    FILE_READ_DATA = 0x1;
    FILE_WRITE_DATA = 0x2;
    FILE_APPEND_DATA = 0x4;
    FILE_READ_EA = 0x8;
    FILE_WRITE_EA = 0x10;
    FILE_EXECUTE_OR_TRAVERSE = 0x20;
    FILE_DELETE_CHILD = 0x40;
    FILE_READ_ATTRIBUTES = 0x80;
    FILE_WRITE_ATTRIBUTES = 0x100;
    DELETE = 0x10000;
    READ_CONTROL = 0x20000;
    WRITE_DAC = 0x40000;
    WRITE_OWNER = 0x80000;
    SYNCHRONIZE = 0x100000;
    ACCESS_SYSTEM_SECURITY = 0x1000000;
    MAXIMUM_ALLOWED = 0x2000000;
    GENERIC_ALL = 0x10000000;
    GENERIC_EXECUTE = 0x20000000;
    GENERIC_WRITE = 0x40000000;
    GENERIC_READ = 0x80000000;
}

[Flags()]
enum SdAceFlags
{
    OBJECT_INHERIT_ACE = 0x1;
    CONTAINER_INHERIT_ACE = 0x2;
    NO_PROPAGATE_INHERIT_ACE = 0x4;
    INHERIT_ONLY_ACE = 0x8;
    INHERITED_ACE = 0x10;
    SUCCESSFUL_ACCESS_ACE_FLAG = 0x40;
    FAILED_ACCESS_ACE_FLAG = 0x80;
}

enum SdAceType
{
    Allowed = 0;
    Denied = 1;
    Audit = 2;
}

class SdAce
{
    [SdAceAccessMask] $AccessMask;
    [SdAceFlags] $AceFlags;
    [SdAceType] $AceType;
    [string] $Trustee;

    SdAce($CimAce)
    {
        $this.AccessMask = $CimAce.AccessMask;
        $this.AceFlags = $CimAce.AceFlags;
        $this.AceType = $CimAce.AceType;
        $this.Trustee = "$($CimAce.Trustee.SIDString) ($($CimAce.Trustee.Domain)\$($CimAce.Trustee.Name))"
    }

    [string] ToString()
    {
        return "$($this.AceType)  $($this.Trustee)  ($($this.AccessMask))  ($($this.AceFlags))"
    }
}

$Win32SD = (Invoke-CimMethod -ClassName Win32_SecurityDescriptorHelper -MethodName SDDLToWin32SD -Namespace root/CIMV2 -Arguments @{ SDDL=$SDDL }).Descriptor
@"
Owner: $($Win32SD.Owner.SIDString) ($($Win32SD.Owner.Domain)\$($Win32SD.Owner.Name))
Group: $($Win32SD.Group.SIDString) ($($Win32SD.Group.Domain)\$($Win32SD.Group.Name))
DACL:
"@
$DACL = @()
$Win32SD.DACL | ForEach-Object {
    $DACL += [SdAce]$_
}
$DACL | Format-Table AceType, Trustee, AccessMask, AceFlags
"SACL:"
$SACL = @()
$Win32SD.SACL | ForEach-Object {
    $SACL += [SdAce]$_
}
$SACL | Format-Table AceType, Trustee, AccessMask, AceFlags

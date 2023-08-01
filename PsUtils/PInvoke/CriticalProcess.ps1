$PInvokeProcessIsCritical = @'
using System;
using System.Runtime.InteropServices;

public class Win32API{
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern uint RtlSetProcessIsCritical(bool bNew, ref bool pbOld, bool bNeedScb);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool IsProcessCritical(IntPtr hProcess, out bool critical);
}
'@

Add-Type -TypeDefinition $PInvokeProcessIsCritical -ErrorAction Stop

function SetPsCritical
{
    $bOld = $false
    $bNeedScb = $false
    $result = [Win32API]::RtlSetProcessIsCritical($true, [ref]$bOld, $bNeedScb)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($result -ne 0)
    { 
        Write-Host "Set process critical failed! Win32 Error $err" -ForegroundColor Red 
    }
    else 
    {
        Write-Host "PowerShell Process is CRITICAL! Termination of this process will cause bugcheck 0xEF!" -ForegroundColor Green
    }
}

function UnsetPsCritical
{
    $bOld = $true
    $bNeedScb = $false
    $result = [Win32API]::RtlSetProcessIsCritical($false, [ref]$bOld, $bNeedScb)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($result -ne 0)
    {
        Write-Host "Unset process critical failed! Win32 Error $err" -ForegroundColor Red
    }
    else 
    {
        Write-Host "PowerShell Process is now not critical." -ForegroundColor Green
    }
}

function IsProcessCritical
{
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = "ProcessId")]
        [uint] $ProcessID
    )

    $handle = [System.Diagnostics.Process]::GetProcessById($ProcessID).Handle
    $critical = $false
    $result = [Win32API]::IsProcessCritical($handle, [ref]$critical)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if (!$result) { Write-Host "Query process critical failed! Win32 Error $err" -ForegroundColor Red }
    return $critical
}
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)] [UInt32] $ProcessId,
    [Parameter(Mandatory=$true)] [string] [ValidateSet('HIDE','SHOWNORMAL','SHOWMINIMIZED','SHOWMAXIMIZED')] $Status
)

$CsDef = @'
using System;
using System.Runtime.InteropServices;

public class Win32Window
{
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] 
    public static extern IntPtr GetForegroundWindow();
}

'@

Add-Type -TypeDefinition $CsDef -ErrorAction SilentlyContinue

enum WindowStatus {
    HIDE = 0;
    SHOWNORMAL = 1;
    SHOWMINIMIZED = 2;
    SHOWMAXIMIZED = 3;
    SHOWNOACTIVATE = 4;
    RESTORE = 9;
    SHOWDEFAULT = 10;
}

$hMWin = (Get-Process -PID $ProcessId).MainWindowHandle
[Win32Window]::ShowWindowAsync($hMWin, [WindowStatus]::$Status)
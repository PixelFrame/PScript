$PInvokeSetDpiAwareness = @'
using System;
using System.Runtime.InteropServices;

public class Win32API{
    [DllImport("SHCore.dll", SetLastError = true)]
    public static extern bool SetProcessDpiAwareness(uint awareness);
    
    [DllImport("kernel32.dll")]
    public static extern uint GetLastError();
}
'@
Add-Type -TypeDefinition $PInvokeSetDpiAwareness -ErrorAction Stop
if ($SetDpiResult = [Win32API]::SetProcessDpiAwareness(2)) { Write-Host "Set DPI awareness failed! $SetDpiResult" -ForegroundColor Red }
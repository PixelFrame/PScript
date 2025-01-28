$Win32 = @'
using System;
using System.Runtime.InteropServices;

public enum WSC_SECURITY_PROVIDER_HEALTH
{
    WSC_SECURITY_PROVIDER_HEALTH_GOOD = 0,
    WSC_SECURITY_PROVIDER_HEALTH_NOTMONITORED = 1,
    WSC_SECURITY_PROVIDER_HEALTH_POOR = 2,
    WSC_SECURITY_PROVIDER_HEALTH_SNOOZE = 3,
}

public class WSCAPI
{
    [DllImport("Wscapi.dll")] 
    public static extern UInt32 WscGetSecurityProviderHealth(UInt32 Providers, ref WSC_SECURITY_PROVIDER_HEALTH pHealth);
}
'@

Add-Type -TypeDefinition $Win32 -ErrorAction SilentlyContinue

[WSC_SECURITY_PROVIDER_HEALTH] $health = [WSC_SECURITY_PROVIDER_HEALTH]::WSC_SECURITY_PROVIDER_HEALTH_GOOD
$hr = [WSCAPI]::WscGetSecurityProviderHealth(1, [ref]$health)
if ($hr -ne 0) { "WscGetSecurityProviderHealth call failed with $hr, health state is $health" }
else { "Health state is $health" }
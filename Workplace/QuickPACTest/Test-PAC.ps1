[CmdletBinding()]
param (
    [string] $Url = 'http://www.microsoft.com',
    [int][ValidateRange(1, 65535)] $Port = 8080
)

function PrintProxyInfo
{
    param (
        [WINHTTP_PROXY_INFO]
        $ProxyInfo
    )
    "    Access Type  : {0}" -f $ProxyInfo.dwAccessType 
    "    Proxy Server : {0}" -f $ProxyInfo.lpszProxy 
    "    Bypass List  : {0}" -f $ProxyInfo.lpszProxyBypass 
}

$Binding = "http://localhost:$Port/"

if (Test-Path $PSScriptRoot\Start-WebServer_EXTERNAL.ps1)
{
    Start-Process -FilePath PowerShell.exe -ArgumentList @("-File $PSScriptRoot\Start-WebServer_EXTERNAL.ps1 -BINDING $Binding") -WindowStyle Hidden
}
else
{
    $WebSrvScriptUrl = 'https://gallery.technet.microsoft.com/scriptcenter/Powershell-Webserver-74dcf466/file/162511/3/Start-WebServer.ps1'
    $WebSrvScript = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $WebSrvScriptUrl).Content).Replace('".avi"="video/x-msvideo"', '".pac"="application/x-ns-proxy-autoconfig"; ".avi"="video/x-msvideo"')
    $WebSrvScript | Out-File $PSScriptRoot\Start-WebServer_EXTERNAL.ps1
    Start-Process -FilePath PowerShell.exe -ArgumentList @("-File $PSScriptRoot\Start-WebServer_EXTERNAL.ps1 -BINDING $Binding") -WindowStyle Hidden
}

while ((Invoke-WebRequest -Uri $Binding).StatusCode -ne 200)
{
    'Waiting for local web server start...'
    Start-Sleep -Seconds 1
}

$PacUrl = $Binding + 'Test.pac'

$Win32CallDef = @'
    using System;
    using System.Runtime.InteropServices;

    public class WinHttp
    {
        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr WinHttpOpen(
            string pwszAgentW,
            AccessType dwAccessType,
            string pwszProxyW,
            string pwszProxyBypassW,
            OpenFlag dwFlags);

        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool WinHttpGetProxyForUrl(
            IntPtr hSession,
            string lpcwszUrl,
            ref WINHTTP_AUTOPROXY_OPTIONS pAutoProxyOptions,
            ref WINHTTP_PROXY_INFO pProxyInfo);

        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool WinHttpGetDefaultProxyConfiguration(ref WINHTTP_PROXY_INFO pProxyInfo);

        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool WinHttpGetIEProxyConfigForCurrentUser(ref WINHTTP_CURRENT_USER_IE_PROXY_CONFIG pProxyInfo);

        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool WinHttpDetectAutoProxyConfigUrl(
            AutoDetectFlag dwAutoDetectFlags,
            ref string ppwstrAutoConfigUrl);

        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int WinHttpResetAutoProxy(
            IntPtr hSession,
            ResetFlag dwFlags);

        [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool WinHttpCloseHandle(IntPtr hInternet);
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WINHTTP_AUTOPROXY_OPTIONS
    {
        public AutoProxyFlag dwFlags;
        public AutoDetectFlag dwAutoDetectFlags;
        public string lpszAutoConfigUrl;
        public IntPtr lpvReserved;
        public int dwReserved;
        public bool fAutoLogonIfChallenged;
    }

    [Flags]
    public enum AccessType
    {
        WINHTTP_ACCESS_TYPE_NO_PROXY = 0x1,
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0x0,
        WINHTTP_ACCESS_TYPE_NAMED_PROXY = 0x3,
        WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY = 0x4
    }

    [Flags]
    public enum OpenFlag
    {
        WINHTTP_FLAG_ASYNC = 0x10000000,
        WINHTTP_FLAG_SECURE_DEFAULTS = 0x30000000
    }

    [Flags]
    public enum AutoProxyFlag
    {
        WINHTTP_AUTOPROXY_AUTO_DETECT = 0x00000001,
        WINHTTP_AUTOPROXY_CONFIG_URL = 0x00000002,
        WINHTTP_AUTOPROXY_HOST_KEEPCASE = 0x00000004,
        WINHTTP_AUTOPROXY_HOST_LOWERCASE = 0x00000008,
        WINHTTP_AUTOPROXY_ALLOW_AUTOCONFIG = 0x00000100,
        WINHTTP_AUTOPROXY_ALLOW_STATIC = 0x00000200,
        WINHTTP_AUTOPROXY_ALLOW_CM = 0x00000400,
        WINHTTP_AUTOPROXY_RUN_INPROCESS = 0x00010000,
        WINHTTP_AUTOPROXY_RUN_OUTPROCESS_ONLY = 0x00020000,
        WINHTTP_AUTOPROXY_NO_DIRECTACCESS = 0x00040000,
        WINHTTP_AUTOPROXY_NO_CACHE_CLIENT = 0x00080000,
        WINHTTP_AUTOPROXY_NO_CACHE_SVC = 0x00100000
    }

    [Flags]
    public enum AutoDetectFlag
    {
        WINHTTP_AUTO_DETECT_TYPE_DHCP = 0x00000001,
        WINHTTP_AUTO_DETECT_TYPE_DNS_A = 0x00000002
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WINHTTP_PROXY_INFO
    {
        public AccessType dwAccessType;
        public string lpszProxy;
        public string lpszProxyBypass;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WINHTTP_CURRENT_USER_IE_PROXY_CONFIG
    {
        public bool fAutoDetect;
        public string lpszAutoConfigUrl;
        public string lpszProxy;
        public string lpszProxyBypass;
    }

    [Flags]
    public enum ResetFlag
    {
        WINHTTP_RESET_STATE = 0x00000001,
        WINHTTP_RESET_SWPAD_CURRENT_NETWORK = 0x00000002,
        WINHTTP_RESET_SWPAD_ALL = 0x00000004,
        WINHTTP_RESET_SCRIPT_CACHE = 0x00000008,
        WINHTTP_RESET_ALL = 0x0000FFFF,
        WINHTTP_RESET_NOTIFY_NETWORK_CHANGED = 0x00010000,
        WINHTTP_RESET_OUT_OF_PROC = 0x00020000,
        WINHTTP_RESET_DISCARD_RESOLVERS = 0x00040000
    }
'@

Add-Type -TypeDefinition $Win32CallDef -ErrorAction Stop

Write-Host "`nWinHttpGetProxyForUrl with Manual PAC" -ForegroundColor Blue

$SessionHandle = [WinHttp]::WinHttpOpen("PWSH PINVOKE WINHTTP CLIENT/1.0", [AccessType]::WINHTTP_ACCESS_TYPE_NO_PROXY, "", "", 0);

$AutoProxyOptions = New-Object WINHTTP_AUTOPROXY_OPTIONS
$AutoProxyOptions.dwFlags = [AutoProxyFlag]::WINHTTP_AUTOPROXY_CONFIG_URL
$AutoProxyOptions.lpszAutoConfigUrl = $PacUrl
$AutoProxyOptions.fAutoLogonIfChallenged = $true

$ProxyInfo = New-Object WINHTTP_PROXY_INFO

if ([WinHttp]::WinHttpGetProxyForUrl($SessionHandle, $Url, [ref] $AutoProxyOptions, [ref] $ProxyInfo))
{
    PrintProxyInfo $ProxyInfo
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    Win32 Call: WinHttpGetProxyForUrl Manual PAC Failed. Error Code: $ErrorCode"
}

[WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null

Pause

Invoke-WebRequest -Uri "$Binding/quit" | Out-Null
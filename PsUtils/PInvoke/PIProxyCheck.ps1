[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [string]
    $Url = $null
)

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
        WINHTTP_AUTOPROXY_NO_CACHE_SVC = 0x00100000,
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
'@

Add-Type -TypeDefinition $Win32CallDef -ErrorAction SilentlyContinue

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

function PrintIEProxyConfig
{
    param (
        [WINHTTP_CURRENT_USER_IE_PROXY_CONFIG]
        $IEProxyConfig
    )
    
    if ($IEProxyConfig.fAutoDetect) { "    Auto Detect     : True" }
    else { "    Auto Detect     : False" }
    "    Auto Config URL : {0}" -f $IEProxyConfig.lpszAutoConfigUrl
    "    Proxy Server    : {0}" -f $IEProxyConfig.lpszProxy 
    "    Bypass List     : {0}" -f $IEProxyConfig.lpszProxyBypass 
}

Write-Host "`nWinINET Proxy" -ForegroundColor Blue
$IEProxyConfig = New-Object WINHTTP_CURRENT_USER_IE_PROXY_CONFIG
$IEPacAddr = $null
if ([WinHttp]::WinHttpGetIEProxyConfigForCurrentUser([ref] $IEProxyConfig))
{
    PrintIEProxyConfig $IEProxyConfig
    $IEPacAddr = $IEProxyConfig.lpszAutoConfigUrl
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    Win32 Call: WinHttpGetIEProxyConfigForCurrentUser Failed. Error Code: $ErrorCode`n"
}

Write-Host "`nWinHTTP Proxy" -ForegroundColor Blue
$WinHttpDefaultProxyInfo = New-Object WINHTTP_PROXY_INFO
if ([WinHttp]::WinHttpGetDefaultProxyConfiguration([ref] $WinHttpDefaultProxyInfo)) 
{
    PrintProxyInfo $WinHttpDefaultProxyInfo
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    Win32 Call: WinHttpGetDefaultProxyConfiguration Failed. Error Code: $ErrorCode`n"
}

Write-Host "`nAuto Proxy" -ForegroundColor Blue
$WpadAddr = ""
$AutoProxyAvailable = $false
if ([WinHttp]::WinHttpDetectAutoProxyConfigUrl([AutoDetectFlag]::WINHTTP_AUTO_DETECT_TYPE_DHCP, [ref]$WpadAddr)) 
{
    $AutoProxyAvailable = $true
    "    DHCP WPAD Address: $WpadAddr"
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    No DHCP WPAD Detected. Code: $ErrorCode"
}
if ([WinHttp]::WinHttpDetectAutoProxyConfigUrl([AutoDetectFlag]::WINHTTP_AUTO_DETECT_TYPE_DNS_A, [ref]$WpadAddr)) 
{
    $AutoProxyAvailable = $true
    "    DNS WPAD Address: $WpadAddr"
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    No DNS WPAD Detected. Code: $ErrorCode"
}

if ($Url.Length -gt 0)
{
    if ($AutoProxyAvailable)
    {
        Write-Host "`nWinHttpGetProxyForUrl with Auto Proxy" -ForegroundColor Blue

        $SessionHandle = [WinHttp]::WinHttpOpen("PINVOKE WINHTTP CLIENT/1.0", [AccessType]::WINHTTP_ACCESS_TYPE_NO_PROXY, "", "", 0);

        $AutoProxyOptions = New-Object WINHTTP_AUTOPROXY_OPTIONS
        $AutoProxyOptions.dwFlags = [AutoProxyFlag]::WINHTTP_AUTOPROXY_AUTO_DETECT
        $AutoProxyOptions.dwAutoDetectFlags = [AutoDetectFlag]::WINHTTP_AUTO_DETECT_TYPE_DHCP -bor [AutoDetectFlag]::WINHTTP_AUTO_DETECT_TYPE_DNS_A
        $AutoProxyOptions.fAutoLogonIfChallenged = $true

        $ProxyInfo = New-Object WINHTTP_PROXY_INFO

        if ([WinHttp]::WinHttpGetProxyForUrl($SessionHandle, $Url, [ref] $AutoProxyOptions, [ref] $ProxyInfo))
        {
            PrintProxyInfo $ProxyInfo
        }
        else 
        {
            $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            "    Win32 Call: WinHttpGetProxyForUrl Auto Proxy Failed. Error Code: $ErrorCode"
        }

        [WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null
    }
    if ($null -ne $IEPacAddr)
    {
        Write-Host "`nWinHttpGetProxyForUrl with IE Auto Config URL" -ForegroundColor Blue

        $SessionHandle = [WinHttp]::WinHttpOpen("PINVOKE WINHTTP CLIENT/1.0", [AccessType]::WINHTTP_ACCESS_TYPE_NO_PROXY, "", "", 0);

        $AutoProxyOptions = New-Object WINHTTP_AUTOPROXY_OPTIONS
        $AutoProxyOptions.dwFlags = [AutoProxyFlag]::WINHTTP_AUTOPROXY_CONFIG_URL
        $AutoProxyOptions.lpszAutoConfigUrl = $IEPacAddr
        $AutoProxyOptions.fAutoLogonIfChallenged = $true

        $ProxyInfo = New-Object WINHTTP_PROXY_INFO

        if ([WinHttp]::WinHttpGetProxyForUrl($SessionHandle, $Url, [ref] $AutoProxyOptions, [ref] $ProxyInfo))
        {
            PrintProxyInfo $ProxyInfo
        }
        else 
        {
            $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            "    Win32 Call: WinHttpGetProxyForUrl IE PAC Failed. Error Code: $ErrorCode"
        }

        [WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null
    }
}
""
Pause
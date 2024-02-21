'Setting ProxySettingsPerUser to 0'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\' -Name ProxySettingsPerUser -Value 0 -Type DWord -Force

$Type = 'NamedProxy'
$PacUrl = 'http://abc.com'
$ProxyServer = '10.1.1.1:8080'
$BypassList = '*.contoso.com;<local>'

$MAX_RETRY = 3

$Win32CallDef = @'
using System;
using System.Runtime.InteropServices;

public class WinINET
{
    [DllImport("wininet.dll", SetLastError = true, CharSet = CharSet.Auto)]
    static extern bool InternetSetOption(IntPtr hInternet, OptionFlag dwOption, IntPtr lpBuffer, int dwBufferLength);

    [DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool WinHttpGetIEProxyConfigForCurrentUser(ref WINHTTP_CURRENT_USER_IE_PROXY_CONFIG pProxyInfo);

    public static bool SetNamedProxy(string ProxyServer, string ProxyBypass, ref int Win32Error)
    {
        var list = new INTERNET_PER_CONN_OPTION_LIST();
        var option = new INTERNET_PER_CONN_OPTION[3];

        IntPtr pszProxyServer = Marshal.StringToHGlobalAuto(ProxyServer);
        IntPtr pszProxyBypass = Marshal.StringToHGlobalAuto(ProxyBypass);
        IntPtr pOptions = Marshal.AllocHGlobal(Marshal.SizeOf(option[0]) * 3);
        IntPtr pOption = new IntPtr(pOptions.ToInt64());
        IntPtr pBuffer = Marshal.AllocHGlobal(Marshal.SizeOf(list));

        bool iRes = false;

        try
        {
            option[0].dwOption = PerConnOption.INTERNET_PER_CONN_FLAGS;
            option[0].Value.dwValue = (int)(PerConnFlag.PROXY_TYPE_PROXY | PerConnFlag.PROXY_TYPE_DIRECT);

            option[1].dwOption = PerConnOption.INTERNET_PER_CONN_PROXY_SERVER;
            option[1].Value.pszValue = pszProxyServer;

            option[2].dwOption = PerConnOption.INTERNET_PER_CONN_PROXY_BYPASS;
            option[2].Value.pszValue = pszProxyBypass;

            for (var i = 0; i < 3; i++)
            {
                Marshal.StructureToPtr(option[i], pOption, true);
                pOption = new IntPtr(pOption.ToInt64() + Marshal.SizeOf(option[0]));
            }

            list.dwSize = Marshal.SizeOf(list);
            list.pszConnection = null;
            list.dwOptionCount = 3;
            list.pOptions = pOptions;

            Marshal.StructureToPtr(list, pBuffer, false);

            iRes = InternetSetOption(IntPtr.Zero, OptionFlag.INTERNET_OPTION_PER_CONNECTION_OPTION, pBuffer, Marshal.SizeOf(list));
            Win32Error = Marshal.GetLastWin32Error();
        }
        finally
        {
            Marshal.FreeHGlobal(pszProxyServer);
            Marshal.FreeHGlobal(pszProxyBypass);
            Marshal.FreeHGlobal(pOptions);
            Marshal.FreeHGlobal(pBuffer);
        }
        return iRes;
    }

    public static bool SetPacUrl(string PacUrl, ref int Win32Error)
    {
        var list = new INTERNET_PER_CONN_OPTION_LIST();
        var option = new INTERNET_PER_CONN_OPTION[2];

        IntPtr pszPacUrl = Marshal.StringToHGlobalAuto(PacUrl);
        IntPtr pOptions = Marshal.AllocHGlobal(Marshal.SizeOf(option[0]) * 2);
        IntPtr pOption = new IntPtr(pOptions.ToInt64());
        IntPtr pBuffer = Marshal.AllocHGlobal(Marshal.SizeOf(list));

        bool iRes = false;

        try
        {
            option[0].dwOption = PerConnOption.INTERNET_PER_CONN_FLAGS;
            option[0].Value.dwValue = (int)(PerConnFlag.PROXY_TYPE_AUTO_PROXY_URL | PerConnFlag.PROXY_TYPE_DIRECT);

            option[1].dwOption = PerConnOption.INTERNET_PER_CONN_AUTOCONFIG_URL;
            option[1].Value.pszValue = pszPacUrl;

            for (var i = 0; i < 2; i++)
            {
                Marshal.StructureToPtr(option[i], pOption, true);
                pOption = new IntPtr(pOption.ToInt64() + Marshal.SizeOf(option[0]));
            }

            list.dwSize = Marshal.SizeOf(list);
            list.pszConnection = null;
            list.dwOptionCount = 2;
            list.pOptions = pOptions;

            Marshal.StructureToPtr(list, pBuffer, false);

            iRes = InternetSetOption(IntPtr.Zero, OptionFlag.INTERNET_OPTION_PER_CONNECTION_OPTION, pBuffer, Marshal.SizeOf(list));
            Win32Error = Marshal.GetLastWin32Error();
        }
        finally
        {
            Marshal.FreeHGlobal(pszPacUrl);
            Marshal.FreeHGlobal(pOptions);
            Marshal.FreeHGlobal(pBuffer);
        }
        return iRes;
    }

    public static bool SetAutoDetect(ref int Win32Error)
    {
        var list = new INTERNET_PER_CONN_OPTION_LIST();
        var option = new INTERNET_PER_CONN_OPTION[1];

        IntPtr pOptions = Marshal.AllocHGlobal(Marshal.SizeOf(option[0]));
        IntPtr pBuffer = Marshal.AllocHGlobal(Marshal.SizeOf(list));

        bool iRes = false;

        try
        {
            option[0].dwOption = PerConnOption.INTERNET_PER_CONN_FLAGS;
            option[0].Value.dwValue = (int)(PerConnFlag.PROXY_TYPE_AUTO_DETECT | PerConnFlag.PROXY_TYPE_DIRECT);

            Marshal.StructureToPtr(option[0], pOptions, true);

            list.dwSize = Marshal.SizeOf(list);
            list.pszConnection = null;
            list.dwOptionCount = 1;
            list.pOptions = pOptions;

            Marshal.StructureToPtr(list, pBuffer, false);

            iRes = InternetSetOption(IntPtr.Zero, OptionFlag.INTERNET_OPTION_PER_CONNECTION_OPTION, pBuffer, Marshal.SizeOf(list));
            Win32Error = Marshal.GetLastWin32Error();
        }
        finally
        {
            Marshal.FreeHGlobal(pOptions);
            Marshal.FreeHGlobal(pBuffer);
        }
        return iRes;
    }

    public static bool ResetProxy(ref int Win32Error)
    {
        var list = new INTERNET_PER_CONN_OPTION_LIST();
        var option = new INTERNET_PER_CONN_OPTION[1];

        IntPtr pOptions = Marshal.AllocHGlobal(Marshal.SizeOf(option[0]));
        IntPtr pBuffer = Marshal.AllocHGlobal(Marshal.SizeOf(list));

        bool iRes = false;

        try
        {
            option[0].dwOption = PerConnOption.INTERNET_PER_CONN_FLAGS;
            option[0].Value.dwValue = (int)(PerConnFlag.PROXY_TYPE_DIRECT);

            Marshal.StructureToPtr(option[0], pOptions, true);

            list.dwSize = Marshal.SizeOf(list);
            list.pszConnection = null;
            list.dwOptionCount = 1;
            list.pOptions = pOptions;

            Marshal.StructureToPtr(list, pBuffer, false);

            iRes = InternetSetOption(IntPtr.Zero, OptionFlag.INTERNET_OPTION_PER_CONNECTION_OPTION, pBuffer, Marshal.SizeOf(list));
            Win32Error = Marshal.GetLastWin32Error();
        }
        finally
        {
            Marshal.FreeHGlobal(pOptions);
            Marshal.FreeHGlobal(pBuffer);
        }
        return iRes;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    struct INTERNET_PER_CONN_OPTION_LIST
    {
        public int dwSize;
        public string pszConnection;
        public int dwOptionCount;
        public int dwOptionError;
        public IntPtr pOptions;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    struct INTERNET_PER_CONN_OPTION
    {
        public PerConnOption dwOption;
        public INTERNET_PER_CONN_OPTION_VALUE Value;


        [StructLayout(LayoutKind.Explicit, CharSet = CharSet.Auto)]
        public struct INTERNET_PER_CONN_OPTION_VALUE
        {
            [FieldOffset(0)]
            public int dwValue;
            [FieldOffset(0)]
            public IntPtr pszValue;
            [FieldOffset(0)]
            public System.Runtime.InteropServices.ComTypes.FILETIME ftValue;
        }
    }

    enum OptionFlag
    {
        INTERNET_OPTION_PER_CONNECTION_OPTION = 75,
        INTERNET_OPTION_PROXY = 38
    }

    enum PerConnOption
    {
        INTERNET_PER_CONN_FLAGS = 1,
        INTERNET_PER_CONN_PROXY_SERVER = 2,
        INTERNET_PER_CONN_PROXY_BYPASS = 3,
        INTERNET_PER_CONN_AUTOCONFIG_URL = 4,
        INTERNET_PER_CONN_AUTODISCOVERY_FLAGS = 5,
        INTERNET_PER_CONN_AUTOCONFIG_SECONDARY_URL = 6,
        INTERNET_PER_CONN_AUTOCONFIG_RELOAD_DELAY_MINS = 7,
        INTERNET_PER_CONN_AUTOCONFIG_LAST_DETECT_TIME = 8,
        INTERNET_PER_CONN_AUTOCONFIG_LAST_DETECT_URL = 9,
        INTERNET_PER_CONN_FLAGS_UI = 10,
    }

    enum PerConnFlag
    {
        PROXY_TYPE_DIRECT = 0x00000001,
        PROXY_TYPE_PROXY = 0x00000002,
        PROXY_TYPE_AUTO_PROXY_URL = 0x00000004,
        PROXY_TYPE_AUTO_DETECT = 0x00000008,
    }
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

function PrintResult
{
    if (!$Result)
    {
        "Error happens during operation. Win32 Error Code: $Win32Error"
    }
    else
    {
        "Operation completed successfully"
    }
}

function ValidateResult
{
    [WinINET]::WinHttpGetIEProxyConfigForCurrentUser([ref] $Actual) | Out-Null

    return (($Expected.fAutoDetect -eq $Actual.fAutoDetect) `
            -and ($Expected.lpszAutoConfigUrl -eq $Actual.lpszAutoConfigUrl) `
            -and ($Expected.lpszProxy -eq $Actual.lpszProxy) `
            -and ($Expected.lpszProxyBypass -eq $Actual.lpszProxyBypass))
}

[int] $Win32Error = 0 | Out-Null
$Result = $true | Out-Null

$Attempt = 0
$Validated = $false
$Expected = New-Object WINHTTP_CURRENT_USER_IE_PROXY_CONFIG
$Actual = New-Object WINHTTP_CURRENT_USER_IE_PROXY_CONFIG
while ($Attempt -lt $MAX_RETRY -and !$Validated)
{
    switch ($Type)
    {
        'AutoDetect'
        { 
            $Result = [WinINET]::SetAutoDetect([ref] $Win32Error)
            PrintResult
            $Expected.fAutoDetect = $true
        }
        'NamedProxy'
        {
            if ($BypassList.Length -eq 0)
            {
                $BypassList = '<local>'
            }
            $Result = [WinINET]::SetNamedProxy($ProxyServer, $BypassList, [ref] $Win32Error)
            PrintResult
            $Expected.fAutoDetect = $false
            $Expected.lpszProxy = $ProxyServer
            $Expected.lpszProxyBypass = $BypassList
        }
        'PAC'
        {
            $Result = [WinINET]::SetPacUrl($PacUrl, [ref] $Win32Error)
            PrintResult
            $Expected.fAutoDetect = $false
            $Expected.lpszAutoConfigUrl = $PacUrl
        }
        'Reset'
        {
            $Result = [WinINET]::ResetProxy([ref] $Win32Error)
            PrintResult
            $Expected.fAutoDetect = $false
        }
    }
    $Validated = ValidateResult $Expected
    if ($Validated)
    {
        'Proxy settings validated!'
    }
    else 
    {
        "Proxy settings incorrect! Attempt $Attempt"
        $Attempt++
    }
    if($Attempt -eq $MAX_RETRY)
    {
        Write-Host 'MAX RETRY reached! Please contact support to diagnose the issue!' -ForegroundColor Red
        'Expected proxy setting'
        $Expected
        'Actual proxy setting'
        $Actual
    }
}
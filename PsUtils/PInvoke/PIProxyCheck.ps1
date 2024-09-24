[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [string]
    $Url = 'https://www.example.com/',

    [switch]
    $DownloadPacScript,

    [switch]
    $IncludeSavedLegacySettings,

    [switch]
    $IncludeVPN,

    [switch]
    $IncludeWOW64,

    [switch]
    $IncludeEnv,

    [string]
    $PacUrl
)

#region P/Invoke

$Win32CallDef = @'
    using System;
    using System.Collections.Generic;
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

        public static readonly Dictionary<int, string> ErrorMessage = new Dictionary<int, string>()   // PowerShell 5 (.NET Framework) does not support shorten declaration...
        {
            {12001, "ERROR_WINHTTP_OUT_OF_HANDLES"},
            {12002, "ERROR_WINHTTP_TIMEOUT"},
            {12004, "ERROR_WINHTTP_INTERNAL_ERROR"},
            {12005, "ERROR_WINHTTP_INVALID_URL"},
            {12006, "ERROR_WINHTTP_UNRECOGNIZED_SCHEME"},
            {12007, "ERROR_WINHTTP_NAME_NOT_RESOLVED"},
            {12009, "ERROR_WINHTTP_INVALID_OPTION"},
            {12011, "ERROR_WINHTTP_OPTION_NOT_SETTABLE"},
            {12012, "ERROR_WINHTTP_SHUTDOWN"},
            {12015, "ERROR_WINHTTP_LOGIN_FAILURE"},
            {12017, "ERROR_WINHTTP_OPERATION_CANCELLED"},
            {12018, "ERROR_WINHTTP_INCORRECT_HANDLE_TYPE"},
            {12019, "ERROR_WINHTTP_INCORRECT_HANDLE_STATE"},
            {12029, "ERROR_WINHTTP_CANNOT_CONNECT"},
            {12030, "ERROR_WINHTTP_CONNECTION_ERROR"},
            {12032, "ERROR_WINHTTP_RESEND_REQUEST"},
            {12044, "ERROR_WINHTTP_CLIENT_AUTH_CERT_NEEDED"},
            {12100, "ERROR_WINHTTP_CANNOT_CALL_BEFORE_OPEN"},
            {12101, "ERROR_WINHTTP_CANNOT_CALL_BEFORE_SEND"},
            {12102, "ERROR_WINHTTP_CANNOT_CALL_AFTER_SEND"},
            {12103, "ERROR_WINHTTP_CANNOT_CALL_AFTER_OPEN"},
            {12150, "ERROR_WINHTTP_HEADER_NOT_FOUND"},
            {12152, "ERROR_WINHTTP_INVALID_SERVER_RESPONSE"},
            {12153, "ERROR_WINHTTP_INVALID_HEADER"},
            {12154, "ERROR_WINHTTP_INVALID_QUERY_REQUEST"},
            {12155, "ERROR_WINHTTP_HEADER_ALREADY_EXISTS"},
            {12156, "ERROR_WINHTTP_REDIRECT_FAILED"},
            {12178, "ERROR_WINHTTP_AUTO_PROXY_SERVICE_ERROR"},
            {12166, "ERROR_WINHTTP_BAD_AUTO_PROXY_SCRIPT"},
            {12167, "ERROR_WINHTTP_UNABLE_TO_DOWNLOAD_SCRIPT"},
            {12176, "ERROR_WINHTTP_UNHANDLED_SCRIPT_TYPE"},
            {12177, "ERROR_WINHTTP_SCRIPT_EXECUTION_ERROR"},
            {12172, "ERROR_WINHTTP_NOT_INITIALIZED"},
            {12175, "ERROR_WINHTTP_SECURE_FAILURE"},
            {12037, "ERROR_WINHTTP_SECURE_CERT_DATE_INVALID"},
            {12038, "ERROR_WINHTTP_SECURE_CERT_CN_INVALID"},
            {12045, "ERROR_WINHTTP_SECURE_INVALID_CA"},
            {12057, "ERROR_WINHTTP_SECURE_CERT_REV_FAILED"},
            {12157, "ERROR_WINHTTP_SECURE_CHANNEL_ERROR"},
            {12169, "ERROR_WINHTTP_SECURE_INVALID_CERT"},
            {12170, "ERROR_WINHTTP_SECURE_CERT_REVOKED"},
            {12179, "ERROR_WINHTTP_SECURE_CERT_WRONG_USAGE"},
            {12180, "ERROR_WINHTTP_AUTODETECTION_FAILED"},
            {12181, "ERROR_WINHTTP_HEADER_COUNT_EXCEEDED"},
            {12182, "ERROR_WINHTTP_HEADER_SIZE_OVERFLOW"},
            {12183, "ERROR_WINHTTP_CHUNKED_ENCODING_HEADER_SIZE_OVERFLOW"},
            {12184, "ERROR_WINHTTP_RESPONSE_DRAIN_OVERFLOW"},
            {12185, "ERROR_WINHTTP_CLIENT_CERT_NO_PRIVATE_KEY"},
            {12186, "ERROR_WINHTTP_CLIENT_CERT_NO_ACCESS_PRIVATE_KEY"},
            {12187, "ERROR_WINHTTP_CLIENT_AUTH_CERT_NEEDED_PROXY"},
            {12188, "ERROR_WINHTTP_SECURE_FAILURE_PROXY"},
            {12189, "ERROR_WINHTTP_RESERVED_189"},
            {12190, "ERROR_WINHTTP_HTTP_PROTOCOL_MISMATCH"},
            {12191, "ERROR_WINHTTP_GLOBAL_CALLBACK_FAILED"},
            {12192, "ERROR_WINHTTP_FEATURE_DISABLED"}
        };
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

#endregion

#region Functions

function PrintProxyInfo
{
    param (
        [WINHTTP_PROXY_INFO]
        $ProxyInfo
    )
    Write-Host ("    Access Type  : {0}" -f $ProxyInfo.dwAccessType )
    Write-Host ("    Proxy Server : {0}" -f $ProxyInfo.lpszProxy )
    Write-Host ("    Bypass List  : {0}" -f $ProxyInfo.lpszProxyBypass )
}

function PrintIEProxyConfig
{
    param (
        [WINHTTP_CURRENT_USER_IE_PROXY_CONFIG]
        $IEProxyConfig
    )
    
    if ($IEProxyConfig.fAutoDetect) { "    Auto Detect     : True" }
    else { "    Auto Detect     : False" }
    Write-Host ("    Auto Config URL : {0}" -f $IEProxyConfig.lpszAutoConfigUrl )
    Write-Host ("    Proxy Server    : {0}" -f $IEProxyConfig.lpszProxy )
    Write-Host ("    Bypass List     : {0}" -f $IEProxyConfig.lpszProxyBypass )
}

function PrintIERegs
{
    param (
        $IERegData
    )

    if ($IERegData.Length -eq 0)
    {
        Write-Host ('        No Registry Setting Found' + [System.Environment]::NewLine) -ForegroundColor Red
    }
    else
    {
        foreach ($IEReg in $IERegData)
        {
            Write-Host ('        ' + $IEReg.Path) -ForegroundColor Cyan
            $__ = (ConvertFrom-ProxySettingsBinary $IEReg.Data).Split([System.Environment]::NewLine)
            $output = ''
            foreach ($l in $__)
            {
                $output += '            ' + $l + [System.Environment]::NewLine
            }
            Write-Host $output
        }
    }
    
}

function Get-SubArray
{
    param (
        [byte[]] $Source,
        [int] $StartIndex,
        [int] $Length
    )
    
    $Result = New-Object 'byte[]' -ArgumentList $Length
    [Array]::Copy($Source, $StartIndex, $Result, 0, $Length);
    return $Result
}

function Convert-BytesToUInt32
{
    param (
        [byte[]] $Bytes,
        [bool] $IsBigEndian
    )
    if ($Bytes.Length -gt 4)
    {
        throw 'Byte array too long!'
    }
    if ([BitConverter]::IsLittleEndian -and $IsBigEndian)
    {
        [Array]::Reverse($Bytes); 
    }
    return [BitConverter]::ToUInt32($Bytes, 0);
}

function Convert-SidToUsername
{
    param (
        [string] $Sid
    )
    $objSID = New-Object System.Security.Principal.SecurityIdentifier $Sid 
    try
    { $objUser = $objSID.Translate( [System.Security.Principal.NTAccount]) }
    catch
    { return $Sid }
    return $objUser.Value
}

function ConvertFrom-ProxySettingsBinary
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Byte[]]
        $ProxySettings
    )

    $Output = @()

    if ($ProxySettings.Count -gt 0)
    {
        # Do a smoke test on the binary to check it looks valid
        if ($ProxySettings[0] -ne 0x46)
        {
            Write-Host 'Invalid HEX string' -ForegroundColor Red
        }

        $ProxySettingVersion = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $ProxySettings -StartIndex 4 -Length 4) -IsBigEndian $false
        $Output += "Proxy setting version         : $ProxySettingVersion"

        # Figure out the proxy settings that are enabled
        $proxyBits = $ProxySettings[8]

        if (($proxyBits -band 0x2) -gt 0)
        {
            $Output += "Manual Proxy                  : True"
        }
        else
        {
            $Output += "Manual Proxy                  : False"
        }

        if (($proxyBits -band 0x4) -gt 0)
        {
            $Output += "Auto Configuration URL (PAC)  : True"
        }
        else
        {
            $Output += "Auto Configuration URL (PAC)  : False"
        }

        if (($proxyBits -band 0x8) -gt 0)
        {
            $Output += "Auto Detection                : True"
        }
        else
        {
            $Output += "Auto Detection                : False"
        }

        $stringPointer = 12

        # Extract the Proxy Server string
        $proxyServer = ''
        $stringLength = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $ProxySettings -StartIndex $stringPointer -Length 4) -IsBigEndian $false
        $Output += "Proxy server string length    : $stringLength"
        $stringPointer += 4

        if ($stringLength -gt 0)
        {
            $stringBytes = New-Object -TypeName Byte[] -ArgumentList $stringLength
            $null = [System.Buffer]::BlockCopy($ProxySettings, $stringPointer, $stringBytes, 0, $stringLength)
            $proxyServer = [System.Text.Encoding]::ASCII.GetString($stringBytes)
            $Output += "Proxy server string           : $proxyServer"
            $stringPointer += $stringLength
        }

        # Extract the Proxy Server Exceptions string
        $stringLength = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $ProxySettings -StartIndex $stringPointer -Length 4) -IsBigEndian $false
        $Output += "Bypass list string length     : $stringLength"
        $stringPointer += 4

        if ($stringLength -gt 0)
        {
            $stringBytes = New-Object -TypeName Byte[] -ArgumentList $stringLength
            $null = [System.Buffer]::BlockCopy($ProxySettings, $stringPointer, $stringBytes, 0, $stringLength)
            $proxyServerExceptionsString = [System.Text.Encoding]::ASCII.GetString($stringBytes)
            $Output += "Bypass list string            : $proxyServerExceptionsString"
            $stringPointer += $stringLength
        }

        # Extract the Auto Config URL string
        $autoConfigURL = ''
        $stringLength = Convert-BytesToUInt32 -Bytes (Get-SubArray -Source $ProxySettings -StartIndex $stringPointer -Length 4) -IsBigEndian $false
        $Output += "Auto Config URL string length : $stringLength"
        $stringPointer += 4

        if ($stringLength -gt 0)
        {
            $stringBytes = New-Object -TypeName Byte[] -ArgumentList $stringLength
            $null = [System.Buffer]::BlockCopy($ProxySettings, $stringPointer, $stringBytes, 0, $stringLength)
            $autoConfigURL = [System.Text.Encoding]::ASCII.GetString($stringBytes)
            $Output += "Auto Config URL string        : $autoConfigURL"
            $stringPointer += $stringLength
        }
    }
    return $Output
}

#endregion

#region WinHTTP | API | ResetAutoProxy

$SessionHandle = [WinHttp]::WinHttpOpen("PINVOKE WINHTTP CLIENT/1.0", [AccessType]::WINHTTP_ACCESS_TYPE_NO_PROXY, "", "", 0);
$ResetResult = [WinHttp]::WinHttpResetAutoProxy($SessionHandle, [ResetFlag]::WINHTTP_RESET_ALL -bor [ResetFlag]::WINHTTP_RESET_OUT_OF_PROC)
if ($ResetResult -ne 0)
{
    "Auto Proxy Reset Failed: $ResetResult"
}
[WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null

#endregion

#region WinINET | API | CurrentUser

Write-Host "`nWinINET Proxy in Use" -ForegroundColor Blue
$IEProxyConfig = New-Object WINHTTP_CURRENT_USER_IE_PROXY_CONFIG
$IEPacAddr = $null
if ([WinHttp]::WinHttpGetIEProxyConfigForCurrentUser([ref] $IEProxyConfig))
{
    PrintIEProxyConfig $IEProxyConfig
    $IEPacAddr = $IEProxyConfig.lpszAutoConfigUrl

    if ($DownloadPacScript -and $IEPacAddr.Length -gt 0)
    {
        Write-Host "    Downloading Script..." -ForegroundColor Green
        try
        {
            Invoke-WebRequest -Uri $IEPacAddr -OutFile $PSScriptRoot\IE_PAC.js
            Write-Host "    Downloaded script file: $PSScriptRoot\IE_PAC.js`n" -ForegroundColor Green
        }
        catch
        {
            Write-Host "    Failed to download script file" -ForegroundColor Red
        }
    }
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    Win32 Call: WinHttpGetIEProxyConfigForCurrentUser Failed. Error Code: $ErrorCode ($([WinHTTP]::ErrorMessage[$ErrorCode]))`n"
}

#endregion

#region WinINET | REG | Proxy Setting Per User

Write-Host "`nWinINET Proxy Per User or Per Machine?" -ForegroundColor Blue
try 
{
    $IsPerUser = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxySettingsPerUser -ErrorAction Stop
}
catch
{
    $IsPerUser = 1
}
if ($IsPerUser -eq 0)
{
    Write-Host "    Per Machine" -ForegroundColor Yellow
}
else
{
    Write-Host "    Per User" -ForegroundColor Green
}

#endregion

#region WinINET | REG | AllUsers

Write-Host "`nWinINET Proxies in Registry" -ForegroundColor Blue
$Keyx64 = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections'
$Keyx86 = '\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\Connections'
if (!(Test-Path HKU:\)) { New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null }
$UserHives = (Get-ChildItem HKU:\ -ErrorAction SilentlyContinue).Name.Replace('HKEY_USERS', 'HKU:') | Where-Object { $_ -notlike '*_Classes' }
foreach ($Hive in $UserHives)
{
    $Username = $Hive.SubString(5)
    if ($Username -like 'S-1-5*') { $Username = Convert-SidToUsername $Username }
    Write-Host "    WinINET Registry of User $Username" -ForegroundColor Cyan
    $UserRegs = @()
    $Pathx64 = $Hive + $Keyx64
    $Pathx86 = $Hive + $Keyx86
    if (Test-Path $Pathx64)
    {
        try { $Data = Get-ItemPropertyValue -Path $Pathx64 -Name 'DefaultConnectionSettings' -ErrorAction Stop } catch { $Data = $null }
        if ($null -ne $Data) 
        {
            $UserRegs += @{
                Path = $Pathx64 + '\DefaultConnectionSettings'
                Data = $Data
            }
        }

        if ($IncludeSavedLegacySettings)
        {
            try { $Data = Get-ItemPropertyValue -Path $Pathx64 -Name 'SavedLegacySettings' -ErrorAction Stop } catch { $Data = $null }
            if ($null -ne $Data) 
            {
                $UserRegs += @{
                    Path = $Pathx64 + '\SavedLegacySettings'
                    Data = $Data
                }
            }
        }

        if ($IncludeVPN)
        {
            $Conns = (Get-Item $Pathx64).Property | Where-Object { $_ -notin @('DefaultConnectionSettings', 'SavedLegacySettings') }
            foreach ($Conn in $Conns)
            {
                try { $Data = Get-ItemPropertyValue -Path $Pathx64 -Name $Conn -ErrorAction Stop } catch { $Data = $null }
                if ($null -ne $Data) 
                {
                    $UserRegs += @{
                        Path = $Pathx64 + '\' + $Conn
                        Data = $Data
                    }
                }
            }
        }
    }

    if ((Test-Path $Pathx86) -and $IncludeWOW64)
    {
        try { $Data = Get-ItemPropertyValue -Path $Pathx86 -Name 'DefaultConnectionSettings' -ErrorAction Stop } catch { $Data = $null }
        if ($null -ne $Data) 
        {
            $UserRegs += @{
                Path = $Pathx86 + '\DefaultConnectionSettings'
                Data = $Data
            }
        }

        if ($IncludeSavedLegacySettings)
        {
            try { $Data = Get-ItemPropertyValue -Path $Pathx86 -Name 'SavedLegacySettings' -ErrorAction Stop } catch { $Data = $null }
            if ($null -ne $Data) 
            {
                $UserRegs += @{
                    Path = $Pathx86 + '\SavedLegacySettings'
                    Data = $Data
                }
            }
        }

        if ($IncludeVPN)
        {
            $Conns = (Get-Item $Pathx86).Property | Where-Object { $_ -notin @('DefaultConnectionSettings', 'SavedLegacySettings') }
            foreach ($Conn in $Conns)
            {
                try { $Data = Get-ItemPropertyValue -Path $Pathx86 -Name $Conn -ErrorAction Stop } catch { $Data = $null }
                if ($null -ne $Data) 
                {
                    $UserRegs += @{
                        Path = $Pathx86 + '\' + $Conn
                        Data = $Data
                    }
                }
            }
        }
    }

    PrintIERegs $UserRegs
}

#endregion

#region WinINET | REG | Machine

Write-Host "    WinINET Registry of Machine" -ForegroundColor Cyan
$MachineRegs = @()
$Pathx64 = 'HKLM:' + $Keyx64
$Pathx86 = 'HKLM:' + $Keyx86
if (Test-Path $Pathx64)
{
    try { $Data = Get-ItemPropertyValue -Path $Pathx64 -Name 'DefaultConnectionSettings' -ErrorAction Stop } catch { $Data = $null }
    if ($null -ne $Data) 
    {
        $MachineRegs += @{
            Path = $Pathx64 + '\DefaultConnectionSettings'
            Data = $Data
        }
    }

    if ($IncludeSavedLegacySettings)
    {
        try { $Data = Get-ItemPropertyValue -Path $Pathx64 -Name 'SavedLegacySettings' -ErrorAction Stop } catch { $Data = $null }
        if ($null -ne $Data) 
        {
            $MachineRegs += @{
                Path = $Pathx64 + '\SavedLegacySettings'
                Data = $Data
            }
        }
    }

    if ($IncludeVPN)
    {
        $Conns = (Get-Item $Pathx64).Property | Where-Object { $_ -notin @('DefaultConnectionSettings', 'SavedLegacySettings', 'WinHttpSettings') }
        foreach ($Conn in $Conns)
        {
            try { $Data = Get-ItemPropertyValue -Path $Pathx64 -Name $Conn -ErrorAction Stop } catch { $Data = $null }
            if ($null -ne $Data) 
            {
                $MachineRegs += @{
                    Path = $Pathx64 + '\' + $Conn
                    Data = $Data
                }
            }
        }
    }
}

if ((Test-Path $Pathx86) -and $IncludeWOW64)
{
    try { $Data = Get-ItemPropertyValue -Path $Pathx86 -Name 'DefaultConnectionSettings' -ErrorAction Stop } catch { $Data = $null }
    if ($null -ne $Data) 
    {
        $MachineRegs += @{
            Path = $Pathx86 + '\DefaultConnectionSettings'
            Data = $Data
        }
    }

    if ($IncludeSavedLegacySettings)
    {
        try { $Data = Get-ItemPropertyValue -Path $Pathx86 -Name 'SavedLegacySettings' -ErrorAction Stop } catch { $Data = $null }
        if ($null -ne $Data) 
        {
            $MachineRegs += @{
                Path = $Pathx86 + '\SavedLegacySettings'
                Data = $Data
            }
        }
    }

    if ($IncludeVPN)
    {
        $Conns = (Get-Item $Pathx86).Property | Where-Object { $_ -notin @('DefaultConnectionSettings', 'SavedLegacySettings', 'WinHttpSettings') }
        foreach ($Conn in $Conns)
        {
            try { $Data = Get-ItemPropertyValue -Path $Pathx86 -Name $Conn -ErrorAction Stop } catch { $Data = $null }
            if ($null -ne $Data) 
            {
                $UserRegs += @{
                    Path = $Pathx86 + '\' + $Conn
                    Data = $Data
                }
            }
        }
    }
}

PrintIERegs $MachineRegs

#endregion

#region WinHTTP | API | Default

Write-Host "`nWinHTTP Default Proxy" -ForegroundColor Blue
$WinHttpDefaultProxyInfo = New-Object WINHTTP_PROXY_INFO
if ([WinHttp]::WinHttpGetDefaultProxyConfiguration([ref] $WinHttpDefaultProxyInfo)) 
{
    PrintProxyInfo $WinHttpDefaultProxyInfo
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    Win32 Call: WinHttpGetDefaultProxyConfiguration Failed. Error Code: $ErrorCode  ($([WinHTTP]::ErrorMessage[$ErrorCode]))`n"
}

#endregion

#region WinHTTP | API | WPAD

Write-Host "`nAuto Proxy" -ForegroundColor Blue
$WpadAddr = ""
$AutoProxyAvailable = $false
if ([WinHttp]::WinHttpDetectAutoProxyConfigUrl([AutoDetectFlag]::WINHTTP_AUTO_DETECT_TYPE_DHCP, [ref]$WpadAddr)) 
{
    $AutoProxyAvailable = $true
    "    DHCP WPAD Address: $WpadAddr"
    
    if ($DownloadPacScript)
    {
        Write-Host "    Downloading Script..." -ForegroundColor Green
        try
        {
            Invoke-WebRequest -Uri $WpadAddr -OutFile $PSScriptRoot\WPAD_DHCP_PAC.js
            Write-Host "    Downloaded script file: $PSScriptRoot\WPAD_DHCP_PAC.js`n" -ForegroundColor Green
        }
        catch
        {
            Write-Host "    Failed to download script file" -ForegroundColor Red
        }
    }
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    No DHCP WPAD Detected. Code: $ErrorCode ($([WinHTTP]::ErrorMessage[$ErrorCode]))"
}
if ([WinHttp]::WinHttpDetectAutoProxyConfigUrl([AutoDetectFlag]::WINHTTP_AUTO_DETECT_TYPE_DNS_A, [ref]$WpadAddr)) 
{
    $AutoProxyAvailable = $true
    "    DNS WPAD Address: $WpadAddr"

    if ($DownloadPacScript)
    {
        Write-Host "    Downloading Script..." -ForegroundColor Green
        try
        {
            Invoke-WebRequest -Uri $WpadAddr -OutFile $PSScriptRoot\WPAD_DNS_PAC.js
            Write-Host "    Downloaded script file: $PSScriptRoot\WPAD_DNS_PAC.js`n" -ForegroundColor Green
        }
        catch
        {
            Write-Host "    Failed to download script file" -ForegroundColor Red
        }
    }
}
else 
{
    $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "    No DNS WPAD Detected. Code: $ErrorCode ($([WinHTTP]::ErrorMessage[$ErrorCode]))"
}

#endregion

#region WinHTTP | REG | WPAD Disabled

try 
{
    $IsWpadDisabled = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp' -Name DisableWpad -ErrorAction Stop
}
catch
{
    $IsWpadDisabled = 0
}
if ($IsWpadDisabled -eq 0)
{
    Write-Host "    WPAD not disabled by HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\DisableWpad" -ForegroundColor Green
}
else
{
    Write-Host "    WPAD disabled by HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\DisableWpad" -ForegroundColor Red
}

try 
{
    $IsWpadDisabled = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp' -Name DisableWpad -ErrorAction Stop
}
catch
{
    $IsWpadDisabled = 0
}
if ($IsWpadDisabled -eq 0)
{
    Write-Host "    WPAD not disabled by HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\DisableWpad" -ForegroundColor Green
}
else
{
    Write-Host "    WPAD disabled by HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\DisableWpad" -ForegroundColor Red
}

#endregion

#region WinHTTP | API | WinHttpGetProxyForUrl

if ($Url.Length -gt 0)
{
    if ($AutoProxyAvailable)
    {
        Write-Host "`nWinHttpGetProxyForUrl with Auto Proxy" -ForegroundColor Blue

        $SessionHandle = [WinHttp]::WinHttpOpen("PWSH PINVOKE WINHTTP CLIENT/1.0", [AccessType]::WINHTTP_ACCESS_TYPE_NO_PROXY, "", "", 0);

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
            "    Win32 Call: WinHttpGetProxyForUrl Auto Proxy Failed. Error Code: $ErrorCode ($([WinHTTP]::ErrorMessage[$ErrorCode]))"
        }

        [WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null
    }
    if ($null -ne $IEPacAddr)
    {
        Write-Host "`nWinHttpGetProxyForUrl with IE Auto Config URL" -ForegroundColor Blue

        $SessionHandle = [WinHttp]::WinHttpOpen("PWSH PINVOKE WINHTTP CLIENT/1.0", [AccessType]::WINHTTP_ACCESS_TYPE_NO_PROXY, "", "", 0);

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
            "    Win32 Call: WinHttpGetProxyForUrl IE PAC Failed. Error Code: $ErrorCode ($([WinHTTP]::ErrorMessage[$ErrorCode]))"
        }

        [WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null
    }
    if ('' -ne $PacUrl)
    {
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
            "    Win32 Call: WinHttpGetProxyForUrl Manual PAC Failed. Error Code: $ErrorCode ($([WinHTTP]::ErrorMessage[$ErrorCode]))"
        }

        [WinHttp]::WinHttpCloseHandle($SessionHandle) | Out-Null
    }
}

#endregion

#region Extra | ENV

if ($IncludeEnv)
{
    Write-Host "`nEnvironment Variables (for libcurl)" -ForegroundColor Blue
    $EnvList = @('http_proxy', 'HTTPS_PROXY', 'FTP_PROXY', 'ALL_PROXY', 'NO_PROXY') # Environment Varibles are not case sensitive on Windows
    foreach ($EnvItem in $EnvList) {
        Write-Host "    $EnvItem" -ForegroundColor Cyan
        Write-Host "    User    : $([Environment]::GetEnvironmentVariable($EnvItem, [EnvironmentVariableTarget]::User))"
        Write-Host "    Machine : $([Environment]::GetEnvironmentVariable($EnvItem, [EnvironmentVariableTarget]::Machine))"
        Write-Host
    }
}

#endregion
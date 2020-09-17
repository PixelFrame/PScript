function CallWin32Api
{
    $FuncDef = @"
[DllImport("winhttp.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool WinHttpGetProxyForUrl(HINTERNET hSession, string strUrl, WINHTTP_AUTO_PROXYOPTIONS autoProxyOptions, out WINHTTP_PROXY_INFO proxyInfo);
"@
    $Win32Api = Add-Type -MemberDefinition $FuncDef -Name WinHttpGetProxyForUrl -Namespace Win32
    $Win32Api::WinHttpGetProxyForUrl()
}
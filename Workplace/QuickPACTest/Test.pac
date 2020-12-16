function FindProxyForURL(url, host) {
    if (dnsDomainIs(host, "example.com") || shExpMatch(host, "*.example.com"))
        return "DIRECT";
    return "PROXY proxy.vlab.int:8080";
}
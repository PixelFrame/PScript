# Test-PAC
Testing Windows PAC parsing with WinHttpGetProxyForUrl call.
As WinHTTP now doesn't support 'file://' URL as a PAC URL. We need to start a local web server for local file.
Uses PS web server from PSGallery.
Need to add PAC/DAT MIME type "application/x-ns-proxy-autoconfig".
> https://gallery.technet.microsoft.com/scriptcenter/Powershell-Webserver-74dcf466

# Test-PACURL
Leave the PAC URL to user define.
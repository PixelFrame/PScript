function FindProxyForURL(url, host) {
    var direct = "DIRECT";
    var proxyServer = "PROXY myproxy.contoso.com:8080";

    // Client subnets go direct
    if (isInNet(myIpAddress(), "10.10.10.0", "255.255.255.0")
        || isInNet(myIpAddress(), "10.10.20.0", "255.255.255.0")
        || isInNet(myIpAddress(), "10.10.30.0", "255.255.255.0")) {
        return direct;
    }

    // Internal web sites go direct
    if (shExpMatch(host, "*.contoso.com")) {
        return direct;
    }

    // Host subnets go proxy
    if (isInNet(dnsResolve(host), "100.100.0.0", "255.255.0.0")) {
        return proxyServer;
    }

    // O365 samples
    if (shExpMatch(host, "cdn.odc.officeapps.live.com")
        || shExpMatch(host, "cdn.uci.officeapps.live.com")
        || shExpMatch(host, "roaming.officeapps.live.com")) {
        return proxyServer;
    }

    if (shExpMatch(host, "*.broadcast.skype.com")
        || shExpMatch(host, "*.compliance.microsoft.com")
        || shExpMatch(host, "*.lync.com")
        || shExpMatch(host, "*.mail.protection.outlook.com")
        || shExpMatch(host, "*.msftidentity.com")
        || shExpMatch(host, "*.msidentity.com")
        || shExpMatch(host, "*.officeapps.live.com")
        || shExpMatch(host, "*.online.office.com")
        || shExpMatch(host, "*.outlook.office.com")
        || shExpMatch(host, "*.protection.office.com")
        || shExpMatch(host, "*.protection.outlook.com")
        || shExpMatch(host, "*.security.microsoft.com")
        || shExpMatch(host, "*.skypeforbusiness.com")
        || shExpMatch(host, "*.teams.microsoft.com")
        || shExpMatch(host, "account.activedirectory.windowsazure.com")
        || shExpMatch(host, "account.office.net")
        || shExpMatch(host, "accounts.accesscontrol.windows.net")
        || shExpMatch(host, "adminwebservice.microsoftonline.com")
        || shExpMatch(host, "api.passwordreset.microsoftonline.com")
        || shExpMatch(host, "autologon.microsoftazuread-sso.com")
        || shExpMatch(host, "becws.microsoftonline.com")
        || shExpMatch(host, "broadcast.skype.com")
        || shExpMatch(host, "clientconfig.microsoftonline-p.net")
        || shExpMatch(host, "companymanager.microsoftonline.com")
        || shExpMatch(host, "compliance.microsoft.com")
        || shExpMatch(host, "Contoso.sharepoint.com")
        || shExpMatch(host, "Contoso-my.sharepoint.com")
        || shExpMatch(host, "device.login.microsoftonline.com")
        || shExpMatch(host, "graph.microsoft.com")
        || shExpMatch(host, "graph.windows.net")
        || shExpMatch(host, "login.microsoft.com")
        || shExpMatch(host, "login.microsoftonline.com")
        || shExpMatch(host, "login.microsoftonline-p.com")
        || shExpMatch(host, "login.windows.net")
        || shExpMatch(host, "logincert.microsoftonline.com")
        || shExpMatch(host, "loginex.microsoftonline.com")
        || shExpMatch(host, "login-us.microsoftonline.com")
        || shExpMatch(host, "nexus.microsoftonline-p.com")
        || shExpMatch(host, "office.live.com")
        || shExpMatch(host, "outlook.office.com")
        || shExpMatch(host, "outlook.office365.com")
        || shExpMatch(host, "passwordreset.microsoftonline.com")
        || shExpMatch(host, "protection.office.com")
        || shExpMatch(host, "provisioningapi.microsoftonline.com")
        || shExpMatch(host, "security.microsoft.com")
        || shExpMatch(host, "smtp.office365.com")
        || shExpMatch(host, "teams.microsoft.com")) {
        return direct;
    }

    return proxyServer;
}
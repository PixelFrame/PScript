Get-NetIPsecRule -DisplayName "VLAB Internal HTTP IPsec Outbound" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecRule
Get-NetIPsecRule -DisplayName "VLAB Internal HTTP IPsec Inbound" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecRule

Get-NetIPsecPhase1AuthSet -DisplayName "SHLTH Machine Cert Auth" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecPhase1AuthSet
Get-NetIPsecPhase2AuthSet -DisplayName "SHLTH User Cert+Kerberos Auth" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecPhase2AuthSet

Get-NetIPsecMainModeCryptoSet -DisplayName "MM Set AES256-DH19-SHA256" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecMainModeCryptoSet
Get-NetIPsecQuickModeCryptoSet -DisplayName "QM Set AES256-ESP-SHA256" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecQuickModeCryptoSet

Get-NetIPsecMainModeRule -DisplayName "MM Rule AES256-DH19-SHA256" -PolicyStore 'shlth.vlab\SHL Firewall' | Remove-NetIPsecMainModeRule


Get-NetIPsecRule -DisplayName "VLAB Internal HTTP IPsec Outbound" | Remove-NetIPsecRule
Get-NetIPsecRule -DisplayName "VLAB Internal HTTP IPsec Inbound" | Remove-NetIPsecRule

Start-Sleep -Seconds 10

Get-NetIPsecPhase1AuthSet -DisplayName "SHLTH Machine Cert Auth" | Remove-NetIPsecPhase1AuthSet
Get-NetIPsecPhase2AuthSet -DisplayName "SHLTH User Cert+Kerberos Auth" | Remove-NetIPsecPhase2AuthSet

Get-NetIPsecMainModeCryptoSet -DisplayName "MM Set AES256-DH19-SHA256" | Remove-NetIPsecMainModeCryptoSet
Get-NetIPsecQuickModeCryptoSet -DisplayName "QM Set AES256-ESP-SHA256" | Remove-NetIPsecQuickModeCryptoSet

Get-NetIPsecMainModeRule -DisplayName "MM Rule AES256-DH19-SHA256" | Remove-NetIPsecMainModeRule

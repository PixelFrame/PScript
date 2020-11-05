# MAIN MODE
# Encryption: AES256
# DHGroup: DH19
# Integrity: SHA256
$MMProp = New-NetIPsecMainModeCryptoProposal -Encryption AES256 -KeyExchange DH19 -Hash SHA256
$MMSet = New-NetIPsecMainModeCryptoSet -DisplayName "MM Set AES256-DH19-SHA256" -Proposal $MMProp -PolicyStore 'shlth.vlab\SHL Firewall'
New-NetIPsecMainModeRule -DisplayName "MM Rule AES256-DH19-SHA256" -MainModeCryptoSet $MMSet.Name -PolicyStore 'shlth.vlab\SHL Firewall'

# Phase 1 Auth
# Machine Cert
$MachineCertProp = New-NetIPsecAuthProposal -Machine -Cert -Authority "DC=vlab, DC=shlth, CN=shlth-SHL-PDC-CA" -AuthorityType Root
$Phase1Auth = New-NetIPsecPhase1AuthSet -DisplayName "SHLTH Machine Cert Auth" -Proposal $MachineCertProp -PolicyStore 'shlth.vlab\SHL Firewall'

# Phase 2 Auth
# User Cert + Kerberos
$UserCertProp = New-NetIPsecAuthProposal -User -Cert -Authority "DC=vlab, DC=shlth, CN=shlth-SHL-PDC-CA" -AuthorityType Root
$UserKerbProp = New-NetIPsecAuthProposal -User -Kerberos
$Phase2Auth = New-NetIPsecPhase2AuthSet -DisplayName "SHLTH User Cert+Kerberos Auth" -Proposal $UserCertProp, $UserKerbProp -PolicyStore 'shlth.vlab\SHL Firewall'

# QUICK MODE
# Encryption: AES256
# Encap: ESP
# Integrity: SHA256
$QMProp = New-NetIPsecQuickModeCryptoProposal -Encryption AES256 -Encapsulation ESP -ESPHash SHA256
$QMSet = New-NetIPsecQuickModeCryptoSet -DisplayName "QM Set AES256-ESP-SHA256" -Proposal $QMProp -PolicyStore 'shlth.vlab\SHL Firewall'

New-NetIPsecRule -DisplayName "VLAB Internal HTTP IPsec Outbound" -InboundSecurity Require -OutboundSecurity Require `
    -Phase1AuthSet $Phase1Auth.Name -Phase2AuthSet $Phase2Auth.Name -QuickModeCryptoSet $QMSet.Name `
    -Protocol TCP -RemoteAddress 192.168.10.0/24 -RemotePort 443, 80 `
    -Mode Transport `
    -Profile Domain `
    -PolicyStore 'shlth.vlab\SHL Firewall'

New-NetIPsecRule -DisplayName "VLAB Internal HTTP IPsec Inbound" -InboundSecurity Require -OutboundSecurity Require `
    -Phase1AuthSet $Phase1Auth.Name -Phase2AuthSet $Phase2Auth.Name -QuickModeCryptoSet $QMSet.Name `
    -Protocol TCP -LocalAddress 192.168.10.0/24 -LocalPort 443, 80 `
    -Mode Transport `
    -Profile Domain `
    -PolicyStore 'shlth.vlab\SHL Firewall'
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $CertAuthority,

    [Parameter(Mandatory = $true)]
    [string]
    $PolicyStore
)


# MAIN MODE
# Encryption: AES256
# DHGroup: DH19
# Integrity: SHA256
$MMProp = New-NetIPsecMainModeCryptoProposal -Encryption AES256 -KeyExchange DH19 -Hash SHA256
$MMSet = New-NetIPsecMainModeCryptoSet -DisplayName "MM Set AES256-DH19-SHA256" -Proposal $MMProp -PolicyStore $PolicyStore
New-NetIPsecMainModeRule -DisplayName "MM Rule AES256-DH19-SHA256" -MainModeCryptoSet $MMSet.Name -PolicyStore $PolicyStore

# Phase 1 Auth
# Machine Cert
$MachineCertProp = New-NetIPsecAuthProposal -Machine -Cert -Authority $CertAuthority -AuthorityType Root
$Phase1Auth = New-NetIPsecPhase1AuthSet -DisplayName "ARG Machine Cert Auth" -Proposal $MachineCertProp -PolicyStore $PolicyStore

# Phase 2 Auth
# User Cert + Kerberos
$UserCertProp = New-NetIPsecAuthProposal -User -Cert -Authority $CertAuthority -AuthorityType Root
$UserKerbProp = New-NetIPsecAuthProposal -User -Kerberos
$Phase2Auth = New-NetIPsecPhase2AuthSet -DisplayName "ARG User Cert+Kerberos Auth" -Proposal $UserCertProp, $UserKerbProp -PolicyStore $PolicyStore

# QUICK MODE
# Encryption: AES256
# Encap: ESP
# Integrity: SHA256
$QMProp = New-NetIPsecQuickModeCryptoProposal -Encryption AES256 -Encapsulation ESP -ESPHash SHA256
$QMSet = New-NetIPsecQuickModeCryptoSet -DisplayName "QM Set AES256-ESP-SHA256" -Proposal $QMProp -PolicyStore $PolicyStore

New-NetIPsecRule -DisplayName "ARG-IPsec WinRM (TCP-Out)" -Name "IPsec-WinRM-Out-TCP" -InboundSecurity Require -OutboundSecurity Require `
    -Phase1AuthSet $Phase1Auth.Name -Phase2AuthSet $Phase2Auth.Name -QuickModeCryptoSet $QMSet.Name `
    -Protocol TCP -RemoteAddress 192.168.10.0/24 -RemotePort 5985 `
    -Mode Transport `
    -Profile Domain `
    -PolicyStore $PolicyStore

New-NetIPsecRule -DisplayName "ARG-IPsec WinRM (TCP-In)" -Name "IPsec-WinRM-In-TCP" -InboundSecurity Require -OutboundSecurity Require `
    -Phase1AuthSet $Phase1Auth.Name -Phase2AuthSet $Phase2Auth.Name -QuickModeCryptoSet $QMSet.Name `
    -Protocol TCP -LocalAddress 192.168.10.0/24 -LocalPort 5985 `
    -Mode Transport `
    -Profile Domain `
    -PolicyStore $PolicyStore
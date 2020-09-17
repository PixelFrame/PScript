# Server

Set-VpnServerConfiguration -CustomPolicy `
    -EncryptionMethod AES256 `
    -DHGroup Group14 -PfsGroup PFS2048 `
    -CipherTransformConstants GCMAES256 `
    -IntegrityCheckMethod SHA256 `
    -AuthenticationTransformConstants GCMAES256 `
    -PassThru

# S2S

Set-VpnS2SInterface -Name 'VLAB S2S Link' -CustomPolicy `
    -EncryptionMethod AES256 `
    -DHGroup Group14 -PfsGroup PFS2048 `
    -CipherTransformConstants GCMAES256 `
    -IntegrityCheckMethod SHA256 `
    -AuthenticationTransformConstants GCMAES256 `
    -PassThru

Set-VpnS2SInterface -Name 'Remote Router' -CustomPolicy -EncryptionMethod AES256 -DHGroup Group14 -PfsGroup PFS2048 -CipherTransformConstants GCMAES256 -IntegrityCheckMethod SHA256 -AuthenticationTransformConstants GCMAES256 -PassThru

# Client

Set-VpnConnectionIPsecConfiguration -ConnectionName 'VirtLab AlwaysOn VPN User Tunnel' -CustomPolicy`
-EncryptionMethod AES256 `
    -DHGroup Group14 -PfsGroup PFS2048 `
    -CipherTransformConstants GCMAES256 `
    -IntegrityCheckMethod SHA256 `
    -AuthenticationTransformConstants GCMAES256 `
    -PassThru
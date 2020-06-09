Set-Location Cert:\LocalMachine\Root

$CARootCert = Get-ChildItem | Where-Object -FilterScript { $_.Subject -like 'CN=test-PDC-CA*' }     # Get the certificate starting with CN=test-PDC-CA
$CARootCert = $CARootCert[0]                                                                        # In case there’re 2 root certs with the same name

Set-VpnConnection -MachineCertificateIssuerFilter $CARootCert -Name 'TEST AlwaysOnVPN'
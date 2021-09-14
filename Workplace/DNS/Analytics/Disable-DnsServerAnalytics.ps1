[CmdletBinding()]
param (
)

$log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration 'Microsoft-Windows-DNSServer/Analytical'
$log.IsEnabled = $false
$log.SaveChanges()

Get-WinEvent -ListLog 'Microsoft-Windows-DNSServer/Analytical' | Format-List *
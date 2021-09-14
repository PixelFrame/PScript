[CmdletBinding()]
param (
    [Parameter()] [string]                                                   $Path,
    [Parameter()] [string]                                                   $FileName,
    [Parameter()] [int]    [ValidateRange(1,[System.Int32]::MaxValue)]       $MaxSize
)

if ($Path -eq '')
{
    $Path = '%SystemRoot%\System32\Winevt\Logs'
}

if ($FileName -eq '')
{
    $FileName = 'Microsoft-Windows-DNSServer%4Analytical.etl'
}

$log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration 'Microsoft-Windows-DNSServer/Analytical'
$log.IsEnabled = $true
$log.LogFilePath = "$Path\$FileName"
$log.MaximumSizeInBytes = $MaxSize
$log.SaveChanges()

Get-WinEvent -ListLog 'Microsoft-Windows-DNSServer/Analytical' | Format-List *
[CmdletBinding()]
param (
    [string] $InputEtl = ''
)

$EventLogName = 'Microsoft-Windows-DNSServer/Analytical'

if ($InputEtl -eq '')
{
    if (Get-WinEvent -ListLog $EventLogName -ErrorAction SilentlyContinue)
    {
        $DNSAnalyticalLogData = Get-WinEvent -ListLog $EventLogName
        if (($DNSAnalyticalLogData.LogFilePath).split("\")[0] -eq '%SystemRoot%')
        { 
            $DNSAnalyticalLogPath = $DNSAnalyticalLogData.LogFilePath.Replace('%SystemRoot%', "$env:Windir") 
        }
        else
        {
            $DNSAnalyticalLogPath = $DNSAnalyticalLogData.LogFilePath
        }
    }
    else
    {
        Write-Error "Microsoft-Windows-DNSServer/Analytical log is not enabled!"
        exit
    }
}
else
{
    $DNSAnalyticalLogPath = $InputEtl
}
    
if (Test-Path $DNSAnalyticalLogPath)
{
    Get-WinEvent -Path $DNSAnalyticalLogPath -Oldest
}
else
{
    Write-Warning "The $($EventLogName) log doesn't exist at the expected path:"
    Write-Host "`n$($DNSAnalyticalLogPath)"
    exit
}
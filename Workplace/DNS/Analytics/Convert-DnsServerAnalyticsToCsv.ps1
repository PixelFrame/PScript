# Original script: https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/secrets-from-the-deep-the-dns-analytical-log-part-2/ba-p/1898454

[CmdletBinding()]
Param
(
    [Parameter()][string] $InputEtl = '',
    [Parameter(Mandatory = $true)][string] $OutFile
)

#Define the DNS Analytical Log name.   
$EventLogName = 'Microsoft-Windows-DNSServer/Analytical'
if ($InputEtl -eq '')
{        
    try
    {
        if (Get-WinEvent -ListLog $EventLogName  -ErrorAction SilentlyContinue)
        {
    
            $DNSAnalyticalLogData = Get-WinEvent -ListLog $EventLogName
            if (($DNSAnalyticalLogData.LogFilePath).split("\")[0] -eq '%SystemRoot%') { $DNSAnalyticalLogPath = $DNSAnalyticalLogData.LogFilePath.Replace('%SystemRoot%', "$env:Windir") }
        }
        else
        {
            Write-Host "The Microsoft-Windows-DNSServer/Analytical log couldn't be found to be enumerated.`n" -ForegroundColor Red
            Write-Host "Ensure that this function is being run on a DNS Server that has the Microsoft-Windows-DNSServer/Analytical log."
            return
        }
    }
    catch
    {
        $_.Exception.Message      
    }
}
else
{
    $DNSAnalyticalLogPath = $InputEtl
}


if (Test-Path $DNSAnalyticalLogPath)
{
    Get-WinEvent -Path $DNSAnalyticalLogPath -Oldest | Select-Object -Property @( 
        'RecordId',
        'Id',
        'TaskDisplayName',
        'LevelDisplayName',
        @{Name = 'TimeCreated'; Expression = { $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss.ffffff') } },
        'Message',
        'ProcessId',
        'ThreadId'
    ) | ConvertTo-Csv | Out-File $OutFile
}
else
{
    Write-Warning "The $($EventLogName) log doesn't exist at the expected path:"
    Write-Host "`n$($DNSAnalyticalLogPath)"
    return
}    

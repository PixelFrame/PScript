# Original script: https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/secrets-from-the-deep-the-dns-analytical-log-part-2/ba-p/1898454


[CmdletBinding()]
Param
(
    #Parameter to define the server.
    [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true,
        Position = 0)]
    $Server = $env:COMPUTERNAME
)

#Define the DNS Analytical Log name.   
$EventLogName = 'Microsoft-Windows-DNSServer/Analytical'
        
Try
{

    If (Get-WinEvent -ListLog $EventLogName  -ErrorAction SilentlyContinue)
    {
    
        $DNSAnalyticalLogData = Get-WinEvent -ListLog $EventLogName
        If (($DNSAnalyticalLogData.LogFilePath).split("\")[0] -eq '%SystemRoot%') { $DNSAnalyticalLogPath = $DNSAnalyticalLogData.LogFilePath.Replace('%SystemRoot%', "$env:Windir") }

    }
    Else
    {
        Write-Host "The Microsoft-Windows-DNSServer/Analytical log couldn't be found to be enumerated.`n" -ForegroundColor Red
        Write-Host "Ensure that this function is being run on a DNS Server that has the Microsoft-Windows-DNSServer/Analytical log."
        Return
    }
        
    If (Test-Path $DNSAnalyticalLogPath)
    {
        $AnalyticEvents = Get-WinEvent -Path $DNSAnalyticalLogPath -Oldest
        $Result = @()
        foreach ($AnalyticEvent in $AnalyticEvents)
        {
            if ($AnalyticEvent.Id -eq 256) {
                $Result += [PSCustomObject]@{
                    XID       = $AnalyticEvent.Properties[6].Value;
                    Interface = $AnalyticEvent.Properties[1].Value;
                    Client    = $AnalyticEvent.Properties[2].Value;
                    QType     = $AnalyticEvent.Properties[3].Value;
                    QName     = $AnalyticEvent.Properties[4].Value;
                }
            }
        }
        $Result | ConvertTo-Csv -NoTypeInformation | Out-File .\DNSReceivedQueries.csv
    }
    Else
    {
        Write-Warning "The $($EventLogName) log doesn't exist at the expected path:"
        Write-Host "`n$($DNSAnalyticalLogPath)"
        Return
    }      
}
Catch
{
    $_.Exception.Message      
}

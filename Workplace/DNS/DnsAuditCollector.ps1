[CmdletBinding()]
param (
    [Parameter(ParameterSetName = 'DiscoverByZone', Mandatory = $true)]
    [string]$ZoneName,
    
    [Parameter(ParameterSetName = 'Manual', Mandatory = $true)]
    [string[]]$NameServers,

    [Parameter()]
    [ValidateRange(1, [int64]::MaxValue)]
    [int64] $MaxEvents,

    [Parameter()]
    [string]$OutDir = (Resolve-Path '~\Desktop').Path,

    [Parameter()]
    [ValidateSet('WinRM', 'RPC')]
    [string]$Transport = 'WinRM'
)

if ($PSCmdlet.ParameterSetName -eq 'DiscoverByZone')
{
    Write-Host "Discovering Name Servers for zone $ZoneName..."
    $NameServers = Resolve-DnsName -Name $ZoneName -Type NS | Where-Object -Property NameHost | Select-Object -ExpandProperty NameHost -Unique
    Write-Host "Found $($NameServers.Count) Name Server(s): $($NameServers -join ', ')"
}
if ($PSCmdlet.ParameterSetName -eq 'Manual')
{
    Write-Host "Using provided Name Servers: $($NameServers -join ', ')"
}

$Complete = 0
$MaxEventsSpecified = $MaxEvents -ne $null

foreach ($NameServer in $NameServers)
{
    Write-Progress -Activity "Collecting DNS Audit Logs" `
        -Status "$Complete/$($NameServers.Count)" `
        -CurrentOperation "From $NameServer" `
        -PercentComplete ($Complete / $NameServers.Count * 100)

    if ($Transport -eq 'RPC')
    {
        $evts = $MaxEventsSpecified ?
            (Get-WinEvent -ComputerName $NameServer -LogName 'Microsoft-Windows-DNSServer/Audit' -MaxEvents $MaxEvents) :
            (Get-WinEvent -ComputerName $NameServer -LogName 'Microsoft-Windows-DNSServer/Audit')
    }
    else
    {
        $sess = New-PSSession -ComputerName $NameServer
        $evts = $MaxEventsSpecified ? 
            (Invoke-Command -Session $sess -ArgumentList $MaxEvents -ScriptBlock { param($MaxEvents) Get-WinEvent -LogName 'Microsoft-Windows-DNSServer/Audit' -MaxEvents $MaxEvents }):
            (Invoke-Command -Session $sess -ScriptBlock { Get-WinEvent -LogName 'Microsoft-Windows-DNSServer/Audit' })
    }
    $evts | Select-Object @(
        @{Name = 'TimeCreated'; Expression = { $_.TimeCreated.ToString('o') } },
        @{Name = 'EventID'; Expression = { $_.Id } },
        @{Name = 'Level'; Expression = { $_.LevelDisplayName } },
        @{Name = 'Message'; Expression = { $_.Message } },
        @{Name = 'Task'; Expression = { $_.TaskDisplayName } },
        @{Name = 'ComputerName'; Expression = { $_.MachineName } },
        @{Name = 'UserId'; Expression = { $_.UserId } }
    ) | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$OutDir\$($NameServer)_DNS_AuditLogs.csv" -Append -Encoding UTF8
    Remove-PSSession -Session $sess
    $Complete++
}
Write-Host "Collected DNS Audit Logs from $($NameServers.Count) Name Server(s)"
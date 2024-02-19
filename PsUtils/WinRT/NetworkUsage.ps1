#requires -PSEdition Desktop

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $StartTime,

    [Parameter(Mandatory)]
    [string]
    $StopTime
)

$dtStartTime = [datetime]::Parse($StartTime)
$dtStopTime = [datetime]::Parse($StopTime)

[Windows.Networking.Connectivity.AttributedNetworkUsage, Windows.Networking.Connectivity, ContentType = WindowsRuntime] | Out-Null
[Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime] | Out-Null

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$_taskMethods = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1
}

$asTaskGeneric = ($_taskMethods | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0];

function Await($WinRtTask, $ResultType)
{
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

$connectionProfiles = [Windows.Networking.Connectivity.NetworkInformation]::GetConnectionProfiles()
$states = New-Object Windows.Networking.Connectivity.NetworkUsageStates

'Connection Profiles:'
$cnt = 0 
foreach ($connectionProfile in $connectionProfiles)
{
    "$cnt. $($connectionProfile.ProfileName)"
}
$index = 0
$indexInput = Read-Host 'Select connection profile to show usage'
while (![int]::TryParse($indexInput, [ref]$index))
{
    $indexInput = Read-Host 'Select connection profile to show usage: '
}

Await ($connectionProfiles[$index].GetAttributedNetworkUsageAsync($dtStartTime, $dtStopTime, $states)) ([System.Collections.Generic.IReadOnlyList[Windows.Networking.Connectivity.AttributedNetworkUsage]]) `
| Select-Object -Property @(
    @{Name = 'App ID'; Expression = { $_.AttributionId } },
    @{Name = 'Bytes Received'; Expression = { $_.BytesReceived } },
    @{Name = 'Bytes Sent'; Expression = { $_.BytesSent } }
    @{Name = 'Bytes Total'; Expression = { $_.BytesSent + $_.BytesReceived } }
) | Out-GridView -Title "$($connectionProfiles[$index].ProfileName) Usage"
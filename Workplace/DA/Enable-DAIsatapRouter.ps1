[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $InterfaceAlias = "Ethernet",

    [Parameter()]
    [int]
    $MaxRetry = 30,

    [switch]
    $Transcript,

    [Parameter()]
    [string]
    $TranscriptPath = "$PSScriptRoot\EnableIsatapRouter.log"
)

if ($Transcript)
{
    Start-Transcript -LiteralPath $TranscriptPath
}

while ((Get-Service -Name RaMgmtSvc).Status -ne 'Running')
{
    Write-Host "Remote Access Management Service not ready. Waiting..."
    Start-Sleep -Seconds 30
}

$AdapterGuid = (Get-NetAdapter -InterfaceAlias $InterfaceAlias -ErrorAction Stop).InterfaceGuid
$IsatapIfAlias = "isatap.$AdapterGuid"
$FailCnt = 0
while ($FailCnt -lt $MaxRetry)
{
    $IsatapIf = Get-NetIPInterface -InterfaceAlias $IsatapIfAlias -ErrorAction SilentlyContinue
    if ($null -eq $IsatapIf -or $Isatap.ConnectionState -ne 'Connected')
    {
        $FailCnt++
        Write-Host "ISATAP interface $IsatapIfAlias not avaliable"
        Write-Host "Retry $FailCnt/$MaxRetry."
        if ($FailCnt -eq $MaxRetry)
        {
            Write-Host "Max retry reached. Exit."
            Exit
        }
        Write-Host "Next retry after 60 seconds."
        Start-Sleep -Seconds 60
    }
    else 
    {
        break
    }
}

$IsatapIf | Set-NetIPInterface -Forwarding Enabled -Advertising Enabled -AdvertiseDefaultRoute Enabled -PassThru
Write-Host "Completed enabling ISATAP interface advertising and forwarding"
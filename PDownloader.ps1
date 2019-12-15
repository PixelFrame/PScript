Write-Host "PowerShell Web Downloader"
$MaxAttempts = Read-Host -Prompt "Max Retry"

$Proxy = New-Object System.Net.WebProxy("http://127.0.0.1:21764")
# $proxy.useDefaultCredentials = $true
$WebClient = New-Object system.net.webclient
$WebClient.proxy = $proxy

$SourceURI = "https://github.com/be5invis/Sarasa-Gothic/releases/download/v0.10.2/sarasa-gothic-ttf-0.10.2.7z"
$DestPath = ".\" + "sarasa-gothic-ttf-0.10.2.7z"

$AttemptCount = 0
Do
{
    $AttemptCount++
    $WebClient.DownloadFile($SourceURI, $DestPath)
} while (((Test-Path $DestPath) -eq $false) -and ($attemptCount -le $MaxAttempts))
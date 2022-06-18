function Invoke-Download
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SourceUri,

        [string]
        $Destination = $PSScriptRoot,
        
        [System.UInt32]
        $Retry = 3,
        
        [bool]
        $UseProxy = $true
    )
    $WebClient = New-Object System.Net.WebClient
    if ($UseProxy)
    {
        $Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $WebClient.Proxy = $Proxy
    }
    $FileName = $SourceUri.Substring($SourceUri.LastIndexOf('/') + 1)
    $DestPath = $Destination + '\' + $FileName

    $AttemptCount = 0
    Do
    {
        $AttemptCount++
        $WebClient.DownloadFile($SourceUri, $DestPath)
    } while (((Test-Path $DestPath) -eq $false) -and ($AttemptCount -le $Retry))
}
function Invoke-Download
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SourceUri,

        [string]
        $DestPath = '.\',

        [string]
        $FileName,
        
        [System.UInt32]
        $Retry = 3,
        
        [bool]
        $UseProxy = $true,

        [string]
        $Hash = ''
    )
    $WebClient = New-Object System.Net.WebClient
    if ($UseProxy)
    {
        $Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $WebClient.Proxy = $Proxy
    }
    if (!$FileName)
    {
        $FileName = $SourceUri.Substring($SourceUri.LastIndexOf('/') + 1)
    }
    $DestPath += $FileName

    $AttemptCount = 0
    Do
    {
        $AttemptCount++
        $WebClient.DownloadFile($SourceURI, $DestPath)
    } while (((Test-Path $DestPath) -eq $false) -and ($AttemptCount -le $Retry))
}
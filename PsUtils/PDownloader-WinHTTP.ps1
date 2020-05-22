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
    $User = "user"
    $Password = "password"

    $WinHttpClient = New-Object -ComObject "WinHttp.WinHttpRequest.5.1"
    $WinHttpClient.Open("GET", $Url, $false)

    $WinHttpClient.SetCredentials($User, $Password, $HttpREQUEST_SETCREDENTIALS_FOR_SERVER) 

    $WinHttpClient.Send()
    $Body = $WinHttpClient.ResponseText
    $Body
}
# Write random bytes to file(s)
[CmdletBinding()]
param (
    [Parameter()]
    [UInt32]
    $UpperSize = 1024,

    [Parameter()]
    [UInt32]
    $BottomSize = 100,

    [Parameter()]
    [UInt32]
    $Number = 10,

    [Parameter()]
    [string]
    $OutPath = $PSScriptRoot,

    [Parameter()]
    [UInt32]
    $DelayMili = 0
)


$RngCsp = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

while(--$Number -ge 0) {
    $cnt = 0
    $Size = Get-Random -Maximum $UpperSize -Minimum $BottomSize
    $OutFileName = $OutPath + '\' + [System.IO.Path]::GetRandomFileName();
    $OutFile = [System.IO.File]::OpenWrite($OutFileName)

    while ($cnt++ -lt 16)
    {
        $Bytes = New-Object byte[] -ArgumentList (65536 * $Size)
        $RngCsp.GetBytes($Bytes)
        $OutFile.Write($Bytes, 0, 65536 * $Size)
        Start-Sleep -Milliseconds $DelayMili
    }

    $OutFile.Close()
    $OutFile.Dispose()
}

$RngCsp.Dispose()
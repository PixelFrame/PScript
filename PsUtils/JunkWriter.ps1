# Write random bytes to file(s)
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateRange(0, 32767)]
    [UInt32]
    $UpperSize = 1024,

    [Parameter()]
    [ValidateRange(0, 32767)]
    [UInt32]
    $BottomSize = 100,

    [Parameter()]
    [Int32]
    $Number = 10,

    [Parameter()]
    [string]
    $OutPath = $PSScriptRoot,

    [Parameter()]
    [UInt32]
    $DelayMili = 0
)

# RNGCryptoServiceProvider Deprecated
# $RngCsp = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

while(--$Number -ge 0) {
    $cnt = 0
    $Size = Get-Random -Maximum $UpperSize -Minimum $BottomSize
    $OutFileName = $OutPath + '\' + [System.IO.Path]::GetRandomFileName();
    $OutFile = [System.IO.File]::OpenWrite($OutFileName)

    while ($cnt++ -lt 16)
    {
        # $Bytes = New-Object byte[] -ArgumentList (65536 * $Size)
        # $RngCsp.GetBytes($Bytes)
        $Bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(65536 * $Size)
        $OutFile.Write($Bytes, 0, 65536 * $Size)
        Start-Sleep -Milliseconds $DelayMili
    }

    $OutFile.Close()
    $OutFile.Dispose()
}

# $RngCsp.Dispose()
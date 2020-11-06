[CmdletBinding()]
param (
    [Parameter()]
    [int]
    $Size = 1024
)

$cnt = 0
$OutFile = [System.IO.File]::OpenWrite("$PSSCriptRoot\Test.dat")
$RngCsp = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

while ($cnt++ -lt 16)
{
    $Bytes = New-Object byte[] -ArgumentList (65536 * $Size)
    $RngCsp.GetBytes($Bytes)
    $OutFile.Write($Bytes, 0, 65536 * $Size)
}

$OutFile.Close()
$OutFile.Dispose()
$RngCsp.Dispose()
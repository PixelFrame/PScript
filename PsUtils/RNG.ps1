$cnt = 0
$OutFile = [System.IO.File]::OpenWrite('.\Test.dat')
$RngCsp = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    
while ($cnt -lt 10)
{
    $Bytes = New-Object byte[] -ArgumentList 1024
    $RngCsp.GetBytes($Bytes)

    $OutFile.Write($Bytes)
    $cnt++ 
}

$OutFile.Close()
$OutFile.Dispose()
$RngCsp.Dispose()
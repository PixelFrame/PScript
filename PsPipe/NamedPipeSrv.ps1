$PipeName = 'PSPipe'
$PipeDirect = [System.IO.Pipes.PipeDirection]::InOut

$PipeSrvStream = New-Object System.IO.Pipes.NamedPipeServerStream -ArgumentList @($PipeName, $PipeDirect)
$PipeSrvStream.WaitForConnection()
'Connected!'
$buffer = New-Object -TypeName Byte[] -ArgumentList 1000
$BytesRead = $PipeSrvStream.Read($buffer, 0, 1000)
[System.Text.Encoding]::ASCII.GetString($buffer, 0, $BytesRead)
'Message Read!'
Pause
$PipeSrvStream.Close()
$PipeSrvStream.Dispose()
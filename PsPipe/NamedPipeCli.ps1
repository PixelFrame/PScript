$PipeName = 'PSPipe'
$PipeDirect = [System.IO.Pipes.PipeDirection]::InOut
$PipeServer = '.'

$PipeCliStream = New-Object System.IO.Pipes.NamedPipeClientStream -ArgumentList @($PipeServer, $PipeName, $PipeDirect)
$PipeCliStream.Connect()
'Connected!'
$Message = [System.Text.Encoding]::ASCII.GetBytes('This is a pipe communication')
$PipeCliStream.Write($Message, 0, $Message.Count)
'Message Sent!'
Pause
$PipeCliStream.Close()
$PipeCliStream.Dispose()
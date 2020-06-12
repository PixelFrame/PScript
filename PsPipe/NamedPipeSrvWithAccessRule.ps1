# Only working on .NET Framework
# So need to be run on Windows PowerShell

$PipeName = 'PSPipe'
$PipeDirect = [System.IO.Pipes.PipeDirection]::InOut

$PipeSecurity = New-Object System.IO.Pipes.PipeSecurity
$DomainSID = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList @((Get-ADDomain).DomainSID)
$SID = New-Object System.Security.Principal.SecurityIdentifier -ArgumentList @([System.Security.Principal.WellKnownSidType]::AccountDomainAdminsSid, $DomainSID)
$AccessRule = New-Object System.IO.Pipes.PipeAccessRule -ArgumentList @($SID, [System.IO.Pipes.PipeAccessRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow);
$PipeSecurity.AddAccessRule($AccessRule);

$PipeSrvStream = New-Object System.IO.Pipes.NamedPipeServerStream -ArgumentList @($PipeName, $PipeDirect, -1, [System.IO.Pipes.PipeTransmissionMode]::Byte, 0, 512, 512, $PipeSecurity)
$PipeSrvStream.WaitForConnection()

'Connected!'
$buffer = New-Object -TypeName Byte[] -ArgumentList 512
$BytesRead = $PipeSrvStream.Read($buffer, 0, 512)
[System.Text.Encoding]::ASCII.GetString($buffer, 0, $BytesRead)
'Message Read!'
Pause
$PipeSrvStream.Close()
$PipeSrvStream.Dispose()
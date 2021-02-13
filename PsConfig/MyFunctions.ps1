function ConvertTo-Utf8
{
    param (
        [Parameter(ValueFromPipeline)][string] $File,
        [string] $Encoding = 'gb2312',
        [switch] $NewFile
    )

    PROCESS
    {
        $Contents = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::GetEncoding($Encoding))
        $EncUtf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false
        if ($NewFile)
        {
            $InsPos = $File.LastIndexOf('.')
            if ($InsPos -eq -1) { $InsPos = $File.Length }
            $Output = $File.Insert($InsPos, '-utf8')
        }
        else
        {
            $Output = $File
        }
        [System.IO.File]::WriteAllText($Output, $Contents, $EncUtf8NoBom)
    }
}

function AesEncryptText
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)][securestring] $SecureSecretText,
        [Parameter(Mandatory = $true)][securestring] $PIN
    )
    

    $SecretText = (New-Object PSCredential "user", $SecureSecretText).GetNetworkCredential().Password

    $PINStr = (New-Object PSCredential "user", $PIN).GetNetworkCredential().Password
    $PINNum = [UInt32]::Parse($PINStr)

    $RNG = New-Object System.Random -ArgumentList $PINNum
    $AESEncryptionKey = [System.Byte[]]::new(32)
    $RNG.NextBytes($AESEncryptionKey)
    $InitializationVector = [System.Byte[]]::new(16)
    $RNG.NextBytes($InitializationVector)
    $AESCipher = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AESCipher.Key = $AESEncryptionKey
    $AESCipher.IV = $InitializationVector

    $UnencryptedBytes = [System.Text.Encoding]::UTF8.GetBytes($SecretText)
    $Encryptor = $AESCipher.CreateEncryptor()
    $EncryptedBytes = $Encryptor.TransformFinalBlock($UnencryptedBytes, 0, $UnencryptedBytes.Length)

    [byte[]] $FullData = $AESCipher.IV + $EncryptedBytes
    $CipherText = [System.Convert]::ToBase64String($FullData)
    $AESCipher.Dispose()

    return $CipherText
}

function AesDecryptText
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)][securestring] $SecureCipherText,
        [Parameter(Mandatory = $true)][securestring] $PIN
    )

    $CipherText = (New-Object PSCredential "user", $SecureCipherText).GetNetworkCredential().Password
    
    $PINStr = (New-Object PSCredential "user", $PIN).GetNetworkCredential().Password
    $PINNum = [UInt32]::Parse($PINStr)

    $RNG = New-Object System.Random -ArgumentList $PINNum
    $AESEncryptionKey = [System.Byte[]]::new(32)
    $RNG.NextBytes($AESEncryptionKey)
    $InitializationVector = [System.Byte[]]::new(16)
    $RNG.NextBytes($InitializationVector)
    $AESCipher = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AESCipher.Key = $AESEncryptionKey
    $AESCipher.IV = $InitializationVector

    $Decryptor = $AESCipher.CreateDecryptor();
    $EncryptedBytes = [System.Convert]::FromBase64String($CipherText)
    $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedBytes, 16, $EncryptedBytes.Length - 16)

    $SecretText = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes)
    $AESCipher.Dispose()

    return $SecretText
}

function InvisibleRun
{
    param (
        [ValidateScript( { Test-Path $_ })]
        [string] $Script,
        [string] $Arguments,
        [switch] $Pwsh
    )
    
    if ($Pwsh)
    {
        $PSExec = "$Env:ProgramFiles\PowerShell\7\pwsh.exe"
    }
    else
    {
        $PSExec = "$Env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
    }

    $PSArguments = @()
    $PSArguments += '-NoLogo'
    $PSArguments += '-NoProfile'
    $PSArguments += "-File $Script $Arguments"

    return Start-Process -FilePath $PSExec -ArgumentList $PSArguments -WindowStyle Hidden -PassThru
}

function ConfigPS
{
    param (
        [Parameter()]
        [ValidateSet('Full', 'Profile', 'TerminalStyle', 'ModuleInstall', 'AppInstall', 'StubOnly')]
        [string]
        $Mode = 'Full'
    )

    & "$Env:USERPROFILE\Documents\PowerShell\Scripts\ConfigPS.ps1" -Mode $Mode
}
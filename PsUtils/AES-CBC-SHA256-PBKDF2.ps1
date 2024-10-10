[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [securestring]
    $Passphrase,

    [Parameter(Mandatory = $true, ParameterSetName = "Decrypt")]
    [string]
    $Cipher,
    
    [Parameter(Mandatory = $true, ParameterSetName = "DecryptFile")]
    [string]
    $CipherFile,

    [Parameter(Mandatory = $true, ParameterSetName = "Encrypt")]
    [string]
    $Plain,

    [Parameter(Mandatory = $true, ParameterSetName = "EncryptFile")]
    [string]
    $PlainFile,

    [Parameter()]
    [int]
    $Length = 32
)

function Base64URLEncode($s)
{
    return [System.Convert]::ToBase64String($s).Split('=')[0].Replace('+', '-').Replace('/', '_')
}

function Base64URLDecode($s)
{
    $s = $s.Trim().Replace('-', '+').Replace('_', '/')
    switch ($s.Length % 4)
    {
        0 { break }
        2 { $s += '=='; break }
        3 { $s += '='; break }
        Default { throw 'Invalid Base64URL string' }
    }
    return [System.Convert]::FromBase64String($s)
}

$BaseKey = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes((ConvertFrom-SecureString $Passphrase -AsPlainText)))
$AesObj = [System.Security.Cryptography.AesManaged]::Create()
$AesObj.Mode = [System.Security.Cryptography.CipherMode]::CBC
$AesObj.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7


switch ($PSCmdlet.ParameterSetName) {
    'Encrypt'
    {
        $AesObj.IV = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        $Salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        $DerivedKey = [System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($BaseKey, $Salt, 5000, [System.Security.Cryptography.HashAlgorithmName]::SHA256, $Length)
        $AesObj.Key = $DerivedKey
        $PlainBytes = [System.Text.Encoding]::UTF8.GetBytes($Plain)
        $AesTrans = $AesObj.CreateEncryptor()
        $CipherBytes = $AesTrans.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Count)
        $Result = $AesObj.IV + $Salt + $CipherBytes
        return Base64URLEncode($Result)
    }
    'EncryptFile'
    {
        $AesObj.IV = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        $Salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        $DerivedKey = [System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($BaseKey, $Salt, 5000, [System.Security.Cryptography.HashAlgorithmName]::SHA256, $Length)
        $AesObj.Key = $DerivedKey
        $PlainBytes = [System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path $PlainFile -Raw))
        $AesTrans = $AesObj.CreateEncryptor()
        $CipherBytes = $AesTrans.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Count)
        $Result = $AesObj.IV + $Salt + $CipherBytes
        return Base64URLEncode($Result) 
    }
    'Decrypt'
    {
        $Result = Base64URLDecode($Cipher)
        $AesObj.IV = $Result[0..15]
        $Salt = $Result[16..31]
        $DerivedKey = [System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($BaseKey, $Salt, 5000, [System.Security.Cryptography.HashAlgorithmName]::SHA256, $Length)
        $AesObj.Key = $DerivedKey
        $CipherBytes = $Result[32..($Result.Count - 1)]
        $AesTrans = $AesObj.CreateDecryptor()
        $PlainBytes = $AesTrans.TransformFinalBlock($CipherBytes, 0, $CipherBytes.Count)
        return [System.Text.Encoding]::UTF8.GetString($PlainBytes) 
    }
    'DecryptFile'
    {
        $Result = Base64URLDecode((Get-Content -Path $CipherFile -Raw))
        $AesObj.IV = $Result[0..15]
        $Salt = $Result[16..31]
        $DerivedKey = [System.Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2($BaseKey, $Salt, 5000, [System.Security.Cryptography.HashAlgorithmName]::SHA256, $Length)
        $AesObj.Key = $DerivedKey
        $CipherBytes = $Result[32..($Result.Count - 1)]
        $AesTrans = $AesObj.CreateDecryptor()
        $PlainBytes = $AesTrans.TransformFinalBlock($CipherBytes, 0, $CipherBytes.Count)
        return [System.Text.Encoding]::UTF8.GetString($PlainBytes)
    }
    Default {}
}
function ConvertTo-Utf8
{
    param (
        [Parameter(ValueFromPipeline)][string] $File,
        [string] $Encoding = 'gb2312',
        [switch] $PSEscape,
        [switch] $NewFile
    )

    PROCESS
    {
        if ($PSEscape)
        {
            $File = $File.Replace('`[', '[')
            $File = $File.Replace('`]', ']')
        }
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

function Get-FileProperties
{
    param (
        [Parameter()]
        [string]
        $Path
    )

    $Item = Get-Item $Path -ErrorAction Stop
    $ShellObj = New-Object -com Shell.Application
    
    if ($Item.GetType().ToString() -eq 'System.IO.DirectoryInfo')
    {
        $Folder = $ShellObj.NameSpace($Item.ToString())
        $Folder.Self.InvokeVerb("Properties")
    }
    elseif ($Item.GetType().ToString() -eq 'System.IO.FileInfo')
    {
        $Folder = $ShellObj.NameSpace($Item.Directory.ToString())
        $File = $Folder.ParseName($Item.Name)
        $File.InvokeVerb("Properties")
    }
    else
    {
        throw 'Not a FileSystem Item!'
    }
}

function Convert-HexToString
{
    param (
        [Parameter()]
        [string]
        $HexString
    )

    $CsDef = @'
using System;
public class HexConv
{
    public static byte[] StringToByteArray(string hex)
    {
        if (hex.Length % 2 == 1)
            return null;
        byte[] arr = new byte[hex.Length >> 1];
        for (int i = 0; i < hex.Length >> 1; ++i)
        {
            arr[i] = (byte)((GetHexVal(hex[i << 1]) << 4) + (GetHexVal(hex[(i << 1) + 1])));
        }
        return arr;
    }

    public static int GetHexVal(char hex) {
        int val = (int)hex;
        //For uppercase A-F letters:
        //return val - (val < 58 ? 48 : 55);
        //For lowercase a-f letters:
        //return val - (val < 58 ? 48 : 87);
        //Or the two combined, but a bit slower:
        return val - (val < 58 ? 48 : (val < 97 ? 55 : 87));
    }
}
'@

    Add-Type -TypeDefinition $CsDef -ErrorAction SilentlyContinue
    $HexString = $HexString.Replace(' ', '')
    $HexString = $HexString.Replace(',', '')

    $HexBytes = [HexConv]::StringToByteArray($HexString)
    'ASCII: ' + [System.Text.Encoding]::ASCII.GetString($HexBytes)
    ''
    'Unicode: ' + [System.Text.Encoding]::Unicode.GetString($HexBytes)
}

function Convert-HexToNumber
{
    param (
        [Parameter()]
        [string]
        $HexString
    )

    $Hexes = $HexString.Split(' ')
    foreach ($Hex in $Hexes)
    {
        Write-Host ([Convert]::ToInt32($Hex, 16).ToString() + ' ') -NoNewline
    }
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

function Update-ChocoApps
{
    Start-Process -FilePath $env:windir\System32\cmd.exe -ArgumentList '/K "choco upgrade all -y"'
}
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $HexString,

    [switch]
    $RemoveSpace
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

if ($RemoveSpace)
{
    $HexString = $HexString.Replace(' ', '')
}

$HexBytes = [HexConv]::StringToByteArray($HexString)
[System.Text.Encoding]::Unicode.GetString($HexBytes)
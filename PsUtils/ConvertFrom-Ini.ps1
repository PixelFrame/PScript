[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [string]
    $Ini = "C:\Users\pm421\AppData\Local\Microsoft\OneDrive\settings\Personal\ClientPolicy.ini",

    [Parameter()]
    [ValidateSet('UTF8', 'UTF8BOM', 'UTF8NoBOM', 'UTF7', 'UNICODE', 'ASCII', 'BigEndianUnicode', 'OEM', 'UTF32')]
    [string]
    $Encoding = 'ASCII'
)

$IniContent = Get-Content -Path $Ini -Encoding $Encoding
$HT = @{ }
for ($i = 0; $i -lt $IniContent.Count; ++$i)
{
    if ($IniContent[$i] -match "^\[.*\]$")
    {
        if ($i -eq 0)
        {
            $ItemName = $IniContent[$i].Substring(1, $IniContent[$i].LastIndexOf(']') - 1)
            $ItemHT = @{ }
            continue
        }
        $ItemValue = New-Object PSObject -Property $ItemHT
        $HT += @{$ItemName = $ItemValue }
        $ItemName = $IniContent[$i].Substring(1, $IniContent[$i].LastIndexOf(']') - 1)
        $ItemHT = @{ }
    }
    else
    {
        $IniContent[$i] = $IniContent[$i].Trim()
        if ($IniContent[$i] -eq '')
        {
            continue
        }
        $Property = $IniContent[$i].Split('=')[0]
        $Value = $IniContent[$i].Split('=')[1]
        $ItemHT += @{ $Property = $Value }
        if ($i -eq ($IniContent.Count - 1))
        {
            $ItemValue = New-Object PSObject -Property $ItemHT
            $HT += @{$ItemName = $ItemValue }
        }
    }
}

New-Object PSObject -Property $HT
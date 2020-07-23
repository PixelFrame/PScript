
[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [string]
    $Ini
)
PROCESS
{
    [string[]] $IniLines += $Ini
}
END
{
    for ($i = 0; $i -lt $IniLines.Count; ++$i)
    {
        if ($IniLines[$i] -match "^\[.*\]$")
        {
            if ($i -eq 0)
            {
                $ItemName = $IniLines[$i].Substring(1, $IniLines[$i].LastIndexOf(']') - 1)
                $ItemHT = @{ }
                continue
            }
            $ItemValue = New-Object PSObject -Property $ItemHT
            $HT += @{$ItemName = $ItemValue }
            $ItemName = $IniLines[$i].Substring(1, $IniLines[$i].LastIndexOf(']') - 1)
            $ItemHT = @{ }
        }
        else
        {
            $IniLines[$i] = $IniLines[$i].Trim()
            if ($IniLines[$i] -eq '')
            {
                continue
            }
            $Property = $IniLines[$i].Split('=')[0]
            $Value = $IniLines[$i].Split('=')[1]
            $ItemHT += @{ $Property = $Value }
            if ($i -eq ($IniLines.Count - 1))
            {
                $ItemValue = New-Object PSObject -Property $ItemHT
                $HT += @{$ItemName = $ItemValue }
            }
        }
    }

    return New-Object PSObject -Property $HT
}

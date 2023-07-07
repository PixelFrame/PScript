[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]
    $SearchList,

    [Parameter()]
    $ScopeId,

    [switch]
    $NoCompression
)

$script:suffixTable = [System.Collections.Generic.Dictionary[string, int]]::new()
$result = @()
$index = 0

function CheckTable
{
    param (
        [string] $suffix,
        [int] $index
    )
    if ($script:suffixTable.ContainsKey($suffix))
    {
        return $script:suffixTable[$suffix]
    }
    else
    {
        $script:suffixTable.Add($suffix, $index)
        return -1
    }
}

foreach ($name in $SearchList)
{
    $suffix = $name
    while ($suffix.Length -gt 0)
    {
        $check = CheckTable -suffix $suffix -index $index
        if (!$NoCompression -and $check -ge 0)
        {
            $ptr = 0xC000 -bor $check
            $result += ($ptr -band 0xFF00) -shr 8
            $result += $ptr -band 0x00FF
            $index += 2
            break
        }
        else
        {
            if ($suffix.Contains('.'))
            {
                $seg = $suffix.Substring(0, $suffix.IndexOf('.'))
                if ($seg.Length -gt 0x3F)
                {
                    throw "Invalid domain name `"$seg`""
                }
                $result += $seg.Length
                $result += [System.Text.Encoding]::ASCII.GetBytes($seg)
                $index += $seg.Length + 1
                $suffix = $suffix.Substring($suffix.IndexOf('.') + 1)
            }
            else
            {
                if ($suffix.Length -gt 0x3F)
                {
                    throw "Invalid domain name `"$suffix`""
                }
                $result += $suffix.Length
                $result += [System.Text.Encoding]::ASCII.GetBytes($suffix)
                $result += 0
                $index += $suffix.Length + 2
                $suffix = ''
            }
        }
    }
}

$netshbytes = [System.BitConverter]::ToString($result) -replace '-', ' '
$psbytes = $result -join ','

if ($ScopeId.Length -gt 0)
{
    Write-Host "netsh: netsh dhcp server V4 scope $ScopeId set optionvalue 119 BYTE $netshbytes"
    Write-Host "PowerShell: Set-DhcpServerv4OptionValue -ScopeId $ScopeId -OptionId 119 -Value $psbytes"
}
else
{
    Write-Host "netsh: netsh dhcp server V4 set optionvalue 119 BYTE $netshbytes"
    Write-Host "PowerShell: Set-DhcpServerv4OptionValue -OptionId 119 -Value $psbytes"
}
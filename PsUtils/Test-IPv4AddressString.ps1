param (
    [string]
    $TestStr = '1.0.3.4'
)

$Octets = $TestStr.Trim().Split('.')
if (($Octets.Count -gt 4) -or ($Octets.Count -lt 0))
{
    return $false
}
$IsFirst = $true
foreach ($Octet in $Octets)
{
    [byte] $bOctet = 0
    if ([byte]::TryParse($Octet, [ref] $bOctet))
    {
        if ($bOctet -gt 255)
        {
            return $false
        }
        if ($bOctet -eq 0 -and $IsFirst)
        {
            return $false
        }
    }
    else
    {
        return $false
    }
    $IsFirst = $false
}

return $true
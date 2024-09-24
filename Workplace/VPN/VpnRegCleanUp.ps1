# This Alternative script is for PowerShell running under 32bit to remove the registries in 64bit

$ProfileName = 'VirtLab AlwaysOnVPN'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$SearchKeyword = '/Vendor/MSFT/VPNv2/' + $ProfileNameEscaped
$RegPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked'

$QueryResult = REG.EXE QUERY $RegPath /f $SearchKeyword /s /d /t REG_SZ /reg:64                  # Force querying 64 bit registry

<# 
'[DEBUG] PRINTING QUERY RESULT'
'**************************************************************'
$QueryResult
'**************************************************************'
#>

$IsFoundKey = $false
$Key = ''
$Property = ''
$PendingRemoval = @()

foreach ($line in $QueryResult)
{
    
    if ($IsFoundKey)
    {
        if ($line -eq '')
        {
            $IsFoundKey = $false
            continue
        }
        $Property = $line.Trim().Split(' ')[0]
        $PendingRemoval += [PSCustomObject]@{
            Key      = $Key;
            Property = $Property;
        }
    }
    if ($line.contains($RegPath))
    {
        $IsFoundKey = $true
        $Key = $line
    }
}

<# 
'[DEBUG] PRINTING REMOVAL LIST'
'**************************************************************'
$PendingRemoval
'**************************************************************'
#>

foreach ($removalItem in $PendingRemoval)
{
    'Now Removing ' + $removalItem.Property + ' @ ' + $removalItem.Key
    # REG.EXE DELETE $removalItem.Key /v $removalItem.Property /f /reg:64
}
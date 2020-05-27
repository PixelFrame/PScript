# Current User
# $RASPhone = ( $env:USERPROFILE ) + '\Appdata\Roaming\Microsoft\Network\Connections\Pbk\rasphone.pbk'

# Machine Wide
# $RASPhone = ( $env:ALLUSERSPROFILE ) + '\Microsoft\Network\Connections\Pbk\rasphone.pbk'

$RASPhone = 'D:\rasphone.pbk.txt'
$ProfileName = 'MyVPN'
$Strategy = 14

$RasphoneContent = Get-Content $RASPhone
$ReachedMyVPN = $false
$lineNum = 0

foreach ($line in $RasphoneContent)
{
    if ($ReachedMyVPN)
    {
        if ($line -like 'VpnStrategy=*')
        {
            $RasphoneContent[$lineNum] = "VpnStrategy=$Strategy"
            break
        }
    }
    elseif ($line -eq "[$ProfileName]")
    {
        $ReachedMyVPN = $true
    }
    ++$lineNum
}
$RasphoneContent | Set-Content $RASPhone
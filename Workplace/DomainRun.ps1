$Script = 'choco install wireshark nmap -y'
$LogFile = 'C:\TEMP\'

Get-ADComputer -Filter 'Name -notlike "*cl*"' | ForEach-Object -Parallel {
    $LogFile = $LogFile + $_.Name + '.log'
    Invoke-Command -ScriptBlock $Script -ComputerName $_.Name > $LogFile
}
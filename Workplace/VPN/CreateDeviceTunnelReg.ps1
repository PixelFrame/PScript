$VpnConn = (Get-VpnConnection -AllUserConnection)[0]
if($null -eq $VpnConn)
{
    Write-Host "No VPN connection found"
    exit
}

if (($VpnConn | Measure-Object).Count -gt 1)
{
    Write-Host "More than one VPN connection found"
    $cnt = 1
    foreach ($_ in $VpnConn) {
        Write-Host "$cnt. $($_.Name)"
    }
    $idx = Read-Host "Please select the desired VPN connection: "
    $VpnConn = $VpnConn[$idx-1]
    if ($null -eq $VpnConn)
    {
        Write-Host "Invalid selection"
        exit
    }
}

New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\DeviceTunnel -Force
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\DeviceTunnel -Name "AutoTriggerProfileEntryName" -Value $VpnConn.Name -PropertyType String -Force
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\DeviceTunnel -Name "AutoTriggerProfilePhonebookPath" -Value "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk" -PropertyType String -Force
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\DeviceTunnel -Name "UserSID" -Value "S-1-5-80" -PropertyType String -Force
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\DeviceTunnel -Name "AutoTriggerProfileGUID" -Value ([Guid](Get-VpnConnection -AllUserConnection).Guid).ToByteArray() -PropertyType Binary -Force

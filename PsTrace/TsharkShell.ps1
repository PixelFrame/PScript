if (Test-Path $Env:ProgramFiles\Wireshark)
{
    Set-Location $Env:ProgramFiles\Wireshark
}
else
{
    "Wireshark Installation not found!"
    Pause
    exit
}

function SplitCapture
{
    param (
        [string[]] $Interfaces
    )
    
    $TsharkProcesses = @()
    foreach ($Interface in $Interfaces)
    {
        $InterfaceAlias = $Interface.Substring($Interface.IndexOf('(') + 1, $Interface.LastIndexOf(')') - $Interface.IndexOf('(') - 1)
        $InterfaceId = $Interface.Substring(0, $Interface.IndexOf('.'))
    
        $Outpath = "`"D:\TraceLab\NetTrace_" + $InterfaceAlias + ".pcapng`""
        "Starting capture on interface: " + $InterfaceAlias
        $TsharkProcesses += Start-Process -FilePath '.\tshark.exe' -ArgumentList @('-w ' + $Outpath, '-b filesize:524288', '-i ' + $InterfaceId) -WindowStyle Hidden -PassThru
    }

    return $TsharkProcesses
}

function CombinedCapture
{
    param (
        [string[]] $Interfaces
    )
    
    $DashI = ''
    foreach ($Interface in $Interfaces)
    {
        # $InterfaceAlias = $Interface.Substring($Interface.IndexOf('(') + 1, $Interface.LastIndexOf(')') - $Interface.IndexOf('(') - 1)
        $InterfaceId = $Interface.Substring(0, $Interface.IndexOf('.'))
        $DashI += " -i $InterfaceId"
    }
    $TsharkProcess += Start-Process -FilePath '.\tshark.exe' -ArgumentList @('-w ' + $Outpath, '-b filesize:524288', $DashI) -WindowStyle Hidden -PassThru

    return $TsharkProcess
}

function LaunchAdditionalBatch
{
    param (
        [string] $Script
    )
    
    Start-Process -FilePath 'cmd.exe' -ArgumentList @("/K $Script")
}

$Interfaces = .\tshark.exe -D | Where-Object { $_ -notlike '*loopback*' }

$TsharkProcesses = SplitCapture -Interfaces $Interfaces
LaunchAdditionalBatch -Script 'D:\ScriptLab\hw.bat'

Pause

$TsharkProcesses | Stop-Process
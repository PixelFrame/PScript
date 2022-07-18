[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Etl,
    [Parameter(Mandatory = $true)]
    [ValidateSet('TMF', 'Split', 'pcapng', 'ws-etwdump', 'pktmonpcapng', 'pktmonformat')]
    [string] $Mode
)

$Etl = $Etl.Replace('[', '``[')
$Etl = $Etl.Replace(']', '``]')
$EtlFile = Get-Item $Etl -ErrorAction Suspend
$TMFPath = $Env:PUBLIC + '\TMF'
try
{
    switch ($Mode)
    {
        'TMF'
        {
            if (!(Test-Path $TMFPath))
            {
                throw [System.IO.FileNotFoundException] "$TMFPath not found."
            }
            $OutFile = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-FMT.txt'
            $OutLog = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-netsh_out.txt'
            netsh.exe trace convert input=$EtlFile output=$OutFile dump=txt tmfpath=$TMFPath | Tee-Object -FilePath $OutLog
        }
        'pcapng'
        {
            $OutFile = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '.pcapng'
            $OutLog = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-etl2pcapng_out.txt'
            etl2pcapng.exe $EtlFile $OutFile | Tee-Object -FilePath $OutLog
        }
        'ws-etwdump'
        {
            if (!(Test-Path 'C:\Program Files\Wireshark\extcap\etwdump.exe')) { throw [System.IO.FileNotFoundException] 'etwdump not available' }
            "C: && cd `"C:\Program Files\Wireshark`"
            start .\Wireshark.exe -i etwdump -o `"extcap.etwdump.etlfile:$($EtlFile.FullName)`" -k" | Out-File $env:Temp\startws.bat   # Wireshark will exit with console if it is directly called from console, so have to call it from a batch
            & $env:Temp\startws.bat
        }
        'Split'
        {
            $OutPath = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '_split'
            $OutFile = $OutPath + '\' + $EtlFile.BaseName + '_split.etl'
            $OutLog = $OutPath + '\' + $EtlFile.BaseName + '-EtwSplitter_out.txt'
            [Int32] $FileNum = Read-Host -Prompt "Number of Files"
            New-Item -Path $OutPath -ItemType Directory -Force | Out-Null
            EtwSplitter.exe $EtlFile $OutFile $FileNum | Tee-Object -FilePath $OutLog
        }
        # Update PktMon syntax 
        'pktmonformat'
        {
            if (!(Test-Path $TMFPath))
            {
                throw [System.IO.FileNotFoundException] "$TMFPath not found."
            }
            $OutFile = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-pktmon-FMT.txt'
            $OutLog = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-pktmon_format_out.txt'
            PktMon.exe etl2txt $EtlFile --verbose 3 --tmfpath $TMFPath -out $OutFile | Tee-Object -FilePath $OutLog
        }
        'pktmonpcapng'
        {
            $OutLog = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-pktmon_pcapng_out.txt'
            PktMon.exe etl2pcap $EtlFile | Tee-Object -FilePath $OutLog
        }
        Default {}
    }
}
catch
{
    $Error
    Pause
}
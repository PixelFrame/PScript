[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Etl,
    [Parameter(Mandatory = $true)]
    [ValidateSet('TMF', 'Split', 'pcapng', 'pktmonpcapng', 'pktmonformat')]
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
        'Split'
        {
            $OutPath = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '_split'
            $OutFile = $OutPath + '\' + $EtlFile.BaseName + '_split.etl'
            $OutLog = $OutPath + '\' + $EtlFile.BaseName + '-EtwSplitter_out.txt'
            [Int32] $FileNum = Read-Host -Prompt "Number of Files"
            New-Item -Path $OutPath -ItemType Directory -Force | Out-Null
            EtwSplitter.exe $EtlFile $OutFile $FileNum | Tee-Object -FilePath $OutLog
        }
        # For packet monitor on Windows 20H1
        'pktmonformat'
        {
            $OutLog = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-pktmon_format_out.txt'
            PktMon.exe format $EtlFile -v 3 | Tee-Object -FilePath $OutLog
        }
        'pktmonpcapng'
        {
            $OutLog = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '-pktmon_pcapng_out.txt'
            PktMon.exe pcapng $EtlFile | Tee-Object -FilePath $OutLog
        }
        Default {}
    }
}
catch
{
    $Error
    Pause
}
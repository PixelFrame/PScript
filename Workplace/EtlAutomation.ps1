[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Etl,
    [Parameter(Mandatory = $true)]
    [ValidateSet('TMF', 'Split', 'pcapng')]
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
            netsh.exe trace convert input=$EtlFile output=$OutFile dump=txt tmfpath=$TMFPath
        }
        'pcapng'
        {
            $OutFile = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '.pcapng'
            etl2pcapng.exe $EtlFile $OutFile
        }
        'Split'
        {
            $OutPath = $EtlFile.DirectoryName + '\' + $EtlFile.BaseName + '_split'
            $OutFile = $OutPath + '\' + $EtlFile.BaseName + '_split.etl'
            [Int32] $FileNum = Read-Host -Prompt "Number of Files"
            New-Item -Path $OutPath -ItemType Directory -Force | Out-Null
            EtwSplitter.exe $EtlFile $OutFile $FileNum
        }
        Default {}
    }
}
catch
{
    $Error
    Pause
}
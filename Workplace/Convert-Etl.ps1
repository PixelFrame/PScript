# Convert Event Tracing Log to TraceFormat, NetMon capture or PcapNg

# TMF files required for TraceFormat
# Microsoft Message Analyzer required for NetMon capture
# etl2pcapng required for PcapNg

[CmdletBinding()]
param (
    [ValidateScript( { Test-Path -Path $_ })]
    [string]        $InputPath = '.\',
    [string]        $OutputPath = '.\',
    [switch]        $Exclude,
    [string[]]      $Exclusion = @('NetTrace*', '*PacketCapture*'),
    [bool]          $Recurse = $false,
    [ValidateSet('TMF', 'CAP', 'PCAPNG', '')]
    [string]        $Mode = 'PCAPNG',
    [string]        $TMFPath = $Env:PUBLIC + '\TMF',
    [switch]        $Parallel
)

function ConvertCap
{
    param (
        [Parameter()]
        $ETL
    )

    $WinPS = $Env:SystemRoot + '\System32\WindowsPowerShell\v1.0\powershell.exe'
    $OutputTrace = $OutputPath + $ETL.BaseName + '-PktCap.cap'
    $SessionName = $ETL.BaseName + '_Conversion'
    $Script = "try { Import-Module PEF } catch { throw 'PEF Module Not Found. Make sure Microsoft Message Analyzer is installed.' } 
`$TraceSession = New-PefTraceSession -Mode Linear -Name $SessionName -SaveOnStop -Force -Path $OutputTrace; 
Add-PefMessageSource -PEFSession `$Tracesession -Source $ETL; 
Set-PefTraceFilter -PEFSession `$TraceSession -Filter 'ethernet'; 
Start-PefTraceSession -PEFSession `$TraceSession; 
"

    Start-Process -FilePath $WinPS -ArgumentList "-Command $Script"
}

function ConvertPcapng
{
    param (
        [Parameter()]
        $ETL
    )
    $OutputTrace = $OutputPath + $ETL.BaseName + '-PktCap.pcapng'
    Start-Process -FilePath etl2pcapng.exe -ArgumentList "$ETL $OutputTrace"
}

function ConvertNetsh
{
    param (
        [Parameter()]
        $ETL
    )
    $OutputTxt = $OutputPath + $ETL.BaseName + '-FMT.txt'
    Start-Process -FilePath netsh.exe -ArgumentList "trace convert input=$ETL output=$OutputTxt dump=txt tmfpath=$TMFPath"
}

function DoConversion
{
    switch ($Mode)
    {
        'TMF' 
        { 
            if (Test-Path $TMFPath)
            {
                foreach ($token in $InputETL)
                {
                    ConvertNetsh $token
                }
            }
            else
            {
                throw 'Invalid TMF Path'
            }
        }
        'CAP'
        {
            foreach ($token in $InputETL)
            {
                ConvertCap $token
            }
        }
        'PCAPNG'
        {
            try
            {
                Get-Command etl2pcapng.exe -ErrorAction Stop
            }
            catch
            {
                throw 'etl2pcapng.exe Not Found. Please download from https://github.com/Microsoft/etl2pcapng and put it in PATH.'
            }
            foreach ($token in $InputETL)
            {
                ConvertPcapng $token
            }
        }
        Default 
        { Write-Host 'Nothing To Do' }
    }
}

$SearchPath = $InputPath + '\*.etl'
if ($Exclude -eq $false) { $Exclusion = '' }

Write-Host @"
-----------------------------------------
ETL Automation Convert

Target Type: $Mode
Source: $InputPath
Destination: $OutputPath
Exclusion: $Exclusion
-----------------------------------------
"@

Pause

if ($Recurse)
{
    $InputETL = Get-ChildItem -Path $SearchPath -Exclude $Exclusion -Recurse    
}
else
{
    $InputETL = Get-ChildItem -Path $SearchPath -Exclude $Exclusion
}
if ($null -eq $InputETL)
{
    Write-Warning 'No ETL file found'
    $Mode = ''
}

if (!(Test-Path $OutputPath))
{
    mkdir -Path $OutputPath
}

DoConversion

Write-Host 'Script Completed'
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

    $OutputTrace = $OutputPath + $ETL.BaseName + '-PktCap.cap'
    $SessionName = $ETL.BaseName + '_Conversion'

    $TraceSession = New-PefTraceSession -Mode Linear -Name $SessionName -SaveOnStop -Force -Path $OutputTrace

    Add-PefMessageSource -PEFSession $Tracesession -Source $ETL
    Set-PefTraceFilter -PEFSession $TraceSession -Filter "ethernet"
    Start-PefTraceSession -PEFSession $TraceSession 
}

function ConvertPcapng
{
    param (
        [Parameter()]
        $ETL
    )
    $OutputTrace = $OutputPath + $ETL.BaseName + '-PktCap.pcapng'
    etl2pcapng.exe $ETL $OutputTrace
}

function ConvertNetsh
{
    param (
        [Parameter()]
        $ETL
    )
    $OutputTxt = $OutputPath + $ETL.BaseName + '-FMT.txt'
    netsh.exe trace convert input=$ETL output=$OutputTxt dump=txt tmfpath=$TMFPath
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
            try
            {
                Import-Module PEF
            }
            catch
            {
                throw 'PEF Module Not Found. Make sure Microsoft Message Analyzer is installed.'
            }
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

function DoConversionParallel
{
    switch ($Mode)
    {
        'TMF' 
        {
            if (Test-Path $TMFPath)
            {
                ForEach-Object -Parallel -InputObject $InputETL
                {
                    Write-Host "Converting $_.Name"
                    ConvertNetsh $_
                }
            }
            else
            {
                throw -Message 'Invalid TMF Path'
            }
        }
        'CAP'
        {
            try
            {
                Import-Module PEF
            }
            catch
            {
                throw 'PEF Module Missing. Make sure Microsoft Message Analyzer is installed.'
            }
            ForEach-Object -Parallel -InputObject $InputETL
            {
                Write-Host "Converting $_.Name"
                ConvertCap $_
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
                throw 'etl2pcapng.exe Missing. Please download from https://github.com/Microsoft/etl2pcapng and put it in PATH.'
            }
            ForEach-Object -Parallel -InputObject $InputETL
            {
                Write-Host "Converting $_.Name"
                ConvertPcapng $_
            }
        }
        Default 
        { Write-Host 'Nothing To Do' }
    }
}

Write-Host @"
-----------------------------------------
ETL Automation Convert

Target Type: $Mode
Source: $InputPath
Destination: $OutputPath
-----------------------------------------
"@

Pause

$SearchPath = $InputPath + '\*.etl'
if ($Exclude -eq $false) { $Exclusion = '' }
$InputETL = Get-ChildItem -Path $SearchPath -Exclude $Exclusion -Recurse $Recurse
if ($null -eq $InputETL)
{
    Write-Warning 'No ETL file found'
    $Mode = ''
}

if (!(Test-Path $OutputPath))
{
    mkdir -Path $OutputPath
}

if ($Parallel)
{
    if ($PSVersionTable.PSVersion.Major -lt 7)
    {
        throw 'Parallel Mode is Only Available with PowerShell 7 or Later Version'
    }
    Write-Host 'Running in Parallel Mode'
    DoConversionParallel
}
else
{ DoConversion }
#Requires -RunAsAdministrator

function Write-Registry
{
    param (
        [Parameter()] [string] $StubPath
    )
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    try
    {
        $EtlProperty = Get-ItemPropertyValue 'HKCR:\.etl' -Name '(default)' -ErrorAction Stop
    }
    catch
    {
        New-ItemProperty -Path 'HKCR:\.etl' -Name '(default)'
        Set-ItemProperty 'HKCR:\.etl' -Name '(default)' -Value 'etl_auto_file'
        $EtlProperty = 'etl_auto_file'
    }
    
    [string[]] $ClassPaths = "HKCR:\$EtlProperty"
    $ClassPaths += "HKCR:\.etl"
    $ClassPaths += "HKCR:\SystemFileAssociations\.etl"
    foreach ($ClassPath in $ClassPaths)
    {
        if (!(Test-Path $ClassPath\'shell')) { (New-Item $ClassPath\'shell' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Convert with TMF')) { (New-Item $ClassPath\'shell\Convert with TMF' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Convert with TMF\command')) { (New-Item $ClassPath\'shell\Convert with TMF\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Convert with TMF\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode TMF" -Force

        if (!(Test-Path $ClassPath\'shell\Split Trace')) { (New-Item $ClassPath\'shell\Split Trace' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Split Trace\command')) { (New-Item $ClassPath\'shell\Split Trace\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Split Trace\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode Split" -Force
    
        if (!(Test-Path $ClassPath\'shell\Convert to pcapng')) { (New-Item $ClassPath\'shell\Convert to pcapng' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Convert to pcapng\command')) { (New-Item $ClassPath\'shell\Convert to pcapng\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Convert to pcapng\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode pcapng" -Force
        
        if (!(Test-Path $ClassPath\'shell\Convert to pcapng (pktmon)')) { (New-Item $ClassPath\'shell\Convert to pcapng (pktmon)' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Convert to pcapng (pktmon)\command')) { (New-Item $ClassPath\'shell\Convert to pcapng (pktmon)\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Convert to pcapng (pktmon)\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode pktmonpcapng" -Force
        
        if (!(Test-Path $ClassPath\'shell\Format (pktmon)')) { (New-Item $ClassPath\'shell\Format (pktmon)' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Format (pktmon)\command')) { (New-Item $ClassPath\'shell\Format (pktmon)\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Format (pktmon)\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode pktmonformat" -Force
    }
}

function Write-StubScript
{
    param (
        [Parameter()] [string] $StubPath,
        [Parameter()] [string] $TMF
    )
    $StubScript = @"
[CmdletBinding()]
param (
    [Parameter(Mandatory = `$true)]
    [string] `$Etl,
    [Parameter(Mandatory = `$true)]
    [ValidateSet('TMF', 'Split', 'pcapng', 'pktmonpcapng', 'pktmonformat')]
    [string] `$Mode
)

`$Etl = `$Etl.Replace('[', '````[')
`$Etl = `$Etl.Replace(']', '````]')
`$EtlFile = Get-Item `$Etl
`$TMFPath = '$TMF'

try
{
    switch (`$Mode)
    {
        'TMF'
        {
            if (!(Test-Path `$TMFPath))
            {
                throw [System.IO.FileNotFoundException] "`$TMFPath not found."
            }
            `$OutFile = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-FMT.txt'
            `$OutLog = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-netsh_out.txt'
            netsh.exe trace convert input=`$EtlFile output=`$OutFile dump=txt tmfpath=`$TMFPath | Tee-Object -FilePath `$OutLog
        }
        'pcapng'
        {
            `$OutFile = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '.pcapng'
            `$OutLog = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-etl2pcapng_out.txt'
            etl2pcapng.exe `$EtlFile `$OutFile | Tee-Object -FilePath `$OutLog
        }
        'Split'
        {
            `$OutPath = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '_split'
            `$OutFile = `$OutPath + '\' + `$EtlFile.BaseName + '_split.etl'
            `$OutLog = `$OutPath + '\' + `$EtlFile.BaseName + '-EtwSplitter_out.txt'
            [Int32] `$FileNum = Read-Host -Prompt "Number of Files"
            New-Item -Path `$OutPath -ItemType Directory -Force | Out-Null
            EtwSplitter.exe `$EtlFile `$OutFile `$FileNum | Tee-Object -FilePath `$OutLog
        }
        
        'pktmonformat'
        {
            `$OutLog = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-pktmon_format_out.txt'
            PktMon.exe format `$EtlFile -v 3 | Tee-Object -FilePath `$OutLog
        }
        'pktmonpcapng'
        {
            `$OutLog = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-pktmon_pcapng_out.txt'
            PktMon.exe pcapng `$EtlFile | Tee-Object -FilePath `$OutLog
        }
        Default {}
    }
}
catch
{
    `$Error
    Pause
}
"@
    Out-File -FilePath $StubPath -Encoding utf8 -InputObject $StubScript -Force
}

function Write-Bin
{
    $Uris = @('https://github.com/microsoft/etl2pcapng/releases/download/v1.4.0/etl2pcapng.zip', 'https://github.com/ryanries/ETWSplitter/releases/download/v1.0/ETWSplitter.exe')
    $Retry = 3
    $WebClient = New-Object System.Net.WebClient

    $Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    $Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    $WebClient.Proxy = $Proxy

    foreach ($Uri in $Uris)
    {
        $FileName = $Uri.Substring($Uri.LastIndexOf('/') + 1)
        $DestPath = (Resolve-Path '~').Path + '\' + $FileName

        $AttemptCount = 0
        Do
        {
            $AttemptCount++
            "Downloading $FileName @ $AttemptCount"
            try
            {
                $WebClient.DownloadFile($Uri, $DestPath)
            }
            catch
            {
                "Error happend during downloading!"
                $_
            }
        } while (!(Test-Path $DestPath) -and ($AttemptCount -lt $Retry))
    }

    if ((Test-Path ~\EtwSplitter.exe) -and (Test-Path ~\etl2pcapng.zip))
    {
        Move-Item -Path ~\EtwSplitter.exe -Destination $env:SystemRoot\EtwSplitter.exe -Force
        Expand-Archive -Path ~\etl2pcapng.zip -DestinationPath ~\
        Move-Item -Path ~\etl2pcapng\x64\etl2pcapng.exe -Destination $env:SystemRoot\etl2pcapng.exe -Force
    }
    else
    {
        "Download Failed! Please manually download etl2pcapng and ETWSplitter and move them to environment PATH"
    }
    Remove-Item -Path ~\etl2pcapng.zip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ~\etl2pcapng -Recurse -Force -ErrorAction SilentlyContinue
}

## START OF SCRIPT ##

$StubPath = '!'
while (!(Test-Path $StubPath))
{
    $StubPath = Read-Host "Where do you want to save the stub script file? (Default - $env:SystemRoot)"
    if ('' -eq $StubPath)
    {
        $StubPath = $env:SystemRoot
    }
}

$TMF = '!'
while (!(Test-Path $TMF))
{
    $TMF = Read-Host "Where is your TMF stored? (Default - $env:PUBLIC\TMF)"
    if ('' -eq $TMF)
    {
        $TMF = $env:PUBLIC + '\TMF'
    }
}

$StubPath += '\EtlAutomation.ps1'

Write-Host "Writing Stub File"
Write-StubScript -StubPath $StubPath -TMF $TMF

Write-Host "Registering to Right Click Menu"
Write-Registry -StubPath $StubPath

try
{
    Get-Command etl2pcapng.exe -ErrorAction Stop | Out-Null
    Get-Command ETWSplitter.exe -ErrorAction Stop | Out-Null
    "etl2pcapng and ETWSplitter found! Skipped downloading."
}
catch
{
    "Downloading etl2pcapng and ETWSplitter to $env:SystemRoot"
    Write-Bin
}
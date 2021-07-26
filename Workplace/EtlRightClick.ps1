[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Deconfig,

    [Parameter()]
    [bool]
    $UserMode = $true
)

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
        New-Item 'HKCR:\.etl' -Force | Out-Null
        New-ItemProperty -Path 'HKCR:\.etl' -Name '(default)'
        Set-ItemProperty 'HKCR:\.etl' -Name '(default)' -Value 'etl_auto_file'
        $EtlProperty = 'etl_auto_file'
    }
    
    Set-ItemProperty -Path 'HKCR:\.etl' -Name 'EtlStubPath' -Value $StubPath

    $StubPath += '\EtlAutomation.ps1'

    [string[]] $ClassPaths = "HKCR:\$EtlProperty"
    $ClassPaths += "HKCR:\.etl"
    $ClassPaths += "HKCR:\SystemFileAssociations\.etl"
    foreach ($ClassPath in $ClassPaths)
    {
        if (!(Test-Path $ClassPath\'shell')) { (New-Item $ClassPath\'shell' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Format (netsh)')) { (New-Item $ClassPath\'shell\Format (netsh)' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Format (netsh)\command')) { (New-Item $ClassPath\'shell\Format (netsh)\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Format (netsh)\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode TMF" -Force

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

function Write-RegistryUser
{
    param (
        [Parameter()] [string] $StubPath
    )
    try
    {
        $EtlProperty = Get-ItemPropertyValue 'HKCU:\SOFTWARE\Classes\.etl' -Name '(default)' -ErrorAction Stop
    }
    catch
    {
        New-Item 'HKCU:\SOFTWARE\Classes\.etl' -Force | Out-Null
        New-ItemProperty -Path 'HKCU:\SOFTWARE\Classes\.etl' -Name '(default)'
        Set-ItemProperty 'HKCU:\SOFTWARE\Classes\.etl' -Name '(default)' -Value 'etl_auto_file'
        $EtlProperty = 'etl_auto_file'
    }

    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Classes\.etl' -Name 'EtlStubPath' -Value $StubPath

    $StubPath += '\EtlAutomation.ps1'

    [string[]] $ClassPaths = "HKCU:\SOFTWARE\Classes\$EtlProperty"
    $ClassPaths += "HKCU:\SOFTWARE\Classes\.etl"
    $ClassPaths += "HKCU:\SOFTWARE\Classes\SystemFileAssociations\.etl"
    
    foreach ($ClassPath in $ClassPaths)
    {
        if (!(Test-Path $ClassPath\'shell')) { (New-Item $ClassPath\'shell' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Format (netsh)')) { (New-Item $ClassPath\'shell\Format (netsh)' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Format (netsh)\command')) { (New-Item $ClassPath\'shell\Format (netsh)\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Format (netsh)\command' -Name '(default)' -Value "PowerShell.exe -NoProfile -File `"$StubPath`" -Etl `"%1`" -Mode TMF" -Force

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

function Remove-Registry
{
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    [string[]] $ClassPaths = "HKCR:\.etl"
    try
    {
        $EtlProperty = Get-ItemPropertyValue 'HKCR:\.etl' -Name '(default)' -ErrorAction Stop
        $ClassPaths += "HKCR:\$EtlProperty"
    }
    catch
    {
        "No ETL Class!"
    }
    $ClassPaths += "HKCR:\SystemFileAssociations\.etl"
    foreach ($ClassPath in $ClassPaths)
    {
        if ((Test-Path $ClassPath\'shell\Format (netsh)')) { Remove-Item $ClassPath\'shell\Format (netsh)' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Format (pktmon)')) { Remove-Item $ClassPath\'shell\Format (pktmon)' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Split Trace')) { Remove-Item $ClassPath\'shell\Split Trace' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Convert to pcapng')) { Remove-Item $ClassPath\'shell\Convert to pcapng' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Convert to pcapng (pktmon)')) { Remove-Item $ClassPath\'shell\Convert to pcapng (pktmon)' -Recurse -Force }
    }
    Remove-ItemProperty -Path "HKCR:\.etl" -Name 'EtlStubPath'
}

function Remove-RegistryUser
{
    [string[]] $ClassPaths = "HKCU:\SOFTWARE\Classes\.etl"
    try
    {
        $EtlProperty = Get-ItemPropertyValue 'HKCU:\SOFTWARE\Classes\.etl' -Name '(default)' -ErrorAction Stop
        $ClassPaths += "HKCU:\SOFTWARE\Classes\$EtlProperty"
    }
    catch
    {
        "No ETL Class!"
    }
    $ClassPaths += "HKCU:\SOFTWARE\Classes\SystemFileAssociations\.etl"
    foreach ($ClassPath in $ClassPaths)
    {
        if ((Test-Path $ClassPath\'shell\Format (netsh)')) { Remove-Item $ClassPath\'shell\Format (netsh)' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Format (pktmon)')) { Remove-Item $ClassPath\'shell\Format (pktmon)' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Split Trace')) { Remove-Item $ClassPath\'shell\Split Trace' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Convert to pcapng')) { Remove-Item $ClassPath\'shell\Convert to pcapng' -Recurse -Force }
        if ((Test-Path $ClassPath\'shell\Convert to pcapng (pktmon)')) { Remove-Item $ClassPath\'shell\Convert to pcapng (pktmon)' -Recurse -Force }
    }
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Classes\.etl" -Name 'EtlStubPath'
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
            if (!(Test-Path `$TMFPath))
            {
                throw [System.IO.FileNotFoundException] "`$TMFPath not found."
            }
            `$OutFile = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-pktmon-FMT.txt'
            `$OutLog = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-pktmon_format_out.txt'
            PktMon.exe etl2txt `$EtlFile --verbose 3 --tmfpath `$TMFPath --out `$OutFile | Tee-Object -FilePath `$OutLog
        }
        'pktmonpcapng'
        {
            `$OutLog = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '-pktmon_pcapng_out.txt'
            PktMon.exe etl2pcap `$EtlFile | Tee-Object -FilePath `$OutLog
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
    Out-File -FilePath ($StubPath + '\EtlAutomation.ps1') -Encoding utf8 -InputObject $StubScript -Force
}

function Get-LatestRelease 
{
    $E2PApiUri = 'https://api.github.com/repos/microsoft/etl2pcapng/releases/latest'
    $ESApiUri = 'https://api.github.com/repos/ryanries/ETWSplitter/releases/latest'

    try
    {
        $E2PResponse = Invoke-WebRequest -Uri $E2PApiUri -ErrorAction Stop
        $E2PDownloadUrl = (($E2PResponse.Content | ConvertFrom-Json).assets | Where-Object { $_.name -eq 'etl2pcapng.zip' })[0].browser_download_url
    }
    catch
    {
        "Fail to retrieve latest etl2pcapng download link! Fallback to v1.5.0"
        $_[0]
        $E2PDownloadUrl = 'https://github.com/microsoft/etl2pcapng/releases/download/1.5.0/etl2pcapng.zip'
    } 

    try
    {
        $ESResponse = Invoke-WebRequest -Uri $ESApiUri -ErrorAction Stop
        $ESDownloadUrl = (($ESResponse.Content | ConvertFrom-Json).assets | Where-Object { $_.name -eq 'ETWSplitter.exe' })[0].browser_download_url
    }
    catch
    {
        "Fail to retrieve latest ETWSplitter download link! Fallback to v1.0"
        $_[0]
        $ESDownloadUrl = 'https://github.com/ryanries/ETWSplitter/releases/download/v1.0/ETWSplitter.exe'
    }

    return @($E2PDownloadUrl, $ESDownloadUrl)
}

function Write-Bin
{
    param (
        [Parameter()] [string] $StubPath,
        [Parameter()] [bool] $UserMode
    )

    if ($UserMode)
    {
        $UserEnvPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($UserEnvPath.Split(';') -notcontains $StubPath)
        {
            "Adding stub file path $StubPath to user environment PATH"
            $UserEnvPath += ";$StubPath"
            [System.Environment]::SetEnvironmentVariable("Path", $UserEnvPath, "User")
        }
    }
    else
    {
        $MachineEnvPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($UserEnvPath.Split(';') -notcontains $StubPath)
        {
            "Adding stub file path $StubPath to Machine environment PATH"
            $MachineEnvPath += ";$StubPath"
            [System.Environment]::SetEnvironmentVariable("Path", $MachineEnvPath, "Machine")
        }
    }


    $Uris = Get-LatestRelease
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
                $_[0]
            }
        } while (!(Test-Path $DestPath) -and ($AttemptCount -lt $Retry))
    }

    if ((Test-Path ~\EtwSplitter.exe) -and (Test-Path ~\etl2pcapng.zip))
    {
        Move-Item -Path ~\EtwSplitter.exe -Destination $StubPath\EtwSplitter.exe -Force
        Expand-Archive -Path ~\etl2pcapng.zip -DestinationPath ~\
        Move-Item -Path ~\etl2pcapng\x64\etl2pcapng.exe -Destination $StubPath\etl2pcapng.exe -Force
    }
    else
    {
        "Download Failed! Please manually download etl2pcapng and ETWSplitter and move them to environment PATH"
    }
    Remove-Item -Path ~\etl2pcapng.zip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path ~\etl2pcapng -Recurse -Force -ErrorAction SilentlyContinue
}

## START OF SCRIPT ##

if ($Deconfig)
{
    if ($UserMode)
    {
        $StubPath = Get-ItemPropertyValue -Path 'HKCU:\SOFTWARE\Classes\.etl' -Name 'EtlStubPath' -ErrorAction SilentlyContinue
        if (Test-Path $StubPath)
        {
            "Stub file path: $StubPath"
            $IsRemoveStub = Read-Host "Do you want to remove stub file path? Y/N"
            if ($IsRemoveStub -in @('y', 'Y'))
            {
                Remove-Item -Path $StubPath -Recurse -Force
            }
            $IsRemoveStubFromPath = Read-Host "Do you want to remove stub file path from Environment Path? Y/N"
            if ($IsRemoveStubFromPath -in @('y', 'Y'))
            {
                $UserEnvPath = ([System.Environment]::GetEnvironmentVariable("Path", "User").Split(';') | Where-Object { $_ -ne $StubPath }) -join ';'
                [System.Environment]::SetEnvironmentVariable("Path", $UserEnvPath, "User")
            }
        }
        'Removing Shell Reigstration!'
        Remove-RegistryUser
    }
    else
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        $StubPath = Get-ItemPropertyValue -Path 'HKCR:\.etl' -Name 'EtlStubPath' -ErrorAction SilentlyContinue
        if (Test-Path $StubPath)
        {
            "Stub file path: $StubPath"
            $IsRemoveStub = Read-Host "Do you want to remove stub file path? Y/N"
            if ($IsRemoveStub -in @('y', 'Y'))
            {
                Remove-Item -Path $StubPath -Recurse -Force
            }
            $IsRemoveStubFromPath = Read-Host "Do you want to remove stub file path from Environment Path? Y/N"
            if ($IsRemoveStubFromPath -in @('y', 'Y'))
            {
                $MachineEnvPath = ([System.Environment]::GetEnvironmentVariable("Path", "Machine").Split(';') | Where-Object { $_ -ne $StubPath }) -join ';'
                [System.Environment]::SetEnvironmentVariable("Path", $UserEnvPath, "Machine")
            }
        }
        else
        {
            "Invalid stub file path: $StubPath"
        }
        'Removing Shell Reigstration!'
        Remove-Registry
    }
    Pause; exit
}

$StubPath = Read-Host "Where do you want to save the stub script file and the tools? (Default: $env:USERPROFILE\Tools, path will be created if not exist)"
if ('' -eq $StubPath)
{
    $StubPath = $env:USERPROFILE + '\Tools'
}
if (!(Test-Path $StubPath))
{
    try
    {
        mkdir $StubPath -ErrorAction Stop | Out-Null
    }
    catch
    {
        "Unable to create stub file path: $StubPath"
        Pause; exit
    }
}


$TMF = '!'
while (!(Test-Path $TMF))
{
    if ('!' -ne $TMF)
    {
        "Path Not Found: $TMF"
    }
    $TMF = Read-Host "Where is your TMF stored? (Default - $env:PUBLIC\TMF)"
    if ('' -eq $TMF)
    {
        $TMF = $env:PUBLIC + '\TMF'
    }
}

Write-Host "Writing Stub File"
Write-StubScript -StubPath $StubPath -TMF $TMF

Write-Host "Registering to Right Click Menu"
if ($UserMode)
{
    Write-RegistryUser -StubPath $StubPath
}
else
{
    Write-Registry -StubPath $StubPath
}

try
{
    Get-Command etl2pcapng.exe -ErrorAction Stop | Out-Null
    Get-Command ETWSplitter.exe -ErrorAction Stop | Out-Null
    "etl2pcapng and ETWSplitter found! Skipped downloading."
}
catch
{
    "Downloading etl2pcapng and ETWSplitter to $StubPath"
    Write-Bin -StubPath $StubPath -UserMode $UserMode
}

Pause
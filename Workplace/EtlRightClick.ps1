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
        Set-ItemProperty -Path $ClassPath\'shell\Convert with TMF\command' -Name '(default)' -Value "PowerShell.exe -File `"$StubPath`" -Etl `"%1`" -Mode TMF" -Force

        if (!(Test-Path $ClassPath\'shell\Split Trace')) { (New-Item $ClassPath\'shell\Split Trace' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Split Trace\command')) { (New-Item $ClassPath\'shell\Split Trace\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Split Trace\command' -Name '(default)' -Value "PowerShell.exe -File `"$StubPath`" -Etl `"%1`" -Mode Split" -Force
    
        if (!(Test-Path $ClassPath\'shell\Convert to pcapng')) { (New-Item $ClassPath\'shell\Convert to pcapng' -Force).Name }
        if (!(Test-Path $ClassPath\'shell\Convert to pcapng\command')) { (New-Item $ClassPath\'shell\Convert to pcapng\command' -Force).Name }
        Set-ItemProperty -Path $ClassPath\'shell\Convert to pcapng\command' -Name '(default)' -Value "PowerShell.exe -File `"$StubPath`" -Etl `"%1`" -Mode pcapng" -Force
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
    [ValidateSet('TMF', 'Split', 'pcapng')]
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
            netsh.exe trace convert input=`$EtlFile output=`$OutFile dump=txt tmfpath=`$TMFPath
        }
        'pcapng'
        {
            `$OutFile = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '.pcapng'
            etl2pcapng.exe `$EtlFile `$OutFile
        }
        'Split'
        {
            `$OutPath = `$EtlFile.DirectoryName + '\' + `$EtlFile.BaseName + '_split'
            `$OutFile = `$OutPath + '\' + `$EtlFile.BaseName + '_split.etl'
            [Int32] `$FileNum = Read-Host -Prompt "Number of Files"
            New-Item -Path `$OutPath -ItemType Directory -Force | Out-Null
            EtwSplitter.exe `$EtlFile `$OutFile `$FileNum
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

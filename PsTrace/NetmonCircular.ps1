[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $OutPath = 'C:\NetCap',

    [Parameter()]
    [int]
    $NumOfTrace = 10,

    [Parameter()]
    [int]
    $Size = 512,

    [Parameter()]
    [string]
    $CaptureFilter = ''
)

if (!(Test-Path $OutPath))
{
    try
    {
        mkdir $OutPath
    }
    catch
    {
        Write-Host "Output path cannot be created!" -ForegroundColor Red
        Exit
    }
}
if ((Get-ChildItem $OutPath\*.cap).Count -ne 0)
{
    while ($true) 
    {
        $Confirm = Read-Host "Existing CAP files in destination folder. Backup the files or remove? B/R"
        if ($Confirm -eq "B" -or $Confirm -eq "b")
        {
            mkdir $OutPath\CapBackup | Out-Null
            Move-Item $OutPath\*.cap $OutPath\CapBackup
            "Backed up files to " + $OutPath + "\CapBackup\"
            break
        }
        if ($Confirm -eq "R" -or $Confirm -eq "r")
        {
            Remove-Item $OutPath\*.cap
            break
        }
    }
}
Set-Location -Path "$env:ProgramFiles\Microsoft Network Monitor 3"
$Argument = "/useprofile 2 /network * /capture $CaptureFilter /file E:\NetCap\NetTraceNM.chn:" + $Size + "M /stopwhen /frame IPv4.Address == 4.3.2.1"
Start-Process -FilePath .\nmcap.exe -ArgumentList $Argument
Set-Location -Path $OutPath

"Press F12 to stop trace"
$continue = $true
while ($continue)
{
    if ([console]::KeyAvailable)
    {
        "Press F12 to stop trace"
        $x = [System.Console]::ReadKey() 
        switch ( $x.key)
        {
            F12 { $continue = $false }
        }
    } 
    else
    {
        $TraceFiles = Get-ChildItem .\*.cap | Sort-Object -Property CreationTime
        if ($TraceFiles.Count -gt $NumOfTrace)
        {
            $Prompt = "Purge File: " + $TraceFiles[0]
            Write-Host $Prompt -ForegroundColor Yellow
            Remove-Item -Path $TraceFiles[0]
        }
    }    
}
ping.exe 4.3.2.1
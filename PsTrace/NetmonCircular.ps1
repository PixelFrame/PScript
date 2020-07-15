[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $OutPath = 'C:\NetCap',

    [Parameter()]
    [int]
    $NumOfFile = 10,

    [Parameter()]
    [int]
    $Size = 512,

    [Parameter()]
    [string]
    $CaptureFilter = '',

    [Parameter()]
    [int]
    $Parser = 2,

    [Parameter()]
    [int]
    $PullInterval = 1
)

if (!(Test-Path $OutPath))
{
    try
    {
        mkdir $OutPath | Out-Null
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
            if (!(Test-Path $OutPath\CapBackup))
            { mkdir $OutPath\CapBackup | Out-Null }
            Move-Item $OutPath\*.cap $OutPath\CapBackup
            "Backed up files to " + $OutPath + "\CapBackup\`n"
            break
        }
        if ($Confirm -eq "R" -or $Confirm -eq "r")
        {
            Remove-Item $OutPath\*.cap
            "Removed files`n"
            break
        }
    }
}

Write-Host "NetMon Circular Capture"
Write-Host "-------------------------------------------------"
Write-Host " > Output Path: $OutPath"
Write-Host " > Num of Files to be Kept: $NumOfFile"
Write-Host " > Size of Each File: $Size MB"
Write-Host " > Capture Filter: $CaptureFilter"
Write-Host " > Parser ID: $Parser"
Write-Host " > Pull Interval: $PullInterval sec"
Write-Host "-------------------------------------------------"
Write-Host ""
Write-Host "Press Enter to Start Capture." -ForegroundColor White -BackgroundColor Green
Write-Host "Press F12 to Stop Capture.   " -ForegroundColor White -BackgroundColor Green
Read-Host

$Argument = "/UseProfile 2 /Network * /Capture $CaptureFilter /file $OutPath\NetTraceNM.chn:" + $Size + "M /CaptureProcesses /StopWhen /Frame IPv4.Address == 4.3.2.1 AND ICMP"
Write-Host "Calling NetMon" -ForegroundColor White -BackgroundColor Green
Write-Host "CommandLine: $env:ProgramFiles\Microsoft Network Monitor 3\nmcap.exe $Argument" -ForegroundColor White -BackgroundColor Green
Start-Process -FilePath "$env:ProgramFiles\Microsoft Network Monitor 3\nmcap.exe" -ArgumentList $Argument -WindowStyle Minimized

$Continue = $true
while ($Continue)
{
    if ([console]::KeyAvailable)
    {
        if ([System.Console]::ReadKey().Key -eq 'F12')
        {
            "F12 Pressed. Pinging 4.3.2.1 to stop capture."
            $Continue = $false
        }
        else
        {
            "Press F12 to Stop Capture"
        }
    } 
    else
    {
        $TraceFiles = Get-ChildItem $OutPath\*.cap | Sort-Object -Property CreationTime
        if ($TraceFiles.Count -gt $NumOfFile)
        {
            $Prompt = "Purging File: " + $TraceFiles[0]
            Write-Host $Prompt -ForegroundColor Yellow
            Remove-Item -Path $TraceFiles[0]
        }
        else
        {
            "File Limit Not Reached. Sleeping for $PullInterval sec."
            Start-Sleep -Milliseconds ($PullInterval * 1000 - 100)
        }
    }
    Start-Sleep -Milliseconds 100 # Key Read Interval to Save CPU Usage.
}
Start-Process $OutPath
ping.exe 4.3.2.1
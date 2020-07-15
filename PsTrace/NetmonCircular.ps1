[CmdletBinding()]
param (
    [Parameter()] [string] $OutPath = 'C:\NetCap',
    [Parameter()] [int]    $NumOfFile = 10,
    [Parameter()] [int]    $Size = 512,
    [Parameter()] [string] $CaptureFilter = '',
    [Parameter()] [int]    $ParserId = 2,
    [Parameter()] [int]    $PullInterval = 1
)

if (!(Test-Path "$env:ProgramFiles\Microsoft Network Monitor 3"))
{
    Write-Host "Microsoft Network Monitor 3 Not Installed!" -ForegroundColor Red
    Write-Host "Download and Install NetMon at http://go.microsoft.com/fwlink/?linkid=220643" -ForegroundColor Red
    Exit
}
if (!(Get-NetAdapterBinding).ComponentID.Contains('ms_netmon'))
{
    Write-Host "Microsoft Network Monitor 3 Driver is Not Bound on Any Network Adapter!" -ForegroundColor Red
    Write-Host "Reinstall NetMon or Launch the Script as Administrator and Try Again" -ForegroundColor Red
    Exit
}
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
            $BackupFolder = $OutPath + '\CapBackup_' + (Get-Date -Format 'yyyy-MM-dd_hhmmss')
            mkdir $BackupFolder | Out-Null
            Move-Item $OutPath\*.cap $BackupFolder
            "Backed up files to $BackupFolder `n"
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
Write-Host " > Output Path:             $OutPath"
Write-Host " > Num of Files to be Kept: $NumOfFile"
Write-Host " > Size of Each File:       $Size MB"
Write-Host " > Capture Filter:          $CaptureFilter"
Write-Host " > Parser Profile ID:               $ParserId"
Write-Host " > Pull Interval:           $PullInterval sec"
Write-Host "-------------------------------------------------"
Write-Host ""
Write-Host "Press Enter to Start Capture." -ForegroundColor White -BackgroundColor Green
Write-Host "Press F12 to Stop Capture.   " -ForegroundColor White -BackgroundColor Green
Read-Host

$Argument = "/UseProfile $Parser /Network * /Capture $CaptureFilter /file $OutPath\NetTraceNM.chn:" + $Size + "M /CaptureProcesses /StopWhen /Frame IPv4.Address == 4.3.2.1 AND ICMP"
Write-Host "Calling NetMon" -ForegroundColor White -BackgroundColor Green
Write-Host "CommandLine: $env:ProgramFiles\Microsoft Network Monitor 3\nmcap.exe $Argument" -ForegroundColor White -BackgroundColor Green
$NmcapProcess = Start-Process -FilePath "$env:ProgramFiles\Microsoft Network Monitor 3\nmcap.exe" -ArgumentList $Argument -WindowStyle Hidden -PassThru

$Continue = $true
while ($Continue)
{
    if ([console]::KeyAvailable)
    {
        if ([System.Console]::ReadKey().Key -eq 'F12')
        {
            Write-Host "`nF12 Pressed. Pinging 4.3.2.1 to stop capture."
            $Continue = $false
        }
        else
        {
            Write-Host "Press F12 to Stop Capture"
        }
    } 
    else
    {
        $TraceFiles = Get-ChildItem $OutPath\*.cap | Sort-Object -Property CreationTime
        if ($TraceFiles.Count -gt $NumOfFile)
        {
            $Prompt = "`nPurging File: " + $TraceFiles[0] + "`n"
            Write-Host $Prompt -ForegroundColor Yellow
            Remove-Item -Path $TraceFiles[0]
        }
        else
        {
            Write-Host '.' -NoNewline
            Start-Sleep -Milliseconds ($PullInterval * 1000 - 100)
        }
    }
    if ($NmcapProcess.HasExited) 
    {
        Write-Host "`nNMCap Process Exited Unexpectedly! Script Terminated!" -ForegroundColor Red
        Write-Host "This could caused by an unexpected ICMP packet to/from IP address 4.3.2.1 or crash of NMCap process" -ForegroundColor Red
        Exit
    }
    Start-Sleep -Milliseconds 100 # Key Read Interval to Save CPU Usage.
}
Start-Process $OutPath
ping.exe 4.3.2.1 -n 1 | Out-Null
[CmdletBinding()]
param (
    [Parameter()] [string] $OutPath = 'C:\NetCap',
    [Parameter()] [int]    $NumOfFile = 10,
    [Parameter()] [int]    $Size = 512,
    [Parameter()] [string] $CaptureFilter = '',
    [Parameter()] [int]    $ParserId = 2,
    [Parameter()] [int]    $PullInterval = 1
)

function StopNmcap
{
    param(
        [Parameter()] [Object] $NmProcess
    )

    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class StartActivateProgramClass {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

    if ($NmProcess) 
    {
        $NmHandle = $NmProcess.Parent.MainWindowHandle
        [void] [StartActivateProgramClass]::SetForegroundWindow($NmHandle)
        
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [System.Windows.Forms.SendKeys]::SendWait('X')
    }
    if (!$NmProcess.HasExited)
    {
        Write-Host 'Automatic Stop Failed!' -ForegroundColor White -BackgroundColor DarkYellow
        Write-Host 'Switch to NMCap window and press X to stop the capture manually' -ForegroundColor White -BackgroundColor DarkYellow
    }
}

if (!(Test-Path "$env:ProgramFiles\Microsoft Network Monitor 3"))
{
    Write-Host "Microsoft Network Monitor 3 Not Installed!" -ForegroundColor Red
    Write-Host "Download and Install NetMon at http://go.microsoft.com/fwlink/?linkid=220643" -ForegroundColor Red
    Pause
    Exit
}
if (!(Get-NetAdapterBinding).ComponentID.Contains('ms_netmon'))
{
    Write-Host "Microsoft Network Monitor 3 Driver is Not Bound on Any Network Adapter!" -ForegroundColor Red
    Write-Host "Reinstall NetMon or Launch the Script as Administrator and Try Again" -ForegroundColor Red
    Pause
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
        Pause
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
Write-Host " > Parser Profile ID:       $ParserId"
Write-Host " > Pull Interval:           $PullInterval sec"
Write-Host "-------------------------------------------------"
Write-Host ""
Write-Host "Press Enter to Start Capture." -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "Press F12 to Stop Capture.   " -ForegroundColor White -BackgroundColor DarkGreen
Read-Host

$Argument = "/UseProfile $ParserId /Network * /Capture $CaptureFilter /file $OutPath\NetTraceNM.chn:" + $Size + "M /StopWhen /Frame IPv4.Address == 4.3.2.1 AND ICMP /TerminateWhen /KeyPress X"
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $Argument += ' /CaptureProcesses'
}
else
{
    Write-Host 'Not running as Administrator, Capture Process will not be enabled.' -ForegroundColor White -BackgroundColor Yellow
}
Write-Host "Calling NetMon" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "CommandLine: $env:ProgramFiles\Microsoft Network Monitor 3\nmcap.exe $Argument" -ForegroundColor White -BackgroundColor DarkGreen
$NmcapProcess = Start-Process -FilePath "$env:ProgramFiles\Microsoft Network Monitor 3\nmcap.exe" -ArgumentList $Argument -WindowStyle Minimized -PassThru

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
            $Prompt = "`nPurging File: " + $TraceFiles[0]
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
        Write-Host "This could caused by an unexpected ICMP packet to/from IP address 4.3.2.1 or not running NMCap as Administrator (No bound interface is found)" -ForegroundColor Red
        Pause
        Exit
    }
    Start-Sleep -Milliseconds 100 # Key Read Interval to Save CPU Usage.
}
ping.exe 4.3.2.1 -n 5 -w 100 | Out-Null
if (!$NmcapProcess.HasExited)
{
    $Warning = 
    "WARNING:                     
    NetMon has NOT exited yet!
    This could be caused by high volume of traffic pending process.
    If forcibly terminate NetMon, there will be data lost. 
    If wait for NetMon finish processing, more capture files will be saved and you need to purge old captures manually."
    Write-Host $Warning -ForegroundColor White -BackgroundColor DarkYellow
    while ($true)
    {
        $ForceExit = Read-Host -Prompt "Do you want to forcibly terminate NetMon? Yes/No (Default - No)"
        if (($ForceExit -eq 'yes') -or ($ForceExit -eq 'Yes'))
        {
            StopNmcap -NmProcess $NmcapProcess
            break
        }
        if (($ForceExit -eq 'no') -or ($ForceExit -eq 'No') -or ($ForceExit -eq ''))
        {
            Write-Host "Waiting for NetMon stopping. Keep pinging 4.3.2.1. Press F12 to stop immediately."
            Write-Host "WARNING: DO NOT forcibly stop this script at this stage, or you need to terminate the PING process and NMCap process manually!" -ForegroundColor White -BackgroundColor DarkYellow
            $PingProcess = Start-Process 'ping.exe' -ArgumentList '4.3.2.1 -t -w 100' -WindowStyle Hidden -PassThru
            while (!$NmcapProcess.HasExited)
            {
                if ([console]::KeyAvailable)
                {
                    if ([System.Console]::ReadKey().Key -eq 'F12')
                    {
                        Write-Host "`nF12 Pressed. Terminate NMCap Process."
                        StopNmcap -NmProcess $NmcapProcess
                    }
                }
                Write-Host '.' -NoNewline
                Start-Sleep -Milliseconds 1000
            }
            if (!$PingProcess.HasExited)
            {
                Stop-Process -Id $PingProcess.Id -Force
            }
            break
        }
    }
}
Start-Process $OutPath
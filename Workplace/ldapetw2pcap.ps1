# Converts data in LDAP client trace to Wireshark ready HEX dump
# Update #1: It appears since WS22, the LDAP client trace will be converted into JSON format with a non-standard timestamp format (yyyy/MM/dd-HH:mm:ss.fffffffff)
# Update #2: Support calling netsh trace convert and text2pcap, so that we don't need manual operations
# Update #3: Split large frames so that Wireshark can handle them

[CmdletBinding()]
param (
    [Parameter()] [string] $LdapEtw,
    [switch] $DecryptedOnly,
    [switch] $CallText2Pcap,
    [switch] $PreserveHexDump,
    [Parameter()] [int] $PseudoMSS = 8960,
    [Parameter()] [string] $Text2PcapPath = "C:\Program Files\Wireshark\text2pcap.exe",
    [Parameter()] [string] $SrcAddress = "10.1.1.1",
    [Parameter()] [string] $DstAddress = "10.1.1.2",
    [Parameter()] [string] $SrcPort = "12345",
    [Parameter()] [string] $DstPort = "389"
)

try
{
    $LdapEtwObj = Get-Item $LdapEtw -ErrorAction Stop
}
catch 
{
    $_
    exit
}
Push-Location $LdapEtwObj.Directory

if ($LdapEtwObj.Extension -eq '.etl')
{
    netsh trace convert "$($LdapEtwObj.FullName)" overwrite=yes
    $LdapEtw = $LdapEtwObj.BaseName + '.txt'
}

$EtwLineRegex = '\[\d+\][\dA-F]{4}\.[\dA-F]{4}::(?<Time>\u200e?\d{4}\u200e?\W\u200e?\d{2}\u200e?\W\u200e?\d{2}\W\d{2}:\d{2}:\d{2}\.\d+) \[Microsoft-Windows-LDAP-Client\](?<Message>.*)'
$HexDumpRegex = '(?<HEX>[\da-f]{2} )+ (?<ASCII>.+)'

$BeginDataSectionMark = 'Data (sent|received) on connection'
$EndDataSectionMark = 'End of (send|receive) buffer.'
$BeginDecryptedSectionMark = 'Unencrypted dump of Data (sent|received) on connection'
$EndDecryptedSectionMark = 'End of Unencrypted dump of (send|receive) buffer.'

$FrameCount = 0
$FramePart = 0
$LineCount = 0
$LdapEtwContent = Get-Content $LdapEtw
$Output = $LdapEtwObj.BaseName + '.hex'
$Index = 0
$IsInHexSection = $false
$CurrentTime = ''
$CurrentDirection = ''

Set-Content -Value ([string]::Empty) -LiteralPath $Output -NoNewline
foreach ($line in $LdapEtwContent)
{
    $LineCount++
    Write-Progress -PercentComplete ($LineCount / $LdapEtwContent.Count * 100) -Status "Line $LineCount/$($LdapEtwContent.Count)" -Activity 'Processing file'
    $RegMatch = [Regex]::Matches($line, $EtwLineRegex)
    if ($null -ne $RegMatch.Groups)
    {
        $Message = ($RegMatch.Groups | Where-Object { $_.Name -eq 'Message' }).Value
        $IsNewLogFormat = $Message[0] -eq '{'
        if ($IsNewLogFormat)
        {
            $Message = (ConvertFrom-Json $Message).Message
        }
        if ($IsInHexSection)
        {
            if ($Message -match $EndDecryptedSectionMark -or (!$DecryptedOnly -and ($Message -match $EndDataSectionMark)) )
            {
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject ([string]::Empty)
                $IsInHexSection = $false
                continue
            }
            $HexMatch = [Regex]::Matches($Message, $HexDumpRegex)
            if ($null -ne $HexMatch.Groups)
            {
                $HexCaptures = ($HexMatch.Groups | Where-Object { $_.Name -eq 'HEX' }).Captures
                $OutLine = $Index.ToString('X8') + '  ' + (-join $HexCaptures) + [System.Environment]::NewLine
                $OutLine | Out-File -Append -Encoding ascii -LiteralPath $Output -NoNewline
                $Index += $HexCaptures.Count
            }

            # Split the frame when the frame size is too large, by default using TCP jumbo MSS (8960 bytes)
            if ($Index -ge $PseudoMSS)
            {
                $FramePart++
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject "# Frame $FrameCount part $FramePart @ Line $LineCount"
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject "$CurrentDirection $CurrentTime"
                $Index = 0
            }
        }
        else
        {
            if ($Message -match $BeginDecryptedSectionMark -or (!$DecryptedOnly -and ($Message -match $BeginDataSectionMark)) )
            {
                $FrameCount++
                $FramePart = 0
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject "# Frame $FrameCount part 0 @ Line $LineCount"
                if ($IsNewLogFormat)
                {
                    $CurrentTime = ($RegMatch.Groups | Where-Object { $_.Name -eq 'Time' }).Value.Replace('-', ' ').Replace('/', '-')
                }
                else
                {
                    $CurrentTime = ($RegMatch.Groups | Where-Object { $_.Name -eq 'Time' }).Value -replace '\u200e'
                }
                if ($Message.Contains('sent')) { $CurrentDirection = 'O' }
                else { $CurrentDirection = 'I' }
                $IsInHexSection = $true
                $Index = 0
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject "$CurrentDirection $CurrentTime"
                continue
            }
        }
    }
}

if ($CallText2Pcap)
{
    $PcapOutput = $LdapEtwObj.BaseName + '.pcapng'
    
    $Text2PcapParams = '-i 6', "-T $DstPort,$SrcPort", "-4 $DstAddress,$SrcAddress", '-t "%Y-%m-%d %H:%M:%S.%f"', "-D ""$Output"" ""$PcapOutput""" -join ' '
    if (!(Test-Path($Text2PcapPath)))
    {
        Write-Error "text2pcap not found at $Text2PcapPath"
        Pop-Location
        exit
    }
    $Text2PcapProcInfo = New-Object System.Diagnostics.ProcessStartInfo
    $Text2PcapProcInfo.FileName = $Text2PcapPath
    $Text2PcapProcInfo.Arguments = $Text2PcapParams
    $Text2PcapProcInfo.RedirectStandardOutput = $true
    $Text2PcapProcInfo.RedirectStandardError = $true
    $Text2PcapProcInfo.UseShellExecute = $false
    $Text2PcapProcInfo.CreateNoWindow = $true
    $Text2PcapProcInfo.WorkingDirectory = $PWD.Path

    $Text2PcapProc = [System.Diagnostics.Process]::Start($Text2PcapProcInfo)
    $Text2PcapProc.WaitForExit()
    $Text2PcapProc.StandardOutput.ReadToEnd()
    $Text2PcapProc.StandardError.ReadToEnd()

    if (!$PreserveHexDump)
    {
        Remove-Item $Output
    }
}
Pop-Location
# Converts data in LDAP client trace to Wireshark ready HEX dump
# Update: It appears since WS22, the LDAP client trace will be converted into JSON format with a non-standard timestamp format (yyyy/MM/dd-HH:mm:ss.fffffffff)
# Update#2: Support calling netsh trace convert and text2pcap, so that we don't need manual operations

[CmdletBinding()]
param (
    [Parameter()]    [string] $LdapEtw,
    [switch] $DecryptedOnly,
    [switch] $CallText2Pcap,
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
$LineCount = 0
$LdapEtwContent = Get-Content $LdapEtw
$Output = $LdapEtwObj.BaseName + '.hex'
$Index = 0
$IsInHexSection = $false
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
        }
        else
        {
            if ($Message -match $BeginDecryptedSectionMark -or (!$DecryptedOnly -and ($Message -match $BeginDataSectionMark)) )
            {
                $FrameCount++
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject "# Frame $FrameCount @ Line $LineCount"
                if ($IsNewLogFormat)
                {
                    $Time = ($RegMatch.Groups | Where-Object { $_.Name -eq 'Time' }).Value.Replace('-', ' ').Replace('/', '-')
                }
                else
                {
                    $Time = ($RegMatch.Groups | Where-Object { $_.Name -eq 'Time' }).Value -replace '\u200e'
                }
                if ($Message.Contains('sent')) { $CurrentDirection = 'O' }
                else { $CurrentDirection = 'I' }
                $IsInHexSection = $true
                $Index = 0
                Out-File -Append -Encoding ascii -LiteralPath $Output -InputObject "$CurrentDirection $Time"
                continue
            }
        }
    }
}

if ($CallText2Pcap)
{
    $PcapOutput = $LdapEtwObj.BaseName + '.pcapng'
    $Text2PcapParams = "-i 6", "-T $SrcPort,$DstPort", "-t %Y-%m-%d %H:%M:%S.%f", "-D", "$Output", "$PcapOutput"
    & $Text2PcapPath $Text2PcapParams
    Remove-Item $Output
}
Pop-Location
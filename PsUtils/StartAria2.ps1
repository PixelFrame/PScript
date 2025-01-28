#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Token,

    [Parameter()]
    [string]
    $DownloadPath = "$USERPROFILE\Downloads"
)

try
{ 
    if (![System.Diagnostics.EventLog]::SourceExists('StartAria2')) 
    { [System.Diagnostics.EventLog]::CreateEventSource('StartAria2', 'Application') }
}
catch { $_ > $PSScriptRoot\EventLogFailed.txt; Exit -1 }
try { Get-Command aria2c.exe -ErrorAction Stop | Out-Null }
catch 
{ 
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Aria2c executable not found!", [System.Diagnostics.EventLogEntryType]::Error, 200)
    Exit 200
}
$IsInstanceRunning = Get-Process -Name aria2c -ErrorAction SilentlyContinue
if (($null -ne $IsInstanceRunning) -and ($IsInstanceRunning.CommandLine -like '*enable-rpc*'))
{
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Another aria2c instance detected!", [System.Diagnostics.EventLogEntryType]::Error, 201)
    Exit 201
}
$IsLocalPortUsed = Get-NetTCPConnection -LocalPort 6800 -LocalAddress 127.0.0.1 -ErrorAction SilentlyContinue
if ($null -ne $IsLocalPortUsed) 
{
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Local port 6800 has been used by another program. Unable to start aria2 instance!", [System.Diagnostics.EventLogEntryType]::Error, 202)
    Exit 202
}

try
{
    $TrackerUrl = 'https://cf.trackerslist.com/all_aria2.txt'
    $TrackerResp = Invoke-WebRequest -Uri $TrackerUrl -UseBasicParsing -ErrorAction Stop
    $TrackerList = $TrackerResp.Content
}
catch
{
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Unable to download BitTorrent tracker list. Tracker list has been set to default.", [System.Diagnostics.EventLogEntryType]::Warning, 210)
    $TrackerList = 'http://1337.abcvg.info:80/announce,http://ipv4.rer.lol:2710/announce,http://nyaa.tracker.wf:7777/announce,http://t.nyaatracker.com:80/announce,http://tk.greedland.net:80/announce,http://torrentsmd.com:8080/announce,http://tracker-zhuqiy.dgj055.icu:80/announce,http://tracker.beeimg.com:6969/announce,http://tracker.bt-hash.com:80/announce,http://tracker.bt4g.com:2095/announce,http://tracker.corpscorp.online:80/announce,http://tracker.lintk.me:2710/announce,http://tracker.moxing.party:6969/announce,http://tracker.renfei.net:8080/announce,http://tracker.tfile.co:80/announce,http://tracker.vraphim.com:6969/announce,http://tracker2.itzmx.com:6961/announce,http://tracker3.itzmx.com:6961/announce,http://tracker4.itzmx.com:2710/announce,http://www.all4nothin.net:80/announce.php,http://www.genesis-sp.org:2710/announce,http://www.torrentsnipe.info:2701/announce,http://www.wareztorrent.com:80/announce,https://1337.abcvg.info:443/announce,https://pybittrack.retiolus.net:443/announce,https://t.213891.xyz:443/announce,https://tr.burnabyhighstar.com:443/announce,https://tr.zukizuki.org:443/announce,https://tracker.gcrenwp.top:443/announce,https://tracker.ipfsscan.io:443/announce,https://tracker.itscraftsoftware.my.id:443/announce,https://tracker.kuroy.me:443/announce,https://tracker.leechshield.link:443/announce,https://tracker.lilithraws.org:443/announce,https://tracker.moeking.me:443/announce,https://tracker.tamersunion.org:443/announce,https://tracker.yemekyedim.com:443/announce,https://tracker1.520.jp:443/announce,https://trackers.mlsub.net:443/announce,udp://amigacity.xyz:6969/announce,udp://bandito.byterunner.io:6969/announce,udp://ec2-18-191-163-220.us-east-2.compute.amazonaws.com:6969/announce,udp://exodus.desync.com:6969/announce,udp://isk.richardsw.club:6969/announce,udp://ismaarino.com:1234/announce,udp://martin-gebhardt.eu:25/announce,udp://ns1.monolithindustries.com:6969/announce,udp://odd-hd.fr:6969/announce,udp://open.demonii.com:1337/announce,udp://open.stealth.si:80/announce,udp://open.tracker.ink:6969/announce,udp://opentor.org:2710/announce,udp://p4p.arenabg.com:1337/announce,udp://seedpeer.net:6969/announce,udp://serpb.vpsburti.com:6969/announce,udp://t.overflow.biz:6969/announce,udp://thetracker.org:80/announce,udp://tr4ck3r.duckdns.org:6969/announce,udp://trackarr.org:6969/announce,udp://tracker-udp.gbitt.info:80/announce,udp://tracker.0x7c0.com:6969/announce,udp://tracker.breizh.pm:6969/announce,udp://tracker.dler.com:6969/announce,udp://tracker.doko.moe:6969/announce,udp://tracker.fnix.net:6969/announce,udp://tracker.gigantino.net:6969/announce,udp://tracker.gmi.gd:6969/announce,udp://tracker.opentrackr.org:1337/announce,udp://tracker.qu.ax:6969/announce,udp://tracker.skyts.net:6969/announce,udp://tracker.srv00.com:6969/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker.tryhackx.org:6969/announce,udp://ttk2.nbaonlineservice.com:6969/announce,udp://u4.trakx.crim.ist:1337/announce,udp://u6.trakx.crim.ist:1337/announce,udp://z.mercax.com:53/announce,wss://tracker.openwebtorrent.com:443/announce'
}
$SeedRatio = '16.0'
$SeedTime = 1440 * 7 * 4

$Params = @()
$Params += "--dir=$DownloadPath"
$Params += "--log=$($env:USERPROFILE)\AppData\Local\aria2.log"
$Params += "--max-concurrent-downloads=10"
$Params += "--check-integrity"
$Params += "--continue"
$Params += "--bt-save-metadata"
$Params += "--seed-ratio=$SeedRatio"
$Params += "--seed-time=$SeedTime"
$Params += "--enable-rpc"
$Params += "--bt-tracker=$TrackerList"
$Params += "--rpc-secret=$Token"
$Params += "--rpc-listen-all=true"
$Params += "--rpc-allow-origin-all"
$Params += "--always-resume"

[System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Staring aria2c process using param:`r`n$Params", [System.Diagnostics.EventLogEntryType]::Information, 100)
$Aria2Proc = Start-Process -FilePath aria2c.exe -ArgumentList $Params -WindowStyle Hidden -PassThru
Start-Sleep 5
if ($Aria2Proc.HasExited) 
{
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Aria2c process failed to start!", [System.Diagnostics.EventLogEntryType]::Error, 203)
    Exit 203
}
else 
{
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Aria2c process started successfully!", [System.Diagnostics.EventLogEntryType]::Information, 101)
    $Aria2Proc | Format-List * | Out-File $env:USERPROFILE\AppData\Local\aria2.proc
}
#Requires -RunAsAdministrator

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
    $TrackerUrl = 'https://cdn.staticaly.com/gh/XIU2/TrackersListCollection/master/best_aria2.txt'
    $TrackerResp = Invoke-WebRequest -Uri $TrackerUrl -UseBasicParsing -ErrorAction Stop
    $TrackerList = $TrackerResp.Content
}
catch
{
    [System.Diagnostics.EventLog]::WriteEntry('StartAria2', "Unable to download BitTorrent tracker list. Tracker list has been set to default.", [System.Diagnostics.EventLogEntryType]::Warning, 210)
    $TrackerList = 'http://1337.abcvg.info:80/announce,http://fxtt.ru:80/announce,http://i-p-v-6.tk:6969/announce,http://incine.ru:6969/announce,http://ipv6.1337.cx:6969/announce,http://ipv6.govt.hu:6969/announce,http://nyaa.tracker.wf:7777/announce,http://open-v6.demonoid.ch:6969/announce,http://open.nyap2p.com:8080/announce,http://open.tracker.ink:6969/announce,http://opentracker.xyz:80/announce,http://share.camoe.cn:8080/announce,http://t.acg.rip:6699/announce,http://t.nyaatracker.com:80/announce,http://t.overflow.biz:6969/announce,http://t.publictracker.xyz:6969/announce,http://tracker.aeerso.space:6969/announce,http://tracker.files.fm:6969/announce,http://tracker.gbitt.info:80/announce,http://tracker.ipv6tracker.ru:80/announce,http://tracker.k.vu:6969/announce,http://vps02.net.orel.ru:80/announce,https://carbon-bonsai-621.appspot.com:443/announce,https://opentracker.i2p.rocks:443/announce,https://tr.abiir.top:443/announce,https://tr.burnabyhighstar.com:443/announce,https://tr.ready4.icu:443/announce,https://tracker.dmhy.pw:443/announce,https://tracker.imgoingto.icu:443/announce,https://tracker.lilithraws.cf:443/announce,https://tracker.lilithraws.org:443/announce,https://tracker.nanoha.org:443/announce,https://tracker.tamersunion.org:443/announce,https://tracker1.loli.co.nz:443/announce,https://trackme.theom.nz:443/announce,udp://6ahddutb1ucc3cp.ru:6969/announce,udp://9.rarbg.com:2810/announce,udp://aarsen.me:6969/announce,udp://astrr.ru:6969/announce,udp://ben.kerbertools.xyz:6969/announce,udp://betasoftsp.com.br:6969/announce,udp://black-bird.ynh.fr:6969/announce,udp://bubu.mapfactor.com:6969/announce,udp://cutscloud.duckdns.org:6969/announce,udp://davidkirkevans.com:6969/announce,udp://epider.me:6969/announce,udp://exodus.desync.com:6969/announce,udp://fe.dealclub.de:6969/announce,udp://fh2.cmp-gaming.com:6969/announce,udp://free.open.tracker.4.starka.st:15480/announce,udp://h3o2.me:1337/announce,udp://htz3.noho.st:6969/announce,udp://ipv4.tracker.harry.lu:80/announce,udp://ipv6.69.mu:6969/announce,udp://ipv6.tracker.monitorit4.me:6969/announce,udp://isk.richardsw.club:6969/announce,udp://itera.bz:6969/announce,udp://keke.re:6969/announce,udp://laze.cc:6969/announce,udp://letsdecentralize.org:6969/announce,udp://lloria.fr:6969/announce,udp://mail.artixlinux.org:6969/announce,udp://mail.zasaonsk.ga:6969/announce,udp://moonburrow.club:6969/announce,udp://movies.zsw.ca:6969/announce,udp://mserver.link:6969/announce,udp://new-line.net:6969/announce,udp://open.demonii.com:1337/announce,udp://open.free-tracker.ga:6969/announce,udp://open.publictracker.xyz:6969/announce,udp://open.stealth.si:80/announce,udp://open.tracker.cl:1337/announce,udp://open.tracker.ink:6969/announce,udp://open.xxtor.com:3074/announce,udp://open6.demonii.com:1337/announce,udp://opentor.org:2710/announce,udp://opentracker.i2p.rocks:6969/announce,udp://p4p.arenabg.com:1337/announce,udp://psyco.fr:6969/announce,udp://qtstm32fan.ru:6969/announce,udp://rep-art.ynh.fr:6969/announce,udp://retracker.hotplug.ru:2710/announce,udp://run.publictracker.xyz:6969/announce,udp://sanincode.com:6969/announce,udp://smtp-relay.odysseylabel.com.au:6969/announce,udp://smtp.flawcra.cc:6969/announce,udp://srv5.digiboy.ir:6969/announce,udp://tamas3.ynh.fr:6969/announce,udp://themaninashed.com:6969/announce,udp://thetracker.org:80/announce,udp://thouvenin.cloud:6969/announce,udp://torrentclub.space:6969/announce,udp://torrents.artixlinux.org:6969/announce,udp://tr.cili001.com:8070/announce,udp://tracker.0x.tf:6969/announce,udp://tracker.4.babico.name.tr:3131/announce,udp://tracker.6.babico.name.tr:6969/announce,udp://tracker.altrosky.nl:6969/announce,udp://tracker.artixlinux.org:6969/announce,udp://tracker.auctor.tv:6969/announce,udp://tracker.beeimg.com:6969/announce,udp://tracker.birkenwald.de:6969/announce,udp://tracker.bitsearch.to:1337/announce,udp://tracker.cyberia.is:6969/announce,udp://tracker.dler.com:6969/announce,udp://tracker.dler.org:6969/announce,udp://tracker.encrypted-data.xyz:1337/announce,udp://tracker.jordan.im:6969/announce,udp://tracker.leech.ie:1337/announce,udp://tracker.lelux.fi:6969/announce,udp://tracker.moeking.me:6969/announce,udp://tracker.monitorit4.me:6969/announce,udp://tracker.openbittorrent.com:6969/announce,udp://tracker.opentrackr.org:1337/announce,udp://tracker.pomf.se:80/announce,udp://tracker.publictracker.xyz:6969/announce,udp://tracker.tiny-vps.com:6969/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker1.bt.moack.co.kr:80/announce,udp://tracker2.dler.com:80/announce,udp://tracker6.lelux.fi:6969/announce,udp://transkaroo.joustasie.net:6969/announce,udp://uploads.gamecoast.net:6969/announce,udp://v2.iperson.xyz:6969/announce,udp://vibe.sleepyinternetfun.xyz:1738/announce,udp://www.torrent.eu.org:451/announce,udp://yahor.ftp.sh:6969/announce,udp://zecircle.xyz:6969/announce,ws://hub.bugout.link:80/announce,wss://tracker.openwebtorrent.com:443/announce'
}
$Token = 'N0Tlm37oL0vE'
$SeedRatio = '16.0'
$SeedTime = 1440 * 7 * 4

$Params = @()
$Params += "--dir=$env:USERPROFILE\Downloads"
$Params += "--log=$env:USERPROFILE\AppData\Local\aria2.log"
$Params += "--max-concurrent-downloads=10"
$Params += "--check-integrity"
$Params += "--continue"
$Params += "--bt-save-metadata"
$Params += "--seed-ratio=$SeedRatio"
$Params += "--seed-time=$SeedTime"
$Params += "--enable-rpc"
$Params += "--bt-tracker=$TrackerList"
$Params += "--rpc-secret=$Token"
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
    $PSStyle.OutputRendering = 'PlainText'
    $Aria2Proc | Format-List * | Out-File $PSScriptRoot\aria2.proc
}
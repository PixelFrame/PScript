#Requires -Module Selenium

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ItemId = '100007835051',
    
    [Parameter()]
    [string]
    $LogPath = ".\JdPriceTrack_$ItemId.csv"
)

$Uri = "https://item.jd.com/$ItemId.html"
$Price = 'N/A'

$SeDriver = Start-SeEdge
Enter-SeUrl $Uri -Driver $SeDriver
$Price = (Get-SeElement -By CssSelector "span[class = 'price J-p-$ItemId']").Text
$Time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Stop-SeDriver $SeDriver

if (Test-Path($LogPath))
{
    '{0}, ￥{1}' -f $Time, $Price | Out-File $LogPath -Append -Encoding utf8NoBOM
}
else
{
    'Time, Price' | Out-File $LogPath -Encoding utf8NoBOM
    '{0}, ￥{1}' -f $Time, $Price | Out-File $LogPath -Append -Encoding utf8NoBOM
}
#Requires -Module Selenium

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ItemId = '595234022443',

    [Parameter()]
    [string]
    $SkuId = '4621088914922',
    
    [Parameter()]
    [string]
    $LogPath = ".\TmallPriceTrack_$ItemId-$SkuId.csv"
)

$Uri = "https://detail.tmall.com/item.htm?id=$ItemId&skuId=$SkuId"
$Price = ''

$SeDriver = Start-SeEdge
Enter-SeUrl $Uri -Driver $SeDriver

$CloseLogin = Get-SeElement -By CssSelector "div#sufei-dialog-close[class = 'sufei-dialog-close']"
Invoke-SeClick -Element $CloseLogin

$CNT = 0
while ($Price -eq '' -and $CNT++ -lt 3)
{
    $Price = (Get-SeElement -By XPath '//*[@id="J_StrPriceModBox"]/dd/span').Text
    $Time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Start-Sleep -Milliseconds 500
}

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
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path = 'C:\DhcpClassAndOption'
)

if (!(Test-Path $Path))
{
    mkdir $Path | Out-Null
}

$VendorClasses = Get-DhcpServerv4Class -Type Vendor
$VendorClasses | ConvertTo-Json | Out-File $Path\VendorClasses.json
$UserClasses = Get-DhcpServerv4Class -Type User
$UserClasses | ConvertTo-Json | Out-File $Path\UserClasses.json

Get-DhcpServerv4OptionDefinition | ConvertTo-Json | Out-File $Path\Options.json
foreach ($VendorClass in $VendorClasses)
{
    $AsciiName = $VendorClass.AsciiData
    $VendorClass | Get-DhcpServerv4OptionDefinition | ConvertTo-Json | Out-File "$Path\Options-$AsciiName.json"
}
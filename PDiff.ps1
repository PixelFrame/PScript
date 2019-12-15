$PathSrc
$PathDest
$ItemsSrc = Get-ChildItem -Path $PathSrc
$ItemsDest = Get-ChildItem -Path $PathDest
$strItemsSrc = @()
$strItemsDest = @()
$diff = @()

foreach ($item in $ItemsSrc)
{
    $strItemsSrc += $item.Name
}

foreach ($item in $ItemsDest)
{
    $strItemsDest += $item.Name
}

foreach ($strItem in $strItemsSrc)
{
    if (!$strItemsDest.Contains($strItem))
    {
        $diff += $strItem
    }
}

$diff
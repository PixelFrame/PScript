# Using WMI

$ProfileName = '*'
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

$HKEY_LOCAL_MACHINE = 2147483650
$KeyPath = 'SOFTWARE\Microsoft\EnterpriseResourceManager\Tracked'
$SearchPattern = '*/Vendor/MSFT/VPNv2/' + $ProfileNameEscaped

$WmiReg = [WMIClass]'root\default:StdRegProv'

$SearchResult = @()
$TrackedSubKeys = $WmiReg.EnumKey($HKEY_LOCAL_MACHINE, $KeyPath)
foreach ($TrackedSubKey in $TrackedSubKeys.sNames)
{
    $TrackedKeyPath = $KeyPath + '\' + $TrackedSubKey
    $GuidSubKeys = $WmiReg.EnumKey($HKEY_LOCAL_MACHINE, $TrackedKeyPath)
    foreach ($GuidSubKey in $GuidSubKeys.sNames)
    {
        $GuidKeyPath = $TrackedKeyPath + '\' + $GuidSubKey
        $SidSubKeys = $WmiReg.EnumKey($HKEY_LOCAL_MACHINE, $GuidKeyPath)
        foreach ($SidSubKey in $SidSubKeys.sNames)
        {
            $SidKeyPath = $GuidKeyPath + '\' + $SidSubKey
            $Entries = $WmiReg.EnumValues($HKEY_LOCAL_MACHINE, $SidKeyPath)
            foreach ($Entry in $Entries.sNames)
            {
                $strValue = $WmiReg.GetStringValue($HKEY_LOCAL_MACHINE, $SidKeyPath, $Entry)
                if (($strValue.ReturnValue -eq 0) -and ($strValue.sValue -like $SearchPattern))
                {
                    $SearchResult += [PSCustomObject]@{
                        Path  = $SidKeyPath;
                        Entry = $Entry;
                        Value = $strValue.sValue
                    }
                    
                    # 'Found Match: ' + $SidSubKey + '\' + $Entry
                    # $WmiReg.DeleteValue($HKEY_LOCAL_MACHINE, $SidKeyPath, $Entry)
                }
            }
        }
    }
}

$SearchResult
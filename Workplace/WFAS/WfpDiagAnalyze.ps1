[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]
    $WfpDiagXmlPath
)

#region Helper Functions
function ReadUnicodeHexString
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $HexString
    )
    if ([string]::IsNullOrEmpty($HexString)) { return $null; }
    $arr = [byte[]] -split ($HexString -replace '..', '0x$& ')
    $str = [System.Text.Encoding]::Unicode.GetString($arr);
    return $str;
}

function TranslateConditionValue
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [object]
        $conditionValue
    )

    switch ($conditionValue.type)
    {
        'FWP_UINT8' { return $conditionValue.uint8 }
        'FWP_UINT16' { return $conditionValue.uint16 }
        'FWP_UINT32' { return $conditionValue.uint32 }
        'FWP_UINT64' { return $conditionValue.uint64 }
        'FWP_INT8' { return $conditionValue.int8 }
        'FWP_INT16' { return $conditionValue.int16 }
        'FWP_INT32' { return $conditionValue.int32 }
        'FWP_INT64' { return $conditionValue.int64 }
        'FWP_FLOAT' { return $conditionValue.float32 }
        'FWP_DOUBLE' { return $conditionValue.double64 }
        'FWP_BYTE_ARRAY16_TYPE' { return $conditionValue.byteArray16 }
        'FWP_BYTE_BLOB_TYPE' { return (ReadUnicodeHexString $conditionValue.byteBlob.data) + ' (' + $conditionValue.byteBlob.data + ')' }
        'FWP_SID' { return $conditionValue.sid }
        'FWP_SECURITY_DESCRIPTOR_TYPE' { return $conditionValue.sd }
        'FWP_TOKEN_INFORMATION_TYPE' { return $conditionValue.tokenInformation }
        'FWP_TOKEN_ACCESS_INFORMATION_TYPE' { return $conditionValue.tokenAccessInformation }
        'FWP_UNICODE_STRING_TYPE' { return $conditionValue.unicodeString }
        'FWP_BYTE_ARRAY6_TYPE' { return $conditionValue.byteArray6 }
        'FWP_V4_ADDR_MASK' { return $conditionValue.v4AddrMask }
        'FWP_V6_ADDR_MASK' { return $conditionValue.v6AddrMask }
        'FWP_RANGE_TYPE' { return (TranslateConditionValue $conditionValue.rangeValue.valueLow) + ' - ' + (TranslateConditionValue $conditionValue.rangeValue.valueHigh) }
        Default { return $null }
    }
}

$NetProfileMapping = @{
    '0' = 'Public';
    '1' = 'Private';
    '2' = 'Domain';
}

$MatchTypeMapping = @{
    'FWP_MATCH_EQUAL' = '==';
    'FWP_MATCH_GREATER' = '>';
    'FWP_MATCH_LESS' = '<';
    'FWP_MATCH_GREATER_OR_EQUAL' = '>=';
    'FWP_MATCH_LESS_OR_EQUAL' = '<='; 
    'FWP_MATCH_RANGE' = 'In Range';
    'FWP_MATCH_FLAGS_ALL_SET' = 'All Flags Set'; 
    'FWP_MATCH_FLAGS_ANY_SET' = 'Any Flag Set';
    'FWP_MATCH_FLAGS_NONE_SET' = 'No Flag Set';
    'FWP_MATCH_EQUAL_CASE_INSENSITIVE' = '== (Case Insensitive)';
    'FWP_MATCH_NOT_EQUAL' = '!=';
    'FWP_MATCH_PREFIX' = 'Prefix';
    'FWP_MATCH_NOT_PREFIX' = 'Not Prefix';
}

#endregion Helper Functions

# Load XML
$xmlobj = [XML] (Get-Content -LiteralPath $WfpDiagXmlPath -Raw)

# Drop Events
$cnt = 0
$dropObj = @()
$drop = $xmlobj.wfpdiag.events.netEvent | Where-Object { $_.type -like '*CLASSIFY_DROP' }  # It appears new OS version uses 'FWPM_NET_EVENT_TYPE_PUBLIC_CLASSIFY_DROP' instead of 'FWPM_NET_EVENT_TYPE_CLASSIFY_DROP' now
foreach ($d in $drop)
{
    $cnt++
    Write-Progress -Activity 'Parsing Drop Events' -Status "$cnt/$($drop.Count)" -PercentComplete ($cnt / $drop.Count * 100)
    $dropObj += [PSCustomObject]@{
        TimeStamp       = [DateTime]::Parse($d.header.timeStamp);
        Flags           = $d.header.flags.item -join [Environment]::NewLine;
        IPVersion       = $d.header.ipVersion;
        IPProtocol      = $d.header.ipProtocol;
        LocalAddress    = $d.header.localAddrV4 + $d.header.localAddrV6;
        RemoteAddress   = $d.header.remoteAddrV4 + $d.header.remoteAddrV6;
        LocalPort       = $d.header.localPort;
        RemotePort      = $d.header.remotePort;
        AppId           = ReadUnicodeHexString $d.header.appId.data;
        UserId          = $d.header.userId;
        PackageSid      = $d.header.packageSid;
        FilterId        = $d.classifyDrop.filterId;
        Direction       = $d.classifyDrop.msFwpDirection;
        OriginalProfile = $NetProfileMapping[$d.classifyDrop.originalProfile];
        CurrentProfile  = $NetProfileMapping[$d.classifyDrop.currentProfile];
    }
}

# Filters
$cnt = 0
$fltObj = @()
$initFilters = $xmlobj.wfpdiag.initialState.SelectNodes('//filters/item')
foreach ($f in $initFilters)
{
    $cnt++
    Write-Progress -Activity 'Parsing Initial Filters' -Status "$cnt/$($initFilters.Count)" -PercentComplete ($cnt / $initFilters.Count * 100)
    $fltObj += [PSCustomObject]@{
        Id          = $f.filterId;
        Name        = $f.displayData.name;
        Description = $f.displayData.description;
        Flags       = $f.flags.item -join [Environment]::NewLine;
        ProviderKey = $f.providerKey;
        Condition   = ($f.filterCondition.item | 
            ForEach-Object { 
                if($null -ne $_)
                { $_.fieldKey.SubString(15) + ' ' + $MatchTypeMapping[$_.matchType] + ' ' + (TranslateConditionValue $_.conditionValue) }
            }) -join [Environment]::NewLine;
    }
}


$cnt = 0
$addedFilters = $xmlobj.wfpdiag.events.filterChange.filter
foreach ($f in $addedFilters)
{
    $cnt++
    Write-Progress -Activity 'Parsing Added Filters' -Status "$cnt/$($addedFilters.Count)" -PercentComplete ($cnt / $addedFilters.Count * 100)
    $fltObj += [PSCustomObject]@{
        Id          = $f.filterId;
        Name        = $f.displayData.name;
        Description = $f.displayData.description;
        Flags       = $f.flags.item -join [Environment]::NewLine;
        ProviderKey = $f.providerKey;
        Condition   = ($f.filterCondition.item | 
            ForEach-Object { 
                if($null -ne $_)
                { $_.fieldKey.SubString(15) + ' ' + $MatchTypeMapping[$_.matchType] + ' ' + (TranslateConditionValue $_.conditionValue) }
            }) -join [Environment]::NewLine;
    }
}

# Providers
$cnt = 0
$provObj = @()
$providers = $xmlobj.wfpdiag.initialState.providers.item
foreach ($p in $providers)
{
    $cnt++
    Write-Progress -Activity 'Parsing Providers'  -Status "$cnt/$($providers.Count)" -PercentComplete ($cnt / $providers.Count * 100)
    $provObj += [PSCustomObject]@{
        Key         = $p.providerKey;
        Name        = $p.displayData.name;
        Description = $p.displayData.description;
        Flags       = $p.flags.item -join [Environment]::NewLine;
        ServiceName = $p.serviceName;
    }
}


# Output

$dropObj | Out-GridView -Title 'Dropped Packets'
$fltObj | Out-GridView -Title 'Filters'
$provObj | Out-GridView -Title 'Providers'
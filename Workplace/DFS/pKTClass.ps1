# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsnm/54e3ec05-913f-4d6d-932b-095f457fd543
# PowerShell class for DFS namespacev1

function Get-SubArray
{
    param (
        [byte[]] $Source,
        [int] $StartIndex,
        [int] $Length
    )
    
    $Result = New-Object 'byte[]' -ArgumentList $Length
    [Array]::Copy($Source, $StartIndex, $Result, 0, $Length);
    return $Result
}

function Convert-LEBytesToUInt32
{
    param (
        [byte[]] $Bytes
    )
    if ($Bytes.Length -gt 4)
    {
        throw 'Byte array too long!'
    }
    if (![BitConverter]::IsLittleEndian)
    {
        [Array]::Reverse($Bytes); 
    }
    return [BitConverter]::ToUInt32($Bytes, 0);
}

function Convert-LEBytesToUInt16
{
    param (
        [byte[]] $Bytes
    )
    if ($Bytes.Length -gt 2)
    {
        throw 'Byte array too long!'
    }
    if (![BitConverter]::IsLittleEndian)
    {
        [Array]::Reverse($Bytes); 
    }
    return [BitConverter]::ToUInt16($Bytes, 0);
}

function Convert-LEBytesToString
{
    param (
        [byte[]] $Bytes
    )
    if ($null -eq $Bytes) { return '' }
    return [System.Text.Encoding]::Unicode.GetString($Bytes)
}

class pKT
{
    [uint32] $Version;
    [uint32] $ElementCount;
    [DFSNamespaceElement[]] $Elements;

    pKT([byte[]] $Data)
    {
        $BLOBVersion = Get-SubArray -Source $Data -StartIndex 0 -Length 4
        $BLOBElementCount = Get-SubArray -Source $Data -StartIndex 4 -Length 4

        $this.Version = Convert-LEBytesToUInt32 $BLOBVersion
        $this.ElementCount = Convert-LEBytesToUInt32 $BLOBElementCount

        $BLOBElements = Get-SubArray -Source $Data -StartIndex 8 -Length ($Data.Length - 8)
        $this.CreateElements($BLOBElements)
    }

    [void] CreateElements([byte[]] $BLOBElements)
    {
        $CreatedCount = 0
        $StartIndex = 0
        while ($CreatedCount++ -lt $this.ElementCount)
        {
            $Element = New-Object DFSNamespaceElement
            $BLOBNameSize = Get-SubArray -Source $BLOBElements -StartIndex $StartIndex -Length 2
            $StartIndex += 2
            $Element.NameSize = Convert-LEBytesToUInt16 -Bytes $BLOBNameSize
            $BLOBName = Get-SubArray -Source $BLOBElements -StartIndex $StartIndex -Length $Element.NameSize
            $StartIndex += $Element.NameSize
            $Element.Name = Convert-LEBytesToString -Bytes $BLOBName
            $BLOBDataSize = Get-SubArray -Source $BLOBElements -StartIndex $StartIndex -Length 4
            $StartIndex += 4
            $Element.DataSize = Convert-LEBytesToUInt32 -Bytes $BLOBDataSize
            $BLOBData = Get-SubArray -Source $BLOBElements -StartIndex $StartIndex -Length $Element.DataSize
            $Element.SetData($BLOBData)
            $StartIndex += $Element.DataSize
            $this.Elements += $Element
        }
    }

    [void] Print()
    {
        $this.Print('All')
    }
    [void] Print([string] $Type)
    {
        foreach ($Element in $this.Elements)
        {
            Write-Host $Element.Name -ForegroundColor DarkBlue -BackgroundColor White
            $Element.Print($Type)
        }
    }
}

class DFSNamespaceElement
{
    [uint16] $NameSize;
    [string] $Name;
    [uint32] $DataSize;
    [DFSNamespaceRootOrLink] $DataRootOrLink;
    [SiteInformation] $DataSite;

    [void] SetData([byte[]] $BLOBData)
    {
        switch ($this.Name)
        {
            '\domainroot' { $this.DataRootOrLink = [DFSNamespaceRootOrLink]::new($BLOBData) }
            '\siteroot' { $this.DataSite = [SiteInformation]::new($BLOBData) }
            Default { $this.DataRootOrLink = [DFSNamespaceRootOrLink]::new($BLOBData) }
        }
    }

    [void] Print([string] $Type)
    {
        if ($Type -eq 'Root' -and $this.Name -ne '\domainroot')
        {
            return
        }
        if ($Type -eq 'Site' -and $this.Name -ne '\siteroot')
        {
            return
        }
        if ($Type -eq 'Link' -and $this.Name -notmatch '\\domainroot\\')
        {
            return
        }
        switch ($this.Name)
        {
            '\domainroot' { $this.DataRootOrLink.Print() }
            '\siteroot' { $this.DataSite.Print() }
            Default { $this.DataRootOrLink.Print() }
        }
    }
}

class DFSNamespaceRootOrLink
{
    [guid] $RootOrLinkGuid;
    [uint16] $PrefixSize;
    [string] $Prefix;
    [uint16] $ShortPrefixSize;
    [string] $ShortPrefix;
    [uint32] $Type;
    [uint32] $State;
    [uint16] $CommentSize;
    [string] $Comment;
    [TimeStamp] $PrefixTimeStamp;
    [TimeStamp] $StateTimeStamp;
    [TimeStamp] $CommentTimeStamp;
    [uint32] $Version;
    [uint32] $TargetListSize;
    [TargetList] $TargetList;
    [uint32] $ReservedBlobSize;
    [uint32] $ReservedBlob;
    [uint32] $ReferralTTL;

    DFSNamespaceRootOrLink([byte[]] $BLOBData)
    {
        $StartIndex = 0

        $BLOBGuid = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 16
        $this.RootOrLinkGuid = [Guid][byte[]] $BLOBGuid
        $StartIndex += 16

        $BLOBPrefixSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 2
        $this.PrefixSize = Convert-LEBytesToUInt16 -Bytes $BLOBPrefixSize
        $StartIndex += 2

        $BLOBPrefix = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $this.PrefixSize
        $this.Prefix = Convert-LEBytesToString $BLOBPrefix
        $StartIndex += $this.PrefixSize

        $BLOBShortPrefixSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 2
        $this.ShortPrefixSize = Convert-LEBytesToUInt16 -Bytes $BLOBShortPrefixSize
        $StartIndex += 2

        $BLOBShortPrefix = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $this.ShortPrefixSize
        $this.ShortPrefix = Convert-LEBytesToString $BLOBShortPrefix
        $StartIndex += $this.ShortPrefixSize

        $BLOBType = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.Type = Convert-LEBytesToUInt32 $BLOBType
        $StartIndex += 4

        $BLOBState = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.State = Convert-LEBytesToUInt32 $BLOBState
        $StartIndex += 4

        $BLOBCommentSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 2
        $this.CommentSize = Convert-LEBytesToUInt16 -Bytes $BLOBCommentSize
        $StartIndex += 2

        $BLOBComment = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $this.CommentSize
        $this.Comment = Convert-LEBytesToString -Bytes $BLOBComment
        $StartIndex += $this.CommentSize

        $BLOBPrefixTimeStamp = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 8
        $this.PrefixTimeStamp = [TimeStamp][byte[]] $BLOBPrefixTimeStamp
        $StartIndex += 8

        $BLOBStateTimeStamp = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 8
        $this.StateTimeStamp = [TimeStamp][byte[]] $BLOBStateTimeStamp
        $StartIndex += 8

        $BLOBCommentTimeStamp = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 8
        $this.CommentTimeStamp = [TimeStamp][byte[]] $BLOBCommentTimeStamp
        $StartIndex += 8

        $BLOBVersion = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.Version = Convert-LEBytesToUInt32 $BLOBVersion
        $StartIndex += 4

        $BLOBTargetListSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.TargetListSize = Convert-LEBytesToUInt32 $BLOBTargetListSize
        $StartIndex += 4

        $BLOBTargetList = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $this.TargetListSize
        $this.TargetList = [TargetList][byte[]] $BLOBTargetList
        $StartIndex += $this.TargetListSize

        $BLOBReservedBlobSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.ReservedBlobSize = Convert-LEBytesToUInt32 $BLOBReservedBlobSize
        $StartIndex += 4

        $BLOBReservedBlob = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $this.ReservedBlobSize
        $this.ReservedBlob = Convert-LEBytesToUInt32 $BLOBReservedBlob
        $StartIndex += $this.ReservedBlobSize

        $BLOBReferralTTL = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.ReferralTTL = Convert-LEBytesToUInt32 $BLOBReferralTTL
        $StartIndex += 4

        if ($StartIndex -lt $BLOBData.Length)
        {
            Write-Host '[Warning] Inconsistent Data Length!' -ForegroundColor Yellow
        }
    }

    [void] Print()
    {
        $Padding = '    '
        Write-Host ($Padding + "Prefix     : " + $this.Prefix)
        Write-Host ($Padding + "Type       : " + $this.Type)
        Write-Host ($Padding + "State      : " + $this.State)
        Write-Host ($Padding + "Comment    : " + ($this.Comment))
        Write-Host ($Padding + "TTL        : " + $this.ReferralTTL)
        Write-Host ($Padding + "TargetList : ")
        $this.TargetList.Print()
    }
}

class SiteInformation
{
    [Guid] $SiteTableGuid;
    [uint32] $SiteEntryCount;
    [SiteEntry[]] $SiteEntries;

    SiteInformation([byte[]] $BLOBData)
    {
        $StartIndex = 0

        $BLOBGuid = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 16
        $this.SiteTableGuid = [Guid][byte[]] $BLOBGuid
        $StartIndex += 16

        $BLOBSiteEntryCount = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.SiteEntryCount = Convert-LEBytesToUInt32 $BLOBSiteEntryCount
        $StartIndex += 4

        $BLOBSiteEntries = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length ($BLOBData.Length - 20)
        $this.CreateEntries($BLOBSiteEntries)
    }

    [void] CreateEntries([byte[]] $BLOBSiteEntries)
    {
        $CreatedCount = 0
        $StartIndex = 0
        while ($CreatedCount++ -lt $this.SiteEntryCount)
        {
            $Entry = New-Object SiteEntry

            $BLOBServerNameSize = Get-SubArray -Source $BLOBSiteEntries -StartIndex $StartIndex -Length 2
            $Entry.ServerNameSize = Convert-LEBytesToUInt16 -Bytes $BLOBServerNameSize
            $StartIndex += 2

            $BLOBServerName = Get-SubArray -Source $BLOBSiteEntries -StartIndex $StartIndex -Length $Entry.ServerNameSize
            $Entry.ServerName = Convert-LEBytesToString -Bytes $BLOBServerName
            $StartIndex += $Entry.ServerNameSize

            $BLOBSiteNameInfoCount = Get-SubArray -Source $BLOBSiteEntries -StartIndex $StartIndex -Length 4
            $Entry.SiteNameInfoCount = Convert-LEBytesToUInt16 -Bytes $BLOBSiteNameInfoCount
            $StartIndex += 4

            $SiteNameInfoCreatedCount = 0
            while ($SiteNameInfoCreatedCount++ -lt $Entry.SiteNameInfoCount)
            {
                $Info = New-Object SiteNameInfo

                $BLOBFlags = Get-SubArray -Source $BLOBSiteEntries -StartIndex $StartIndex -Length 4
                $Info.Flags = Convert-LEBytesToUInt32 $BLOBFlags
                $StartIndex += 4

                $BLOBSiteNameSize = Get-SubArray -Source $BLOBSiteEntries -StartIndex $StartIndex -Length 2
                $Info.SiteNameSize = Convert-LEBytesToUInt16 $BLOBSiteNameSize
                $StartIndex += 2

                $BLOBSiteName = Get-SubArray -Source $BLOBSiteEntries -StartIndex $StartIndex -Length $Info.SiteNameSize
                $Info.SiteName = Convert-LEBytesToString $BLOBSiteName
                $StartIndex += $Info.SiteNameSize

                $Entry.SiteNameInfo += $Info
            }

            $this.SiteEntries += $Entry
        }
    }

    [void] Print()
    {
        foreach ($SiteEntry in $this.SiteEntries)
        {
            $SiteEntry.Print()
        }
    }
}

class TargetList
{
    [uint32] $TargetCount;
    [TargetEntry[]] $TargetEntries;

    TargetList([byte[]] $BLOBTargetList)
    {
        $BLOBTargetCount = Get-SubArray -Source $BLOBTargetList -StartIndex 0 -Length 4
        $this.TargetCount = Convert-LEBytesToUInt32 $BLOBTargetCount
        $BLOBTargetEntries = Get-SubArray -Source $BLOBTargetList -StartIndex 4 -Length ($BLOBTargetList.Length - 4)
        $this.CreateEntries($BLOBTargetEntries)
    }

    [void] CreateEntries([byte[]] $BLOBTargetEntries)
    {
        $CreatedCount = 0
        $StartIndex = 0
        while ($CreatedCount++ -lt $this.TargetCount)
        {
            $Entry = New-Object TargetEntry

            $BLOBTargetEntrySize = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 4
            $Entry.TargetEntrySize = Convert-LEBytesToUInt32 $BLOBTargetEntrySize
            $StartIndex += 4

            # TODO: Priority is not set here, only set TimeStamp
            $BLOBTargetTimeStamp = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 8
            $Entry.TargetTimeStamp = [TimeStamp][byte[]] $BLOBTargetTimeStamp
            $StartIndex += 8

            $BLOBTargetState = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 4
            $Entry.TargetState = Convert-LEBytesToUInt32 $BLOBTargetState
            $StartIndex += 4

            $BLOBTargetType = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 4
            $Entry.TargetType = Convert-LEBytesToUInt32 $BLOBTargetType
            $StartIndex += 4

            $BLOBServerNameSize = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 2
            $Entry.ServerNameSize = Convert-LEBytesToUInt16 $BLOBServerNameSize
            $StartIndex += 2

            $BLOBServerName = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length $Entry.ServerNameSize
            $Entry.ServerName = Convert-LEBytesToString $BLOBServerName
            $StartIndex += $Entry.ServerNameSize

            $BLOBShareNameSize = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 2
            $Entry.ShareNameSize = Convert-LEBytesToUInt16 $BLOBShareNameSize
            $StartIndex += 2

            $BLOBShareName = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length $Entry.ShareNameSize
            $Entry.ShareName = Convert-LEBytesToString $BLOBShareName
            $StartIndex += $Entry.ShareNameSize

            $this.TargetEntries += $Entry
        }
    }

    [void] Print()
    {
        $Padding = '        '
        Write-Host ($Padding + "State`tType`tServerName`t`t`tShareName")
        foreach ($TargetEntry in $this.TargetEntries)
        {
            Write-Host ($Padding + $TargetEntry.TargetState + "`t" + $TargetEntry.TargetType + "`t" + $TargetEntry.ServerName + "`t`t`t" + $TargetEntry.ShareName)
        }
    }
}

class TargetEntry
{
    [uint32] $TargetEntrySize;
    [TimeStamp] $TargetTimeStamp;
    [byte] $PriorityRank;
    [byte] $PriorityClass;
    [uint32] $TargetState;
    [uint32] $TargetType;
    [uint16] $ServerNameSize;
    [string] $ServerName;
    [uint16] $ShareNameSize;
    [string] $ShareName;
}

class SiteEntry
{
    [uint16] $ServerNameSize;
    [string] $ServerName;
    [uint32] $SiteNameInfoCount;
    [SiteNameInfo[]] $SiteNameInfo;

    [void] Print()
    {
        $Padding = '    '
        Write-Host ($Padding + $this.ServerName)
        $Padding += '    '
        foreach ($Info in $this.SiteNameInfo)
        {
            Write-Host ($Padding + 'SiteName: ' + $Info.SiteName)
        }
    }
}

class SiteNameInfo
{
    [uint32] $Flags;
    [uint16] $SiteNameSize;
    [string] $SiteName;
}

class TimeStamp
{
    [uint32] $dwLowDateTime;
    [uint32] $dwHighDateTime;

    TimeStamp([byte[]] $BLOBTimeStamp)
    {
        $this.dwLowDateTime = Convert-LEBytesToUInt32 (Get-SubArray -Source $BLOBTimeStamp -StartIndex 0 -Length 4)
        $this.dwHighDateTime = Convert-LEBytesToUInt32 (Get-SubArray -Source $BLOBTimeStamp -StartIndex 4 -Length 4)
    }
}

enum RootOrLinkType
{
    PKT_ENTRY_TYPE_DFS = 0x1;
    PKT_ENTRY_TYPE_OUTSIDE_MY_DOM = 0x10;
    PKT_ENTRY_TYPE_INSITE_ONLY = 0x20;
    PKT_ENTRY_TYPE_COST_BASED_SITE_SELECTION = 0x40;
    PKT_ENTRY_TYPE_REFERRAL_SVC = 0x80;
    PKT_ENTRY_TYPE_ROOT_SCALABILITY = 0x200;
    PKT_ENTRY_TYPE_TARGET_FAILBACK = 0x8000;
}

enum RootOrLinkState
{
    DFS_VOLUME_STATE_OK = 0x1;
    RESERVED = 0x2;
    DFS_VOLUME_STATE_OFFLINE = 0x3;
    DFS_VOLUME_STATE_ONLINE = 0x4;
}
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

class PKT
{
    [uint32] $Version;
    [uint32] $ElementCount;
    [DFSNamespaceElement[]] $Elements;

    [byte[]] $RawData;

    PKT([byte[]] $Data)
    {
        $this.RawData = $Data
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

    [string[]] Print()
    {
        return $this.Print('All')
    }
    [string[]] Print([string] $Type)
    {
        [string[]] $PrintString = @()
        foreach ($Element in $this.Elements)
        {
            $PrintString += $Element.Name
            $Element.Print($Type, [ref] $PrintString)
        }
        return $PrintString
    }

    [string[]] PrintTree()
    {
        [string[]] $TreeString = @()
        $TreeString += "PKT"
        $TreeString += "+---Version: $($this.Version) (0,4)"
        $TreeString += "+---ElementCount: $($this.ElementCount) (4,4)"
        $TreeString += "\---Elements (8,$($this.RawData.Length - 8))"
        $Offset = 8
        for ($i = 0; $i -lt $this.ElementCount; $i++)
        {
            if ($i -eq ($this.ElementCount - 1))
            {
                $TreeString += '    \---Element'
                $Offset = $this.Elements[$i].PrintTree($Offset, '        ', [ref] $TreeString)
            }
            else
            {
                $TreeString += '    +---Element'
                $Offset = $this.Elements[$i].PrintTree($Offset, '    |   ', [ref] $TreeString)
            }
        }
        return $TreeString
    }

    [string] PrintRaw()
    {
        return [System.BitConverter]::ToString($this.RawData)
    }

    [void] WriteRaw([string] $Path)
    {
        $this.RawData | Out-File $Path
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

    [void] Print([string] $Type, [ref] $RefPrintString)
    {
        $PrintString = $RefPrintString.Value
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
            '\domainroot' { $this.DataRootOrLink.Print([ref] $PrintString) }
            '\siteroot' { $this.DataSite.Print([ref] $PrintString) }
            Default { $this.DataRootOrLink.Print([ref] $PrintString) }
        }
        $RefPrintString.Value = $PrintString
    }

    [uint32] PrintTree([uint32] $Offset, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---NameSize: $($this.NameSize) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad+---Name: $($this.Name) ($Offset,$($this.NameSize))"
        $Offset += $this.NameSize
        $TreeString += "$Pad+---DataSize: $($this.DataSize) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad\---Data ($Offset,$($this.DataSize))"
        switch ($this.Name)
        {
            '\domainroot' { $this.DataRootOrLink.PrintTree($Offset, $Pad + '    ', [ref] $TreeString) }
            '\siteroot' { $this.DataSite.PrintTree($Offset, $this.DataSize, $Pad + '    ', [ref] $TreeString) }
            Default { $this.DataRootOrLink.PrintTree($Offset, $Pad + '    ', [ref] $TreeString) }
        }
        $Offset += $this.DataSize
        $RefTreeString.Value = $TreeString
        return $Offset
    }
}

class DFSNamespaceRootOrLink
{
    [guid] $RootOrLinkGuid;
    [uint16] $PrefixSize;
    [string] $Prefix;
    [uint16] $ShortPrefixSize;
    [string] $ShortPrefix;
    [RootOrLinkType] $Type;
    [RootOrLinkState] $State;
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
        $this.Type = [Enum]::ToObject([RootOrLinkType], (Convert-LEBytesToUInt32 $BLOBType))
        $StartIndex += 4

        $BLOBState = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.State = [Enum]::ToObject([RootOrLinkState], (Convert-LEBytesToUInt32 $BLOBState))
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

    [void] Print([ref] $RefPrintString)
    {
        $PrintString = $RefPrintString.Value
        $Pad = '    '
        $PrintString += ($Pad + "Prefix     : " + $this.Prefix)
        $PrintString += ($Pad + "Type       : " + $this.Type)
        $PrintString += ($Pad + "State      : " + $this.State)
        $PrintString += ($Pad + "Comment    : " + $this.Comment)
        $PrintString += ($Pad + "TTL        : " + $this.ReferralTTL)
        $PrintString += ($Pad + "TargetList : ")
        $this.TargetList.Print([ref] $PrintString)
        $RefPrintString.Value = $PrintString
    }

    [uint32] PrintTree([uint32] $Offset, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---Guid: $($this.RootOrLinkGuid) ($Offset,16)"
        $Offset += 16
        $TreeString += "$Pad+---PrefixSize: $($this.PrefixSize) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad+---Prefix: $($this.Prefix) ($Offset,$($this.PrefixSize))"
        $Offset += $this.PrefixSize
        $TreeString += "$Pad+---ShortPrefixSize: $($this.ShortPrefixSize) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad+---ShortPrefix: $($this.ShortPrefix) ($Offset,$($this.ShortPrefixSize))"
        $Offset += $this.ShortPrefixSize
        $TreeString += "$Pad+---Type: $($this.Type) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---State: $($this.State) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---CommentSize: $($this.CommentSize) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad+---Comment: $($this.Comment) ($Offset,$($this.CommentSize))"
        $Offset += $this.CommentSize
        $TreeString += "$Pad+---PrefixTimeStamp: $($this.PrefixTimeStamp) ($Offset,8)"
        $Offset += 8
        $TreeString += "$Pad+---StateTimeStamp: $($this.StateTimeStamp) ($Offset,8)"
        $Offset += 8
        $TreeString += "$Pad+---CommentTimeStamp: $($this.CommentTimeStamp) ($Offset,8)"
        $Offset += 8
        $TreeString += "$Pad+---Version: $($this.Version) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---TargetListSize: $($this.TargetListSize) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---TargetList ($Offset,$($this.TargetListSize))"
        $this.TargetList.PrintTree($Offset, $this.TargetListSize, $Pad + '|   ', [ref] $TreeString)
        $Offset += $($this.TargetListSize)
        $TreeString += "$Pad+---ReservedBlobSize: $($this.ReservedBlobSize) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---ReservedBlob: $($this.ReservedBlob) ($Offset,$($this.ReservedBlobSize))"
        $Offset += $this.ReservedBlobSize
        $TreeString += "$Pad\---ReferralTTL: $($this.ReferralTTL) ($Offset,4)"
        $Offset += 4
        $RefTreeString.Value = $TreeString
        return $Offset
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

    [void] Print([ref] $RefPrintString)
    {
        $PrintString = $RefPrintString.Value
        foreach ($SiteEntry in $this.SiteEntries)
        {
            $SiteEntry.Print([ref] $PrintString)
        }
        $RefPrintString.Value = $PrintString 
    }

    [uint32] PrintTree([uint32] $Offset, [uint32] $FullSize, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---Guid: $($this.SiteTableGuid) ($Offset,16)"
        $Offset += 16
        $TreeString += "$Pad+---SiteEntryCount: $($this.SiteEntryCount) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad\---SiteEntries ($Offset,$($FullSize - 20))"
        for ($i = 0; $i -lt $this.SiteEntries.Count; $i++)
        {
            if ($i -eq $this.SiteEntries.Count - 1)
            {
                $TreeString += "$Pad    \---Site Entry"
                $Pad2 = '        ' 
            }
            else
            {
                $TreeString += "$Pad    +---Site Entry"
                $Pad2 = '    |   ' 
            }
            $Offset = $this.SiteEntries[$i].PrintTree($Offset, $FullSize - 20, $Pad + $Pad2, [ref] $TreeString)
        }
        $RefTreeString.Value = $TreeString
        return $Offset
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

            $BLOBTargetTimeStamp = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 8
            $Entry.TargetTimeStamp = [TimeStamp][byte[]] $BLOBTargetTimeStamp
        
            # The actual implementation of PriorityRank and PriorityClass seems to be different from doc
            # Actual: | PriorityClass 3 bits | PriorityRank 5 bits |
            # Doc:    | PriorityRank 5 bits | PriorityClass 3 bits |
            $BLOBTargetPriority = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 1
            $Entry.PriorityRank = $BLOBTargetPriority -band 0x1F
            $Entry.PriorityClass = [Enum]::ToObject([PriorityClass], ($BLOBTargetPriority -band 0xE0) -shr 5)
            $StartIndex += 8

            $BLOBTargetState = Get-SubArray -Source $BLOBTargetEntries -StartIndex $StartIndex -Length 4
            $Entry.TargetState = [Enum]::ToObject([TargetState], (Convert-LEBytesToUInt32 $BLOBTargetState))
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

    [void] Print([ref] $RefPrintString)
    {
        $PrintString = $RefPrintString.Value
        $Pad = '        '
        $PrintString += ($Pad + "State    Type    PriorityClass    PriorityRank    ServerName    ShareName")
        foreach ($TargetEntry in $this.TargetEntries)
        {
            $PrintString += ($Pad + $TargetEntry.TargetState + "    " + $TargetEntry.TargetType + "    " + $TargetEntry.PriorityClass + "    " + $TargetEntry.PriorityRank + "    " + $TargetEntry.ServerName + "    " + $TargetEntry.ShareName)
        }
        $RefPrintString.Value = $PrintString
    }

    [uint32] PrintTree([uint32] $Offset, [uint32] $TargetListSize, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---TargetCount: $($this.TargetCount) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad\---TargetEntries ($Offset, $($TargetListSize - 4))"
        for ($i = 0; $i -lt $this.TargetEntries.Count; $i++)
        {
            if ($i -eq $this.TargetEntries.Count - 1)
            { 
                $TreeString += "$Pad    \---Target Entry"
                $Pad2 = '        ' 
            } 
            else 
            { 
                $TreeString += "$Pad    +---Target Entry"
                $Pad2 = '    |   ' 
            }
            $Offset = $this.TargetEntries[$i].PrintTree($Offset, $Pad + $Pad2, [ref] $TreeString)
        }
        $RefTreeString.Value = $TreeString
        return $Offset
    }
}

class TargetEntry
{
    [uint32] $TargetEntrySize;
    [TimeStamp] $TargetTimeStamp;
    [byte] $PriorityRank;
    [PriorityClass] $PriorityClass;
    [TargetState] $TargetState;
    [uint32] $TargetType; # Should be 0x2
    [uint16] $ServerNameSize;
    [string] $ServerName;
    [uint16] $ShareNameSize;
    [string] $ShareName;

    [uint32] PrintTree([uint32] $Offset, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---TargetEntrySize: $($this.TargetEntrySize) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---TargetTimeStamp: $($this.TargetTimeStamp) ($Offset,8)"
        $Offset += 8
        $TreeString += "$Pad+---TargetState: $($this.TargetState) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---TargetType: $($this.TargetType) ($Offset,4)"
        $Offset += 4
        $TreeString += "$Pad+---ServerNameSize: $($this.ServerNameSize) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad+---ServerName: $($this.ServerName) ($Offset,$($this.ServerNameSize))"
        $Offset += $this.ServerNameSize
        $TreeString += "$Pad+---ShareNameSize: $($this.ShareNameSize) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad\---ShareName: $($this.ShareName) ($Offset,$($this.ShareNameSize))"
        $Offset += $this.ShareNameSize
        $RefTreeString.Value = $TreeString
        return $Offset
    }
}

class SiteEntry
{
    [uint16] $ServerNameSize;
    [string] $ServerName;
    [uint32] $SiteNameInfoCount;
    [SiteNameInfo[]] $SiteNameInfo;

    [void] Print([ref] $RefPrintString)
    {
        $PrintString = $RefPrintString.Value
        $Pad = '    '
        $PrintString += ($Pad + $this.ServerName)
        $Pad += '    '
        foreach ($Info in $this.SiteNameInfo)
        {
            $PrintString += ($Pad + 'SiteName: ' + $Info.SiteName)
        }
        $RefPrintString.Value = $PrintString 
    }

    [uint32] PrintTree([uint32] $Offset, [uint32] $FullSize, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---ServerNameSize: $($this.ServerNameSize) ($Offset,2))"
        $Offset += 2
        $TreeString += "$Pad+---ServerName: $($this.ServerName) ($Offset,$($this.ServerNameSize))"
        $Offset += $this.ServerNameSize
        $TreeString += "$Pad+---SiteNameInfoCount: $($this.SiteNameInfoCount) ($Offset,2)"
        $Offset += 2
        $TreeString += "$Pad\---SiteNameInfo ($Offset,$($FullSize - 4 - $this.ServerNameSize))"
        foreach ($Info in $this.SiteNameInfo)
        {
            $Offset = $Info.PrintTree($Offset, $Pad + '    ', [ref] $TreeString)
        }
        $RefTreeString.Value = $TreeString
        return $Offset
    }
}

class SiteNameInfo
{
    [uint32] $Flags; # Must be 0
    [uint16] $SiteNameSize;
    [string] $SiteName;

    [uint32] PrintTree([uint32] $Offset, [string] $Pad, [ref] $RefTreeString)
    {
        $TreeString = $RefTreeString.Value
        $TreeString += "$Pad+---Flags: $($this.Flags) ($Offset,4))"
        $Offset += 4
        $TreeString += "$Pad+---SiteNameSize: $($this.SiteNameSize) ($Offset,2))"
        $Offset += 2
        $TreeString += "$Pad+---SiteName: $($this.SiteName) ($Offset,$($this.SiteNameSize))"
        $Offset += $this.SiteNameSize
        $RefTreeString.Value = $TreeString
        return $Offset
    }
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

    [string] ToString()
    {
        return "$($this.dwHighDateTime) $($this.dwLowDateTime)"
    }
}

[Flags()] enum RootOrLinkType
{
    PKT_ENTRY_TYPE_DFS = 0x1;
    PKT_ENTRY_TYPE_OUTSIDE_MY_DOM = 0x10;
    PKT_ENTRY_TYPE_INSITE_ONLY = 0x20;
    PKT_ENTRY_TYPE_COST_BASED_SITE_SELECTION = 0x40;
    PKT_ENTRY_TYPE_REFERRAL_SVC = 0x80;
    PKT_ENTRY_TYPE_ROOT_SCALABILITY = 0x200;
    PKT_ENTRY_TYPE_TARGET_FAILBACK = 0x8000;
}

[Flags()] enum RootOrLinkState
{
    DFS_VOLUME_STATE_OK = 0x1;
    RESERVED = 0x2;
    DFS_VOLUME_STATE_OFFLINE = 0x3;
    DFS_VOLUME_STATE_ONLINE = 0x4;
}

[Flags()] enum TargetState
{
    DFS_STORAGE_STATE_OFFLINE = 0x1;
    DFS_STORAGE_STATE_ONLINE = 0x2;
    DFS_STORAGE_STATE_ACTIVE = 0x4;
}

[Flags()] enum PriorityClass
{
    DFS_TARGET_PRIORITY_CLASS_SITE_COST_NORMAL = 0x0;
    DFS_TARGET_PRIORITY_CLASS_GLOBAL_HIGH = 0x1;
    DFS_TARGET_PRIORITY_CLASS_SITE_COST_HIGH = 0x2;
    DFS_TARGET_PRIORITY_CLASS_SITE_COST_LOW = 0x3;
    DFS_TARGET_PRIORITY_CLASS_GLOBAL_LOW = 0x4;
}
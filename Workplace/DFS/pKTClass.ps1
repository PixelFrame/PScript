# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsnm/54e3ec05-913f-4d6d-932b-095f457fd543
# PowerShell class for DFS namespacev1

function Get-SubArray
{
    param (
        [object[]] $Source,
        [int] $StartIndex,
        [int] $Length
    )
    
    $Result = New-Object 'Object[]' -ArgumentList $Length
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
    [System.Text.Encoding]::Unicode.GetString($Bytes)
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
        $this.lementCount = Convert-LEBytesToUInt32 $BLOBElementCount

        $BLOBElement = Get-SubArray -Source $Data -StartIndex 8 -Length ($Data.Length - 8)
        $this.CreateElements($BLOBElement)
    }

    [void] CreateElements([byte[]] $BLOBElement)
    {
        $CreatedCount = 0
        $StartIndex = 0
        while ($CreatedCount -lt $this.ElementCount)
        {
            $Element = New-Object DFSNamespaceElement
            $BLOBNameSize = Get-SubArray -Source $BLOBElement -StartIndex $StartIndex -Length 2
            $StartIndex += 2
            $Element.NameSize = Convert-LEBytesToUInt16 -Bytes $BLOBNameSize
            $BLOBName = Get-SubArray -Source $BLOBElement -StartIndex $StartIndex -Length $Element.NameSize
            $StartIndex += $Element.NameSize
            $Element.Name = Convert-LEBytesToString -Bytes $BLOBName
            $BLOBDataSize = Get-SubArray -Source $BLOBElement -StartIndex $StartIndex -Length 4
            $StartIndex += 4
            $Element.DataSize = Convert-LEBytesToUInt32 -Bytes $BLOBDataSize
            $BLOBData = Get-SubArray -Source $BLOBElement -StartIndex $StartIndex -Length $Element.DataSize
            $Element.SetData($BLOBData)
            $StartIndex += $Element.DataSize
            $this.Elements += $Element
        }
    }
}

class DFSNamespaceElement
{
    [uint16] $NameSize;
    [string] $Name;
    [uint32] $DataSize;
    [DFSNamespaceRoot] $DataRoot;
    [DFSNamespaceLink] $DataLink;
    [SiteInformation] $DataSite;

    [void] SetData($BLOBData)
    {
        switch ($this.Name)
        {
            '\domainroot' { $this.DataRoot = [DFSNamespaceRoot] $BLOBData }
            '\siteroot' { $this.DataSite = [SiteInformation]$BLOBData }
            Default { $this.DataLink = [DFSNamespaceLink]$BLOBData }
        }
    }
}

class DFSNamespaceRoot
{
    [guid] $RootGuid;
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

    DFSNamespaceRoot([byte[]] $BLOBData)
    {
        $StartIndex = 0

        $BLOBGuid = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 16
        $this.RootGuid = [Guid] $BLOBGuid
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
        $this.PrefixTimeStamp = [TimeStamp] $BLOBPrefixTimeStamp
        $StartIndex += 8

        $BLOBStateTimeStamp = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 8
        $this.StateTimeStamp = [TimeStamp] $BLOBStateTimeStamp
        $StartIndex += 8

        $BLOBCommentTimeStamp = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 8
        $this.CommentTimeStamp = [TimeStamp] $BLOBCommentTimeStamp
        $StartIndex += 8

        $BLOBVersion = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.Version = Convert-LEBytesToUInt32 $BLOBVersion
        $StartIndex += 4

        $BLOBTargetListSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.TargetListSize = Convert-LEBytesToUInt32 $BLOBTargetListSize
        $StartIndex += 4

        $BLOBTargetList = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $this.TargetListSize
        $this.TargetList = [TargetList] $BLOBTargetList
        $StartIndex += $this.TargetListSize

        $BLOBReservedBlobSize = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.ReservedBlobSize = Convert-LEBytesToUInt32 $BLOBReservedBlobSize
        $StartIndex += 4

        $BLOBReservedBlob = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length $BLOBReservedBlobSize
        $this.ReservedBlob = Convert-LEBytesToUInt32 $BLOBReservedBlob
        $StartIndex += $BLOBReservedBlobSize

        $BLOBReferralTTL = Get-SubArray -Source $BLOBData -StartIndex $StartIndex -Length 4
        $this.ReferralTTL = Convert-LEBytesToUInt32 $BLOBReferralTTL
        $StartIndex += 4

        if ($StartIndex -lt $BLOBData.Length)
        {
            Write-Host '[Warning] Inconsistent Data Length!' -ForegroundColor Yellow
        }
    }
}

class DFSNamespaceLink
{
    
}

class SiteInformation
{
    
}

class TargetList
{
    [uint32] $TargetCount
    [TargetEntry[]] $TargetEntries
}

class TargetEntry
{
    
}

class TimeStamp
{
    [uint32] $dwLowDateTime;
    [uint32] $dwHighDateTime;
}
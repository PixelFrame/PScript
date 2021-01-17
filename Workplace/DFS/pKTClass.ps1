# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dfsnm/54e3ec05-913f-4d6d-932b-095f457fd543
# PowerShell class for DFS namespacev1

class pKT
{
    [uint32] $BLOBVersion;
    [uint32] $BLOBElementCount;
    [DFSNamespaceElementBLOB[]] $BLOBElement;

    pKT([byte[]] $Data)
    {

    }
}

class DFSNamespaceElementBLOB
{
    [uint16] $BLOBNameSize;
    [string] $BLOBName;
    [uint32] $BLOBDataSize;
    [DFSNamespaceRootBLOB[]] $BLOBDataRoot;
    [DFSNamespaceLinkBLOB[]] $BLOBDataLink;
    [SiteInformationBLOB[]] $BLOBDataSite;
}

class DFSNamespaceRootBLOB
{
    
}

class DFSNamespaceLinkBLOB
{
    
}

class SiteInformationBLOB
{
    
}
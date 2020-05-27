#######################################################################
# Run on 2K08 machine to export the namespace list

dfsutil server srv2k08.domain.lab | findstr \ > C:\Namespaces.txt

#######################################################################
# Run on 2K12 machine to create the DFS root folder and SMB share

$Namespaces = Get-Content -Path C:\Namespaces.txt

if (!(Test-Path -Path C:\DFSRoots\)) { mkdir C:\DFSRoots\ }
foreach ($Namespace in $Namespaces)
{
    $Namespace = $Namespace.Split('\')[2]
    mkdir "C:\DFSRoots\$Namespace"
    New-SmbShare -Path "C:\DFSRoots\$Namespace" -Name $Namespace -ReadAccess everyone
}

#######################################################################
# Run on 2K08 machine to add the namespace target

$Namespaces = Get-Content -Path C:\Namespaces.txt

foreach ($Namespace in $Namespaces)
{
    $Namespace = $Namespace.Split('\')[2]
    dfsutil target add "\\srv2k12.domain.lab\$Namespace"
}
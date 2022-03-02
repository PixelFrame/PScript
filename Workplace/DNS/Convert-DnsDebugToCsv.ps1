[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Source
)

try
{
    $SourceFile = Get-Item $Source -ErrorAction Stop
    if ($SourceFile.Mode.Contains('d')) { throw new System.IO.FileNotFoundException }
}
catch
{
    Write-Error "$Source is not found or not a file"
    exit
}

$Header = 'DateTime,TID,EventType,InternalID,Protocol,Direction,Address,XID,Flags,QType,Name'
$OutFile = '{0}\{1}.csv' -f $SourceFile.DirectoryName, $SourceFile.BaseName

try
{
    $Reader = New-Object System.IO.StreamReader -ArgumentList $SourceFile.FullName
    $Writer = New-Object System.IO.StreamWriter -ArgumentList $OutFile

    $Writer.WriteLine($Header)

    while ($null -ne ($Line = $Reader.ReadLine()))
    {
        if ($Line.Contains(' PACKET  ')) {
            $LenTime = $Line.IndexOf(' AM ')
            if ($LenTime -lt 0) {
                $LenTime = $Line.IndexOf('PM') + 3
            } else {
                $LenTime += 3
            }
            $Length = @($LenTime, 4, 7, 18, 4, 4, 17, 4, 25, 7)
            $RegexAddComma = New-Object Regex "(.{$($Length[0])})(.{$($Length[1])})(.{$($Length[2])})(.{$($Length[3])})(.{$($Length[4])})(.{$($Length[5])})(.{$($Length[6])})(.{$($Length[7])})(.{$($Length[8])})(.{$($Length[9])})(.*)"
            $Segs = $RegexAddComma.Split($Line)
            $NewLine = "$($Segs[1].Trim()),0x$($Segs[2]),$($Segs[3].Trim()),$($Segs[4].Trim()),$($Segs[5].Trim()),$($Segs[6].Trim()),$($Segs[7].Trim()),0x$($Segs[8]),$($Segs[9].Trim()),$($Segs[10].Trim()),$($Segs[11].Trim())"
            $Writer.WriteLine($NewLine)
        }
    }
}
finally
{
    if ($null -ne $Writer)
    {
        $Writer.Close()
    }
    if ($null -ne $Reader)
    {
        $Reader.Close()
    }
}
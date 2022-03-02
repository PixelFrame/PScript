[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Source,

    [Parameter(ParameterSetName = 'Line')]
    [UInt32]
    $LineLimit = 500000,

    [Parameter(ParameterSetName = 'Size')]
    [UInt32]
    $SizeLimit = 100MB,

    [Parameter(ParameterSetName = 'Size')]
    [ValidateSet('Loose', 'Strict')]
    [string]
    $SizeMode = 'Loose'
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

try
{
    $Reader = New-Object System.IO.StreamReader -ArgumentList $SourceFile.FullName
    $FileCounter = 0
    $CurrentFile = '{0}\{1}_Split{2}{3}' -f $SourceFile.DirectoryName, $SourceFile.BaseName, $FileCounter, $SourceFile.Extension
    $Writer = New-Object System.IO.StreamWriter -ArgumentList $CurrentFile
    $Line = ''
    $LineCounter = 1
    
    if ($PSCmdlet.ParameterSetName -eq 'Line') {
        while ($null -ne ($Line = $Reader.ReadLine()))
        {
            if ($LineCounter -gt $LineLimit)
            {
                $Writer.Close()
                $LineCounter = 1
                $FileCounter++
                $CurrentFile = '{0}\{1}_Split{2}{3}' -f $SourceFile.Directory.FullName, $SourceFile.BaseName, $FileCounter, $SourceFile.Extension
                $Writer = New-Object System.IO.StreamWriter -ArgumentList $CurrentFile
            }
            $Writer.WriteLine($Line)
            $LineCounter++
        }
    } else {        
        while ($null -ne ($Line = $Reader.ReadLine()))
        {
            if (($SizeMode -eq 'Loose' -and $LineCounter -eq 10000) -or ($SizeMode -eq 'Strict')) {
                $Writer.Flush()
            }
            if ($Writer.BaseStream.Length -gt $SizeLimit)
            {
                $Writer.Close()
                $LineCounter = 1
                $FileCounter++
                $CurrentFile = '{0}\{1}_Split{2}{3}' -f $SourceFile.Directory.FullName, $SourceFile.BaseName, $FileCounter, $SourceFile.Extension
                $Writer = New-Object System.IO.StreamWriter -ArgumentList $CurrentFile
            }
            $Writer.WriteLine($Line)
            $LineCounter++
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
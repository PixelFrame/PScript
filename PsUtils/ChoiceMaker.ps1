function Roll
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $ChoiceEntryFile = "E:\Scripts\Misc\Choices.txt",

        [switch]
        $NoCls
    )

    if (!$NoCls) { Clear-Host }
    [string[]] $Choices = Get-Content $ChoiceEntryFile -ErrorAction Stop | Where-Object { $_ -ne '' }
    [string[]] $Colors = @('Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow')

    $RngCsp = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $Bytes = New-Object byte[] -ArgumentList 4
    $RngCsp.GetNonZeroBytes($Bytes)

    $Seed = [BitConverter]::ToInt32($Bytes, 0)

    $Dice = Get-Random -Maximum 250 -Minimum 50 -SetSeed $Seed
    $Cnt = 0
    $ColorPtr = 0

    foreach ($Choice in $Choices)
    {
        $PadLen = 10 - $Choice.Length
        $ChoiceWithPadding = $Choice
        if ($PadLen -lt 0)
        {
            $ChoiceWithPadding = $ChoiceWithPadding.Remove(7)
            $ChoiceWithPadding += '.'
        }
        else
        {
            $ChoiceWithPadding += ' ' * $PadLen
        }
        if ($ColorPtr -eq 6)
        {
            $ColorPtr = 0
        }
        Write-Host $ChoiceWithPadding -NoNewline -BackgroundColor $Colors[$ColorPtr++] -ForegroundColor White
    }
    Write-Host
    while ($Cnt++ -lt $Dice)
    {
        if ($Dice - $Cnt -lt 30)
        {
            Start-Sleep -Milliseconds 100
        }
        if ($Dice - $Cnt -lt 20)
        {
            Start-Sleep -Milliseconds 100
        }
        if ($Dice - $Cnt -lt 10)
        {
            Start-Sleep -Milliseconds 100
        }
    
        Write-Host "`r" -NoNewline
        Write-Host (" " * 10 * $Choices.Count) -NoNewline
        Write-Host "`r" -NoNewline

        $Pos = $Cnt % $Choices.Count
        $PadLen = 10 * $Pos
        Write-Host (' ' * $PadLen + '^') -NoNewline
    }
    Write-Host
    $Repeat = Read-Host -Prompt 'One more time? Y/N'
    if ($Repeat -eq 'y' -or $Repeat -eq 'Y')
    {
        Roll -NoCls
    }
}

Roll
Pause
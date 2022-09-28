function MapByteToChar {
    param (
        [byte] $b
    )
    if($b -lt 32)
    {
        $b += 32
        return MapByteToChar($b)
    }
    if($b -gt 126)
    {
        $b -= 126
        return MapByteToChar($b)
    }

    return [char] $b
}

while ($true) {
    $Width = $Host.UI.RawUI.WindowSize.Width
    $data = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Width)
    $line = ''
    foreach ($b in $data) {
        $line += MapByteToChar($b)
    }
    Write-Host $line -ForegroundColor DarkGreen
    Start-Sleep -Milliseconds 50
}
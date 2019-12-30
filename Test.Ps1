try
{
    Get-Command -Name NotACommand
    Get-Command -Name NotACommand -ErrorAction Stop
}
catch
{
    Write-Host Thrown
}
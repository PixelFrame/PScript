$Dependents = (Get-Service -Name 'WinHttpAutoProxySvc').DependentServices | Where-Object { $_.Status -eq 'Running' }
Stop-Process -Id (Get-WmiObject win32_service | Where-Object { $_.name -eq 'WinHttpAutoProxySvc' }).processID -Force
Start-Service 'WinHttpAutoProxySvc'
foreach ($Dependent in $Dependents)
{
    Start-Service $Dependent
}
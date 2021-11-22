# Capture traffic of a VM when launching

$VMName = 'HV-PXE'
$Output = "D:\$VMName-boot-pktmon.etl"

Start-VM -Name $VMName
$Comps = ((pktmon comp list | Where-Object {$_.contains($VMName)}).Trim() | ForEach-Object { $_.Split()[0] }) -Join ','
PktMon.exe start -c --comp $Comps --pkt-size 0 -f $Output
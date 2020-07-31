param (
    [Parameter()]
    [int]
    [ValidateRange(0, 3)]
    $Mode = 0
)

try
{
    Get-NetQosPolicy -Name 'QoS Policy' -ErrorAction Stop
}
catch
{
    New-NetQosPolicy -Name 'QoS Policy' -AppPathNameMatchCondition 'iperf3.exe' -ThrottleRateActionBitsPerSecond 1MB
}

switch ($Mode)
{
    0
    { 
        Set-NetQosPolicy -Name 'QoS Policy' -ThrottleRateActionBitsPerSecond 1MB
    }
    1
    { 
        Set-NetQosPolicy -Name 'QoS Policy' -ThrottleRateActionBitsPerSecond 2MB
    }
    2
    { 
        Set-NetQosPolicy -Name 'QoS Policy' -ThrottleRateActionBitsPerSecond 3MB
    }
    3
    { 
        Set-NetQosPolicy -Name 'QoS Policy' -ThrottleRateActionBitsPerSecond 4MB
    }
    Default {}
}
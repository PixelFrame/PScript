Get-NetTCPConnection | ForEach-Object -PipelineVariable TcpConn -Process { $_ } `
| ForEach-Object -PipelineVariable Proc -Process { Get-Process -Id $_.OwningProcess } `
| ForEach-Object { [PsCustomObject]@{ 
        LocalAddress  = $TcpConn.LocalAddress; 
        LocalPort     = $TcpConn.LocalPort; 
        RemoteAddress = $TcpConn.RemoteAddress;
        RemotePort    = $TcpConn.RemotePort;
        State         = $TcpConn.State;
        ProcessId     = $Proc.Id;
        ProcessName   = $Proc.ProcessName;
        ProcessHandle = $Proc.HandleCount
    } } `
| Format-Table -AutoSize

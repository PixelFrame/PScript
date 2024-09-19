[CmdletBinding()]
param (
    [Parameter(ParameterSetName = 'Directory')]
    [string] $Directory,
    
    [Parameter(ParameterSetName = 'Files')]
    [string[]] $Files
)

$CSharp = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

public class FastDel
{
    public static void DeleteDirContent(string path)
    {
        var files = Directory.EnumerateFiles(path);
        DeleteFiles(files);
    }

    public static void DeleteFiles(IEnumerable<string> files)
    {
        var start = DateTime.Now;
        var tasks = new List<Task>();
        foreach (var file in files)
        {
            tasks.Add(Task.Factory.StartNew(() => FastDelete(file)));
        }
        Task.WaitAll(tasks.ToArray());

        var end = DateTime.Now;
        Console.WriteLine("Done, time spent " + (end - start));
    }

    public static void FastDelete(string path)
    {
        var start = DateTime.Now;
        var hFile = PInvoke.CreateFile(path, 
            0x40000000, // GENERIC_WRITE
            0,          // Non-sharing
            IntPtr.Zero,
            3,          // OPEN_EXISTING
            0x04000000, // FILE_FLAG_DELETE_ON_CLOSE
            IntPtr.Zero);
        if (hFile.ToInt32() != -1)
        {
            PInvoke.CloseHandle(hFile);
            var end = DateTime.Now;
            Console.WriteLine("{0}, {1}", path, end - start);
        }
        else
        {
            Console.WriteLine("{0}, failed with 0x{1:X}", path, Marshal.GetLastWin32Error());
        }
    }
}

public static class PInvoke
{
    [DllImport("Kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
'@

Add-Type -TypeDefinition $CSharp

if ($PSCmdlet.ParameterSetName -eq 'Directory')
{ [FastDel]::DeleteDirContent($Directory) }
else
{ [FastDel]::DeleteFiles($Files) }

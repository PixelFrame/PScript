// Main Coding from http://pinvoke.net/default.aspx/netapi32/DsGetDcName.html

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace DsGetDc
{
    class NTDS
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DOMAIN_CONTROLLER_INFO
        {
            [MarshalAs(UnmanagedType.LPTStr)]
            public string DomainControllerName;
            [MarshalAs(UnmanagedType.LPTStr)]
            public string DomainControllerAddress;
            public uint DomainControllerAddressType;
            public Guid DomainGuid;
            [MarshalAs(UnmanagedType.LPTStr)]
            public string DomainName;
            [MarshalAs(UnmanagedType.LPTStr)]
            public string DnsForestName;
            public uint Flags;
            [MarshalAs(UnmanagedType.LPTStr)]
            public string DcSiteName;
            [MarshalAs(UnmanagedType.LPTStr)]
            public string ClientSiteName;
        }

        [DllImport("Netapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int DsGetDcName
        (
            [MarshalAs(UnmanagedType.LPTStr)]
            string ComputerName,
            [MarshalAs(UnmanagedType.LPTStr)]
            string DomainName,
            [In] Guid DomainGuid,
            [MarshalAs(UnmanagedType.LPTStr)]
            string SiteName,
            [MarshalAs(UnmanagedType.U4)]
            DSGETDCNAME_FLAGS flags,
            out IntPtr pDOMAIN_CONTROLLER_INFO
        );

        [DllImport("Netapi32.dll", SetLastError = true)]
        public static extern int NetApiBufferFree(IntPtr Buffer);

        [Flags]
        public enum DSGETDCNAME_FLAGS : uint
        {
            DS_FORCE_REDISCOVERY = 0x00000001,
            DS_DIRECTORY_SERVICE_REQUIRED = 0x00000010,
            DS_DIRECTORY_SERVICE_PREFERRED = 0x00000020,
            DS_GC_SERVER_REQUIRED = 0x00000040,
            DS_PDC_REQUIRED = 0x00000080,
            DS_BACKGROUND_ONLY = 0x00000100,
            DS_IP_REQUIRED = 0x00000200,
            DS_KDC_REQUIRED = 0x00000400,
            DS_TIMESERV_REQUIRED = 0x00000800,
            DS_WRITABLE_REQUIRED = 0x00001000,
            DS_GOOD_TIMESERV_PREFERRED = 0x00002000,
            DS_AVOID_SELF = 0x00004000,
            DS_ONLY_LDAP_NEEDED = 0x00008000,
            DS_IS_FLAT_NAME = 0x00010000,
            DS_IS_DNS_NAME = 0x00020000,
            DS_RETURN_DNS_NAME = 0x40000000,
            DS_RETURN_FLAT_NAME = 0x80000000
        }

        public static DOMAIN_CONTROLLER_INFO GetDomainInfo(string ComputerName, string DomainName, Guid DomainGuid, string SiteName)
        {
            DOMAIN_CONTROLLER_INFO domainInfo;
            const int ERROR_SUCCESS = 0;
            IntPtr pDCI = IntPtr.Zero;
            try
            {
                int val = DsGetDcName(ComputerName, DomainName, DomainGuid, SiteName,
                DSGETDCNAME_FLAGS.DS_DIRECTORY_SERVICE_REQUIRED |
                DSGETDCNAME_FLAGS.DS_RETURN_DNS_NAME |
                DSGETDCNAME_FLAGS.DS_IP_REQUIRED, out pDCI);
                //check return value for error
                if (ERROR_SUCCESS == val)
                {
                    domainInfo = (DOMAIN_CONTROLLER_INFO)Marshal.PtrToStructure(pDCI, typeof(DOMAIN_CONTROLLER_INFO));
                }
                else
                {
                    throw new Exception("Error: " + val);
                }
            }
            finally
            {
                NetApiBufferFree(pDCI);
            }
            return domainInfo;
        }
    }
}

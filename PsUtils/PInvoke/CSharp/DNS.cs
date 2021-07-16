using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;

namespace PlatInvoker
{
    public class DNS
    {
        [DllImport("dnsapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int DnsModifyRecordsInSet_W
        (
            IntPtr pAddRecords,
            IntPtr pDeleteRecords,
            DnsUpdateOption dnsOption,
            IntPtr hCredentials,
            IntPtr pSrvList,
            IntPtr pReserved
        );

        [Flags]
        public enum DnsUpdateOption : uint
        {
            DNS_UPDATE_SECURITY_USE_DEFAULT = 0x00000000,
            DNS_UPDATE_SECURITY_OFF = 0x00000010,
            DNS_UPDATE_SECURITY_ON = 0x00000020,
            DNS_UPDATE_SECURITY_ONLY = 0x00000100,
            DNS_UPDATE_CACHE_SECURITY_CONTEXT = 0x00000200,
            DNS_UPDATE_TEST_USE_LOCAL_SYS_ACCT = 0x00000400,
            DNS_UPDATE_FORCE_SECURITY_NEGO = 0x00000800,
            DNS_UPDATE_TRY_ALL_MASTER_SERVERS = 0x00001000,
            DNS_UPDATE_SKIP_NO_UPDATE_ADAPTERS = 0x00002000,
            DNS_UPDATE_REMOTE_SERVER = 0x00004000,
            DNS_UPDATE_RESERVED = 0xffff0000
        }

        // Following data type def from http://pinvoke.net/default.aspx/dnsapi/DnsQuery.html

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/cc982162(v=vs.85).aspx
        /// Also see http://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml
        /// </summary>
        public enum DnsRecordTypes
        {
            DNS_TYPE_A = 0x1,
            DNS_TYPE_NS = 0x2,
            DNS_TYPE_MD = 0x3,
            DNS_TYPE_MF = 0x4,
            DNS_TYPE_CNAME = 0x5,
            DNS_TYPE_SOA = 0x6,
            DNS_TYPE_MB = 0x7,
            DNS_TYPE_MG = 0x8,
            DNS_TYPE_MR = 0x9,
            DNS_TYPE_NULL = 0xA,
            DNS_TYPE_WKS = 0xB,
            DNS_TYPE_PTR = 0xC,
            DNS_TYPE_HINFO = 0xD,
            DNS_TYPE_MINFO = 0xE,
            DNS_TYPE_MX = 0xF,
            DNS_TYPE_TEXT = 0x10,       // This is how it's specified on MSDN
            DNS_TYPE_TXT = DNS_TYPE_TEXT,
            DNS_TYPE_RP = 0x11,
            DNS_TYPE_AFSDB = 0x12,
            DNS_TYPE_X25 = 0x13,
            DNS_TYPE_ISDN = 0x14,
            DNS_TYPE_RT = 0x15,
            DNS_TYPE_NSAP = 0x16,
            DNS_TYPE_NSAPPTR = 0x17,
            DNS_TYPE_SIG = 0x18,
            DNS_TYPE_KEY = 0x19,
            DNS_TYPE_PX = 0x1A,
            DNS_TYPE_GPOS = 0x1B,
            DNS_TYPE_AAAA = 0x1C,
            DNS_TYPE_LOC = 0x1D,
            DNS_TYPE_NXT = 0x1E,
            DNS_TYPE_EID = 0x1F,
            DNS_TYPE_NIMLOC = 0x20,
            DNS_TYPE_SRV = 0x21,
            DNS_TYPE_ATMA = 0x22,
            DNS_TYPE_NAPTR = 0x23,
            DNS_TYPE_KX = 0x24,
            DNS_TYPE_CERT = 0x25,
            DNS_TYPE_A6 = 0x26,
            DNS_TYPE_DNAME = 0x27,
            DNS_TYPE_SINK = 0x28,
            DNS_TYPE_OPT = 0x29,
            DNS_TYPE_DS = 0x2B,
            DNS_TYPE_RRSIG = 0x2E,
            DNS_TYPE_NSEC = 0x2F,
            DNS_TYPE_DNSKEY = 0x30,
            DNS_TYPE_DHCID = 0x31,
            DNS_TYPE_UINFO = 0x64,
            DNS_TYPE_UID = 0x65,
            DNS_TYPE_GID = 0x66,
            DNS_TYPE_UNSPEC = 0x67,
            DNS_TYPE_ADDRS = 0xF8,
            DNS_TYPE_TKEY = 0xF9,
            DNS_TYPE_TSIG = 0xFA,
            DNS_TYPE_IXFR = 0xFB,
            DNS_TYPE_AFXR = 0xFC,
            DNS_TYPE_MAILB = 0xFD,
            DNS_TYPE_MAILA = 0xFE,
            DNS_TYPE_ALL = 0xFF,
            DNS_TYPE_ANY = 0xFF,
            DNS_TYPE_WINS = 0xFF01,
            DNS_TYPE_WINSR = 0xFF02,
            DNS_TYPE_NBSTAT = DNS_TYPE_WINSR
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682056(v=vs.85).aspx
        /// </summary>
        public enum DNS_FREE_TYPE
        {
            DnsFreeFlat = 0,
            DnsFreeRecordList = 1,
            DnsFreeParsedMessageFields = 2
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682082(v=vs.85).aspx
        /// These field offsets could be different depending on endianness and bitness
        /// </summary>
        [StructLayout(LayoutKind.Explicit)]
        public struct DNS_RECORD
        {
            [FieldOffset(0)]
            public IntPtr pNext;    // DNS_RECORD*
            [FieldOffset(4)]
            public IntPtr pName;    // string
            [FieldOffset(8)]
            public ushort wType;
            [FieldOffset(10)]
            public ushort wDataLength;
            [FieldOffset(12)]
            public FlagsUnion Flags;
            [FieldOffset(16)]
            public uint dwTtl;
            [FieldOffset(20)]
            public uint dwReserved;
            [FieldOffset(24)]
            public DataUnion Data;
        }

        [StructLayout(LayoutKind.Explicit)]
        public struct FlagsUnion
        {
            [FieldOffset(0)]
            public uint DW;
            [FieldOffset(0)]
            public DNS_RECORD_FLAGS S;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682084(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_RECORD_FLAGS
        {
            internal uint data;

            // DWORD Section :2;
            public uint Section
            {
                get { return data & 0x3u; }
                set { data = (data & ~0x3u) | (value & 0x3u); }
            }

            // DWORD Delete :1;
            public uint Delete
            {
                get { return (data >> 2) & 0x1u; }
                set { data = (data & ~(0x1u << 2)) | (value & 0x1u) << 2; }
            }

            // DWORD CharSet :2;
            public uint CharSet
            {
                get { return (data >> 3) & 0x3u; }
                set { data = (data & ~(0x3u << 3)) | (value & 0x3u) << 3; }
            }

            // DWORD Unused :3;
            public uint Unused
            {
                get { return (data >> 5) & 0x7u; }
                set { data = (data & ~(0x7u << 5)) | (value & 0x7u) << 5; }
            }

            // DWORD Reserved :24;
            public uint Reserved
            {
                get { return (data >> 8) & 0xFFFFFFu; }
                set { data = (data & ~(0xFFFFFFu << 8)) | (value & 0xFFFFFFu) << 8; }
            }
        }

        [StructLayout(LayoutKind.Explicit)]
        public struct DataUnion
        {
            [FieldOffset(0)]
            public DNS_A_DATA A;
            [FieldOffset(0)]
            public DNS_SOA_DATA SOA, Soa;
            [FieldOffset(0)]
            public DNS_PTR_DATA PTR, Ptr, NS, Ns, CNAME, Cname, DNAME, Dname, MB, Mb, MD, Md, MF, Mf, MG, Mg, MR, Mr;
            [FieldOffset(0)]
            public DNS_MINFO_DATA MINFO, Minfo, RP, Rp;
            [FieldOffset(0)]
            public DNS_MX_DATA MX, Mx, AFSDB, Afsdb, RT, Rt;
            [FieldOffset(0)]
            public DNS_TXT_DATA HINFO, Hinfo, ISDN, Isdn, TXT, Txt, X25;
            [FieldOffset(0)]
            public DNS_NULL_DATA Null;
            [FieldOffset(0)]
            public DNS_WKS_DATA WKS, Wks;
            [FieldOffset(0)]
            public DNS_AAAA_DATA AAAA;
            [FieldOffset(0)]
            public DNS_KEY_DATA KEY, Key;
            [FieldOffset(0)]
            public DNS_SIG_DATA SIG, Sig;
            [FieldOffset(0)]
            public DNS_ATMA_DATA ATMA, Atma;
            [FieldOffset(0)]
            public DNS_NXT_DATA NXT, Nxt;
            [FieldOffset(0)]
            public DNS_SRV_DATA SRV, Srv;
            [FieldOffset(0)]
            public DNS_NAPTR_DATA NAPTR, Naptr;
            [FieldOffset(0)]
            public DNS_OPT_DATA OPT, Opt;
            [FieldOffset(0)]
            public DNS_DS_DATA DS, Ds;
            [FieldOffset(0)]
            public DNS_RRSIG_DATA RRSIG, Rrsig;
            [FieldOffset(0)]
            public DNS_NSEC_DATA NSEC, Nsec;
            [FieldOffset(0)]
            public DNS_DNSKEY_DATA DNSKEY, Dnskey;
            [FieldOffset(0)]
            public DNS_TKEY_DATA TKEY, Tkey;
            [FieldOffset(0)]
            public DNS_TSIG_DATA TSIG, Tsig;
            [FieldOffset(0)]
            public DNS_WINS_DATA WINS, Wins;
            [FieldOffset(0)]
            public DNS_WINSR_DATA WINSR, WinsR, NBSTAT, Nbstat;
            [FieldOffset(0)]
            public DNS_DHCID_DATA DHCID;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682044(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_A_DATA
        {
            public uint IpAddress;      // IP4_ADDRESS IpAddress;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682096(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_SOA_DATA
        {
            public IntPtr pNamePrimaryServer;       // string
            public IntPtr pNameAdministrator;       // string
            public uint dwSerialNo;
            public uint dwRefresh;
            public uint dwRetry;
            public uint dwExpire;
            public uint dwDefaultTtl;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682080(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_PTR_DATA
        {
            public IntPtr pNameHost;    // string
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682067(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_MINFO_DATA
        {
            public IntPtr pNameMailbox;     // string
            public IntPtr pNameErrorsMailbox;       // string
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682070(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_MX_DATA
        {
            public IntPtr pNameExchange;        // string
            public ushort wPreference;
            public ushort Pad;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682109(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_TXT_DATA
        {
            public uint dwStringCount;
            public IntPtr pStringArray;     // PWSTR pStringArray[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682074(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_NULL_DATA
        {
            public uint dwByteCount;
            public IntPtr Data;           // BYTE  Data[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682120(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_WKS_DATA
        {
            public uint IpAddress;      // IP4_ADDRESS IpAddress;
            public byte chProtocol;     // UCHAR       chProtocol;
            public IntPtr BitMask;        // BYTE    BitMask[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682035(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_AAAA_DATA
        {
            // IP6_ADDRESS Ip6Address;
            // DWORD IP6Dword[4];
            // This isn't ideal, but it should work without using the fixed and unsafe keywords
            public uint Ip6Address0;
            public uint Ip6Address1;
            public uint Ip6Address2;
            public uint Ip6Address3;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682061(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_KEY_DATA
        {
            public ushort wFlags;
            public byte chProtocol;
            public byte chAlgorithm;
            public IntPtr Key;        // BYTE Key[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682094(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_SIG_DATA
        {
            public IntPtr pNameSigner;      // string
            public ushort wTypeCovered;
            public byte chAlgorithm;
            public byte chLabelCount;
            public uint dwOriginalTtl;
            public uint dwExpiration;
            public uint dwTimeSigned;
            public ushort wKeyTag;
            public ushort Pad;
            public IntPtr Signature;      // BYTE  Signature[1];
        }

        public const int DNS_ATMA_MAX_ADDR_LENGTH = 20;
        public const int DNS_ATMA_FORMAT_E164 = 1;
        public const int DNS_ATMA_FORMAT_AESA = 2;

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682041(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_ATMA_DATA
        {
            public byte AddressType;
            // BYTE Address[DNS_ATMA_MAX_ADDR_LENGTH];
            // This isn't ideal, but it should work without using the fixed and unsafe keywords
            public byte Address0;
            public byte Address1;
            public byte Address2;
            public byte Address3;
            public byte Address4;
            public byte Address5;
            public byte Address6;
            public byte Address7;
            public byte Address8;
            public byte Address9;
            public byte Address10;
            public byte Address11;
            public byte Address12;
            public byte Address13;
            public byte Address14;
            public byte Address15;
            public byte Address16;
            public byte Address17;
            public byte Address18;
            public byte Address19;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682076(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_NXT_DATA
        {
            public IntPtr pNameNext;    // string
            public ushort wNumTypes;
            public IntPtr wTypes;       // WORD  wTypes[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682097(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_SRV_DATA
        {
            public IntPtr pNameTarget;      // string
            public ushort uPriority;
            public ushort wWeight;
            public ushort wPort;
            public ushort Pad;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/cc982164(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_NAPTR_DATA
        {
            public ushort wOrder;
            public ushort wPreference;
            public IntPtr pFlags;       // string
            public IntPtr pService;     // string
            public IntPtr pRegularExpression;       // string
            public IntPtr pReplacement;     // string
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/dd392298(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_OPT_DATA
        {
            public ushort wDataLength;
            public ushort wPad;
            public IntPtr Data;           // BYTE Data[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/dd392296(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_DS_DATA
        {
            public ushort wKeyTag;
            public byte chAlgorithm;
            public byte chDigestType;
            public ushort wDigestLength;
            public ushort wPad;
            public IntPtr Digest;         // BYTE Digest[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/dd392301(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_RRSIG_DATA
        {
            public IntPtr pNameSigner;      // string
            public ushort wTypeCovered;
            public byte chAlgorithm;
            public byte chLabelCount;
            public uint dwOriginalTtl;
            public uint dwExpiration;
            public uint dwTimeSigned;
            public ushort wKeyTag;
            public ushort Pad;
            public IntPtr Signature;      // BYTE  Signature[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/dd392297(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_NSEC_DATA
        {
            public IntPtr pNextDomainName;    // string
            public ushort wTypeBitMapsLength;
            public ushort wPad;
            public IntPtr TypeBitMaps;    // BYTE  TypeBitMaps[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/dd392295(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_DNSKEY_DATA
        {
            public ushort wFlags;
            public byte chProtocol;
            public byte chAlgorithm;
            public ushort wKeyLength;
            public ushort wPad;
            public IntPtr Key;        // BYTE Key[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682104(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_TKEY_DATA
        {
            public IntPtr pNameAlgorithm;   // string
            public IntPtr pAlgorithmPacket; // PBYTE (which is BYTE*)
            public IntPtr pKey;         // PBYTE (which is BYTE*)
            public IntPtr pOtherData;       // PBYTE (which is BYTE*)
            public uint dwCreateTime;
            public uint dwExpireTime;
            public ushort wMode;
            public ushort wError;
            public ushort wKeyLength;
            public ushort wOtherLength;
            public byte cAlgNameLength;     // UCHAR cAlgNameLength;
            public int bPacketPointers;     // BOOL  bPacketPointers;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682106(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_TSIG_DATA
        {
            public IntPtr pNameAlgorithm;   // string
            public IntPtr pAlgorithmPacket; // PBYTE (which is BYTE*)
            public IntPtr pSignature;       // PBYTE (which is BYTE*)
            public IntPtr pOtherData;       // PBYTE (which is BYTE*)
            public long i64CreateTime;
            public ushort wFudgeTime;
            public ushort wOriginalXid;
            public ushort wError;
            public ushort wSigLength;
            public ushort wOtherLength;
            public byte cAlgNameLength;     // UCHAR    cAlgNameLength;
            public int bPacketPointers;     // BOOL     bPacketPointers;
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682114(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_WINS_DATA
        {
            public uint dwMappingFlag;
            public uint dwLookupTimeout;
            public uint dwCacheTimeout;
            public uint cWinsServerCount;
            public uint WinsServers;    // IP4_ADDRESS WinsServers[1];
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/ms682113(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_WINSR_DATA
        {
            public uint dwMappingFlag;
            public uint dwLookupTimeout;
            public uint dwCacheTimeout;
            public IntPtr pNameResultDomain;    // string
        }

        /// <summary>
        /// See http://msdn.microsoft.com/en-us/library/windows/desktop/dd392294(v=vs.85).aspx
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct DNS_DHCID_DATA
        {
            public uint dwByteCount;
            public IntPtr DHCID;          // BYTE  DHCID[1];
        }
    }
}
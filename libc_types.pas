unit libc_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  Tint8_t = Integer;
  Tint16_t = Integer;
  Tint32_t = Integer;
  Tint64_t = LongInt;
  Tuint8_t = Cardinal;
  Tuint16_t = Cardinal;
  Tuint32_t = Cardinal;
  Tuint64_t = Cardinal;
  Tuintptr_t = Cardinal;
  Tintptr_t = LongInt;
  TFILE = record
    (* empty struct *)
  end;
  PFILE = ^TFILE;
  Tsize_t = Cardinal;
  Ttime_t = LongInt;
  Twchar_t = Integer;
  Twint_t = Cardinal;
  TDWORD = Cardinal;
  TWORD = Word;
  TBYTE = Byte;
  TBOOL = Integer;
  THANDLE = Pointer;
  THMODULE = Pointer;
  THINSTANCE = Pointer;
  THDC = Pointer;
  THWND = Pointer;
  TPVOID = Pointer;
  TLPVOID = Pointer;
  TLPSTR = PChar;
  TLPCSTR = PChar;
  TPCSTR = PChar;
  TPCWSTR = ^Twchar_t;
  TPWSTR = ^Twchar_t;
  TPCTSTR = PChar;
  TLPCTSTR = PChar;
  THDEVINFO = Pointer;
  TPSP_DEVICE_INTERFACE_DETAIL_DATA_A = Pointer;
  TPSP_DEVICE_INTERFACE_DETAIL_DATA_W = Pointer;
  TPSP_DEVICE_INTERFACE_DETAIL_DATA = Pointer;
  TPDWORD = ^Cardinal;
  THKEY = Integer;
  TPHKEY = Pointer;
  TINT = Integer;
  TUINT = Cardinal;
  TLONG = LongInt;
  TULONG = Cardinal;
  TSHORT = SmallInt;
  TUSHORT = Word;
  TWCHAR = Integer;
  TLPWSTR = ^Twchar_t;
  TLPCWSTR = ^Twchar_t;
  Tu_long = Cardinal;
  Tu_short = Word;
  Tu_int = Cardinal;
  Tu_char = Byte;
  TLARGE_INTEGER = LongInt;
  TULARGE_INTEGER = LongInt;
  TBOOLEAN = Integer;
  TPULONG = ^Cardinal;
  TPWORD = ^Word;
  TPBYTE = PByte;
  TPLONG = ^LongInt;
  TPSHORT = ^SmallInt;
  TPINT = ^Integer;
  TPUINT = ^Cardinal;
  TGUID = record
    Data1: Cardinal;
    Data2: Word;
    Data3: Word;
    Data4: array[0..8-1] of Byte;
  end;
  PGUID = ^TGUID;
  TLPGUID = ^T_GUID;
  TREFGUID = ^T_GUID;
  TLPCGUID = PGUID;
  TOVERLAPPED = record
    Internal: TDWORD;
    InternalHigh: TDWORD;
  end;
  POVERLAPPED = ^TOVERLAPPED;
  TLPOVERLAPPED = ^T_OVERLAPPED;
  TLPSECURITY_ATTRIBUTES = record
    nLength: TDWORD;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: TBOOL;
  end;
  PLPSECURITY_ATTRIBUTES = ^TLPSECURITY_ATTRIBUTES;
  TPSECURITY_ATTRIBUTES = ^T_SECURITY_ATTRIBUTES;
  TPHDEVINFO = ^T_HDEVINFO;
  TSP_DEVICE_INTERFACE_DATA = record
    cbSize: TDWORD;
    InterfaceClassGuid: TGUID;
    Flags: TDWORD;
    Reserved: TULONG;
  end;
  PSP_DEVICE_INTERFACE_DATA = ^TSP_DEVICE_INTERFACE_DATA;
  TPSP_DEVICE_INTERFACE_DATA = ^T_SP_DEVICE_INTERFACE_DATA;
  TSP_DEVINFO_DATA = record
    cbSize: TDWORD;
    ClassGuid: TGUID;
    DevInst: TDWORD;
    Reserved: TULONG;
  end;
  PSP_DEVINFO_DATA = ^TSP_DEVINFO_DATA;
  TPSP_DEVINFO_DATA = ^T_SP_DEVINFO_DATA;
  TSP_DEVICE_INTERFACE_DETAIL_DATA_A = record
    cbSize: TDWORD;
    DevicePath: array[0..1-1] of Char;
  end;
  PSP_DEVICE_INTERFACE_DETAIL_DATA_A = ^TSP_DEVICE_INTERFACE_DETAIL_DATA_A;
  TSP_DEVICE_INTERFACE_DETAIL_DATA = TSP_DEVICE_INTERFACE_DETAIL_DATA_A;
  THIDD_ATTRIBUTES = record
    Size: TULONG;
    VendorID: TUSHORT;
    ProductID: TUSHORT;
    VersionNumber: TUSHORT;
  end;
  PHIDD_ATTRIBUTES = ^THIDD_ATTRIBUTES;
  TPHIDD_ATTRIBUTES = ^T_HIDD_ATTRIBUTES;
  TSOCKET = Integer;
  Tfd_set = record
    fd_count: Cardinal;
    fd_array: array[0..64-1] of Integer;
  end;
  PTfd_set = ^Tfd_set;
  TWSABUF = record
    len: Cardinal;
    buf: PChar;
  end;
  PWSABUF = ^TWSABUF;
  TLPWSABUF = ^T_WSABUF;
  TWSADATA = record
    wVersion: TWORD;
    wHighVersion: TWORD;
    szDescription: array[0..257-1] of Char;
    szSystemStatus: array[0..129-1] of Char;
    iMaxSockets: Word;
    iMaxUdpDg: Word;
    lpVendorInfo: PChar;
  end;
  PWSADATA = ^TWSADATA;

var
  isdigit: TProcedure;
  isalpha: TProcedure;
  isalnum: TProcedure;
  isspace: TProcedure;
  isupper: TProcedure;
  islower: TProcedure;
  tolower: TProcedure;
  toupper: TProcedure;
  errno: Integer;
  open: TProcedure;
  getopt_long: TProcedure;
  getopt: TProcedure;
  sqrt: TProcedure;
  pow: TProcedure;
  floor: TProcedure;
  ceil: TProcedure;
  round: TProcedure;
  printf: TProcedure;
  fprintf: TProcedure;
  sprintf: TProcedure;
  snprintf: TProcedure;
  fopen: TProcedure;
  fclose: TProcedure;
  fread: TProcedure;
  fwrite: TProcedure;
  fseek: TProcedure;
  ftell: TProcedure;
  feof: TProcedure;
  fgets: TProcedure;
  fputs: TProcedure;
  fgetc: TProcedure;
  fputc: TProcedure;
  malloc: TProcedure;
  calloc: TProcedure;
  realloc: TProcedure;
  free: TProcedure;
  exit: TProcedure;
  atoi: TProcedure;
  strtol: TProcedure;
  atof: TProcedure;
  strcpy: TProcedure;
  strncpy: TProcedure;
  strcat: TProcedure;
  strncat: TProcedure;
  strcmp: TProcedure;
  strncmp: TProcedure;
  strcasecmp: TProcedure;
  strncasecmp: TProcedure;
  strlen: TProcedure;
  strchr: TProcedure;
  strrchr: TProcedure;
  strstr: TProcedure;
  strdup: TProcedure;
  memcpy: TProcedure;
  memmove: TProcedure;
  memset: TProcedure;
  memcmp: TProcedure;
  time: TProcedure;
  localtime: TProcedure;
  clock_gettime: TProcedure;
  gettimeofday: TProcedure;
  close: TProcedure;
  read: TProcedure;
  write: TProcedure;
  access: TProcedure;
  unlink: TProcedure;
  sleep: TProcedure;
  usleep: TProcedure;
  QueryPerformanceCounter: TProcedure;
  QueryPerformanceFrequency: TProcedure;
  GetLastError: TProcedure;
  CreateFile: TProcedure;
  ReadFile: TProcedure;
  WriteFile: TProcedure;
  CloseHandle: TProcedure;
  CreateEvent: TProcedure;
  Sleep: TProcedure;
  LoadLibrary: TProcedure;
  GetProcAddress: TProcedure;
  FreeLibrary: TProcedure;
  atexit: TProcedure;

// --- function declarations ---
  function timeBeginPeriod: Integer;
  function timeEndPeriod: Integer;
  function timeGetTime: Cardinal;
  function WSAStartup: Integer;
  function WSACleanup: Integer;
  function WSAGetLastError: Integer;
  function ioctlsocket: Integer;
  function closesocket: Integer;
  function socket: TSOCKET;
  function bind: Integer;
  function listen: Integer;
  function accept: TSOCKET;
  function connect: Integer;
  function getsockname: Integer;
  function getpeername: Integer;
  function setsockopt: Integer;
  function getsockopt: Integer;
  function send: Integer;
  function recv: Integer;
  function sendto: Integer;
  function recvfrom: Integer;
  function shutdown: Integer;
  function gethostbyname: T^Thostent;
  function gethostbyaddr: T^Thostent;
  function inet_addr: Cardinal;
  function inet_ntoa: PChar;
  function htons: Word;
  function ntohs: Word;
  function htonl: Cardinal;
  function ntohl: Cardinal;
  function select: Integer;
  function WSASendTo: Integer;
  function WSARecvFrom: Integer;

implementation

end.

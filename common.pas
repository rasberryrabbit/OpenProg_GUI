unit common;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls,
  ComCtrls,
  ExtCtrls,
  Buttons,
  Spin,
  Menus,
  LCLType,
  strings,
  instructions;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

const
  _APPNAME = 'OPGUI';
  COL = 16;
  VERSION = 'unknown';
  G = (12.0/34*1024/5);
  LOCK = 1;
  FUSE = 2;
  FUSE_H = 4;
  FUSE_X = 8;
  CAL = 16;
  SLOW = 256;
  SYSNAME = 'Linux';
  DIMBUF = 64;

type
  TDWORD = DWORD;
  TWORD = Word;
  TBYTE = Byte;

var
  bufferU: array[0..128-1] of Byte;
  bufferI: array[0..128-1] of Byte;
  bufferU0: array[0..128-1] of Byte;
  bufferI0: array[0..128-1] of Byte;
  NumberOfBytesRead: DWORD;
  BytesWritten: DWORD;
  Result: DWORD;
  WriteHandle: THandle;
  ReadHandle: THandle;
  HIDOverlapped: TOVERLAPPED;
  hEventObject: THandle;
  statusID: Integer;
  status_bar: TControl;
  str: array[0..4096-1] of Char;
  saveLog: Integer;
  strings: PChar;
  fd: Integer;
  programID: Integer;
  MinDly: Integer;
  load_osccal: Integer;
  load_BKosccal: Integer;
  use_osccal: Integer;
  use_BKosccal: Integer;
  load_calibword: Integer;
  max_err: Integer;
  AVRlock: Integer;
  AVRfuse: Integer;
  AVRfuse_h: Integer;
  AVRfuse_x: Integer;
  ICDenable: Integer;
  ICDaddr: Integer;
  FWVersion: Integer;
  HwID: Integer;
  logfile: ^TextFile;
  LogFileName: array[0..512-1] of Char;
  loadfile: array[0..512-1] of Char;
  savefile: array[0..512-1] of Char;
  memCODE_W: Word;
  size: Integer;
  sizeW: Integer;
  sizeEE: Integer;
  sizeCONFIG: Integer;
  sizeUSERID: Integer;
  memCODE: Byte;
  memEE: Byte;
  memID: array[0..512-1] of Byte;
  memCONFIG: array[0..48-1] of Byte;
  memUSERID: array[0..8-1] of Byte;
  hvreg: Double;
  RWstop: Integer;
  useSAFLOCK_flag: Integer;

// --- function declarations ---
function StartHVReg(V: Double): Integer;
procedure msDelay(delay: Double);
procedure DisplayEE;
procedure PrintMessage(msg: PChar);
procedure PrintMessageI2C(msg: PChar);
function CheckV33Regulator: Integer;
procedure OpenLogFile;
procedure WriteLogIO;
procedure CloseLogFile;
function htoi(hex: PChar; length: Integer): Cardinal;
procedure PacketIO(delay: Double);

implementation

end.

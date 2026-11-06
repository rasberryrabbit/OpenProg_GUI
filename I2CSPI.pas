unit i2cspi;

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
  common,
  glib_types,
  gtk_types,
  libc_types,
  sys_types,
  mainform;

const
  NL = #10;
  CS = 8;
  HLD = 16;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

type
  TDWORD = Cardinal;
  TWORD = Word;
  TBYTE = Byte;

var
  strings_it: array[0..DIM-1] of PChar;
  strings_en: array[0..DIM-1] of PChar;
  STR_ID: array[0..DIM-1] of PChar;
  bufferU0: array[0..128-1] of Byte;
  bufferI0: array[0..128-1] of Byte;
  bufferU: PByte;
  bufferI: PByte;
  NumberOfBytesRead: TDWORD;
  BytesWritten: TDWORD;
  Result_: TULONG;
  WriteHandle: THANDLE;
  ReadHandle: THANDLE;
  HIDOverlapped: TOVERLAPPED;
  hEventObject: THANDLE;
  statusID: Integer;
  status_bar: PControl;
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
  memCODE_W: PWORD;
  size: Integer;
  sizeW: Integer;
  sizeEE: Integer;
  sizeCONFIG: Integer;
  sizeUSERID: Integer;
  memCODE: PByte;
  memEE: PByte;
  memID: array[0..512-1] of Byte;
  memCONFIG: array[0..48-1] of Byte;
  memUSERID: array[0..8-1] of Byte;
  hvreg: Double;
  RWstop: Integer;
  useSAFLOCK_flag: Integer;

// --- function declarations ---
procedure strinit;
function strfind(langid: PChar; langfile: PChar): Integer;
function GenerateLangFile(langid: PChar; langfile: PChar): Pointer;
function StartHVReg(V: Double): Integer;
function msDelay(delay: Double): Pointer;
procedure DisplayEE;
function PrintMessage(msg: PChar): Pointer;
function PrintMessageI2C(msg: PChar): Pointer;
function CheckV33Regulator: Integer;
procedure OpenLogFile;
procedure WriteLogIO;
procedure CloseLogFile;
function htoi(hex: PChar; length: Integer): Cardinal;
function PacketIO(delay: Double): Pointer;
function I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: PBYTE): Pointer;
function I2CSend(mode: Integer; speed: Integer; N: Integer; buffer: PBYTE): Pointer;

implementation

function I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: PBYTE): Pointer;
var
  j: Integer;
  str: array[0..1024-1] of Char;
  t: array[0..16-1] of Char;
  i: Integer;
begin
  j := 0;
  if N < 0 then
   N := 0;
  if N > 60 then
   N := 60;
  if mode < 0 then
   mode := 0;
  if mode > 5 then
   mode := 5;
  if speed < 0 then
   speed := 0;
  if speed > 3 then
   speed := 3;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'I2C-SPI receive' + #9 + 'mode=%d' + #9 + 'speed=%d' + NL + '', mode, speed);
  end;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  if mode < 2 then
  begin
   bufferU[j] := $2B;
   Inc(j);
   bufferU[j] := (speed shl 3) + IfThen(speed > 0, $40, 0);
   Inc(j);
  end
  else
  begin
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $2F;
   Inc(j);
   bufferU[j] := speed + ((mode - 2) shl 2);
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  if mode = 0 then
  begin
   bufferU[j] := $2C;
   Inc(j);
   bufferU[j] := IfThen(N > 64 - 4, 64 - 4, N);
   Inc(j);
   bufferU[j] := buffer[0];
   Inc(j);
   bufferU[j] := buffer[1];
   Inc(j);
  end
  else
   if mode = 1 then
   begin
    bufferU[j] := $2E;
    Inc(j);
    bufferU[j] := IfThen(N > 64 - 4, 64 - 4, N);
    Inc(j);
    bufferU[j] := buffer[0];
    Inc(j);
    bufferU[j] := buffer[1];
    Inc(j);
    bufferU[j] := buffer[2];
    Inc(j);
   end
   else
    if mode >= 2 then
    begin
     bufferU[j] := $30;
     Inc(j);
     bufferU[j] := IfThen(N > 64 - 5, 64 - 5, N);
     Inc(j);
     bufferU[j] := $32;
     Inc(j);
     bufferU[j] := 8;
     Inc(j);
     bufferU[j] := 0;
     Inc(j);
    end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(10);
  if saveLog then
  begin
   CloseLogFile();
  end;
  if (bufferI[0] = $2C) or (bufferI[0] = $2E) or (bufferI[0] = $30) then
  begin
   if bufferI[1] = $FD then
   begin
    printf(strings[S_I2CAckErr]);
   end
   else
    if bufferI[1] > $FA then
    begin
     printf(strings[S_InsErr]);
    end
    else
    begin
     str := '';
     t := '';
     if mode = 0 then
      sprintf(str, '> %02X %02X' + #13 + '' + NL + '', bufferU[2], bufferU[3])
     else
      if mode = 1 then
       sprintf(str, '> %02X %02X' + #13 + '' + NL + '', bufferU[2], bufferU[3]);
     strcat(str, '< ');
     for i := 0 to (bufferI[1]) - 1 do
     begin
      sprintf(t, '%02X ', bufferI[i + 2]);
      strcat(str, t);
      if i and (i mod 16 = 15) then
      begin
       strcat(str, '' + #13 + '' + NL + '');
      end;
     end;
     strcat(str, '' + #13 + '' + NL + '');
     printf(str);
     fflush(stdout);
    end;
  end
  else
  begin
   printf(strings[S_ComErr]);
  end;
end;

function I2CSend(mode: Integer; speed: Integer; N: Integer; buffer: PBYTE): Pointer;
var
  i: Integer;
  j: Integer;
  str: array[0..1024-1] of Char;
  t: array[0..16-1] of Char;
  n: Integer;
begin
  j := 0;
  if N < 0 then
   N := 0;
  if N > 57 then
   N := 57;
  if mode < 0 then
   mode := 0;
  if mode > 5 then
   mode := 5;
  if speed < 0 then
   speed := 0;
  if speed > 3 then
   speed := 3;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'I2C-SPI send' + #9 + 'mode=%d' + #9 + 'speed=%d' + NL + '', mode, speed);
  end;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  if mode < 2 then
  begin
   bufferU[j] := $2B;
   Inc(j);
   bufferU[j] := (speed shl 3) + IfThen(speed > 0, $40, 0);
   Inc(j);
  end
  else
  begin
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $2F;
   Inc(j);
   bufferU[j] := speed + ((mode - 2) shl 2);
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  if mode = 0 then
  begin
   bufferU[j] := $2D;
   Inc(j);
   bufferU[j] := IfThen(N > 64 - 5, 64 - 5, N);
   Inc(j);
   bufferU[j] := buffer[0];
   Inc(j);
   bufferU[j] := buffer[1];
   Inc(j);
   for i := 0 to (bufferU[1]) - 1 do
   begin
    bufferU[j] := buffer[i + 2];
    Inc(j);
   end;
  end
  else
   if mode = 1 then
   begin
    bufferU[j] := $2D;
    Inc(j);
    bufferU[j] := IfThen(N + 1 > 64 - 5, 64 - 5, N + 1);
    Inc(j);
    bufferU[j] := buffer[0];
    Inc(j);
    bufferU[j] := buffer[1];
    Inc(j);
    bufferU[j] := buffer[2];
    Inc(j);
    for i := 0 to (bufferU[1] - 1) - 1 do
    begin
     bufferU[j] := buffer[i + 3];
     Inc(j);
    end;
   end;
  if mode >= 2 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := IfThen(N > 64 - 5, 64 - 5, N);
   Inc(j);
   for i := 0 to (bufferU[1]) - 1 do
   begin
    bufferU[j] := buffer[i];
    Inc(j);
   end;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(20);
  if saveLog then
  begin
   CloseLogFile();
  end;
  if (bufferI[0] = $2D) or (bufferI[0] = $31) then
  begin
   if bufferI[1] = $FD then
   begin
    printf(strings[S_I2CAckErr]);
   end
   else
    if bufferI[1] > $FA then
    begin
     printf(strings[S_InsErr]);
    end
    else
    begin
     n := 2;
     sprintf(str, '> ');
     if mode < 2 then
      n := 4;
     for i := 0 to (bufferU[1]) - 1 do
     begin
      sprintf(t, '%02X ', bufferU[i + n]);
      strcat(str, t);
      if i and (i mod 16 = 15) then
      begin
       strcat(str, '' + #13 + '' + NL + '');
      end;
     end;
     strcat(str, '' + #13 + '' + NL + '');
     printf(str);
    end;
  end
  else
  begin
   printf(strings[S_ComErr]);
  end;
end;

end.

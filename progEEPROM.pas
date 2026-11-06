unit progeeprom;

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
  PRE = $08;
  S = $10;
  W = $20;
  ORG = $20;
  CS = 8;
  HLD = 16;
  WP = $40;
  READ_ROM = $33;
  MATCH_ROM = $55;
  SKIP_ROM = $CC;
  SEARCH_ROM = $F0;
  WRITE_SCRATCHPAD = $0F;
  READ_SCRATCHPAD = $AA;
  COPY_SCRATCHPAD = $55;
  READ_MEMORY = $F0;
  WRITE_APP_REGISTER = $99;
  READ_STAT_REGISTER = $66;
  READ_APP_REGISTER = $C3;
  COPY_LOCK_APP_REGISTER = $5A;
  READ_SCRATCHPAD2 = $BE;
  CONVERT_TEMP = $44;
  RECALL_EE = $B8;
  READ_PWSUP = $B4;
  UNIO_READ = $03;
  UNIO_CRRD = $06;
  UNIO_WRITE = $6C;
  UNIO_WREN = $96;
  UNIO_WRDI = $91;
  UNIO_RDSR = $05;
  UNIO_WRSR = $6E;
  UNIO_ERAL = $6D;
  UNIO_SETAL = $67;

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
  OW_LIST: array of TID_OW;

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
function ReadI2C(dim: Integer; addr: Integer): Pointer;
function WriteI2C(dim: Integer; addr: Integer; page: Integer): Pointer;
function Read93x(dim: Integer; na: Integer; options: Integer): Pointer;
function Write93Sx(dim: Integer; na: Integer; page: Integer): Pointer;
function Write93Cx(dim: Integer; na: Integer; options: Integer): Pointer;
function Read25xx(dim: Integer): Pointer;
function Write25xx(dim: Integer; options: Integer): Pointer;
function OW_ID(id: Integer): Pointer;
function ReadOneWireMem(dim: Integer; options: Integer): Pointer;
function WriteOneWireMem(dim: Integer; options: Integer): Pointer;
procedure ReadDS1820;
function Read11xx(dim: Integer): Pointer;
function Write11xx(dim: Integer; page: Integer): Pointer;

implementation

function ReadI2C(dim: Integer; addr: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  AX: Integer;
  addr17: Integer;
  start: Cardinal;
  inc: Integer;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  AX := (addr shr 4) and 7;
  addr17 := (addr shr 8) and $F;
  addr := addr and 1;
  if (dim > $30000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'ReadI2C(%d,%d)    (0x%X,0x%X)' + NL + '', dim, addr, dim, addr);
  end;
  sizeEE := dim;
  if memEE then
   free(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  hvreg := 0;
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $2B;
  Inc(j);
  bufferU[j] := AX;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  PrintMessage(strings[S_ReadEE]);
  j := 0;
  i := 0;
  while i < dim do
  begin
   if (i < $10000) and (i > $10000 - 64 - 4) then
    inc := $10000 - i
   else
    inc := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   if not (addr) then
   begin
    bufferU[j] := $2C;
    Inc(j);
    bufferU[j] := inc;
    Inc(j);
    bufferU[j] := $A0 + (i shr 7) and $0E;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end
   else
   begin
    bufferU[j] := $2E;
    Inc(j);
    bufferU[j] := inc;
    Inc(j);
    bufferU[j] := $A0 + IfThen(i > $FFFF, addr17, 0);
    Inc(j);
    bufferU[j] := (i shr 8) and $FF;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(8);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $2C) and (bufferI[j] <> $2E) do
   begin
    Inc(j);
   end;
   if (j < 64 - 1) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     memEE[k] := bufferI[z];
     Inc(k);
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   Inc(i, inc);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
   sum := sum + memEE[i];
  end;
  sprintf(str, 'Checksum: 0x%X' + #13 + '' + NL + '', sum and $FFFF);
  PrintMessage(str);
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function WriteI2C(dim: Integer; addr: Integer; page: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  AX: Integer;
  addr17: Integer;
  start: Cardinal;
  ack: Integer;
  inc: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  AX := (addr shr 4) and 7;
  addr17 := (addr shr 8) and $F;
  addr := addr and 1;
  hvreg := 0;
  if (dim > $30000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'WriteI2C(%d,%d,%d)    (0x%X,0x%X)' + NL + '', dim, addr, page, dim, addr);
  end;
  if dim > sizeEE then
  begin
   i := sizeEE;
   memEE := realloc(memEE, dim);
   while i < dim do
   begin
    memEE[i] := $FF;
    Inc(i);
   end;
   sizeEE := dim;
  end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $2B;
  Inc(j);
  bufferU[j] := AX;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  PrintMessage(strings[S_EEAreaW]);
  while page >= 64 - 6 do
  begin
   page := page shr 1;
  end;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $2D;
   Inc(j);
   if not (addr) then
   begin
    bufferU[j] := page;
    Inc(j);
    bufferU[j] := $A0 + (i shr 7) and $0E;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end
   else
   begin
    bufferU[j] := page + 1;
    Inc(j);
    bufferU[j] := $A0 + IfThen(i > $FFFF, addr17, 0);
    Inc(j);
    bufferU[j] := (i shr 8) and $FF;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end;
   for k := 0 to (page) - 1 do
   begin
    bufferU[j] := memEE[i + k];
    Inc(j);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $2D) do
   begin
    Inc(j);
   end;
   if (bufferI[j] <> $2D) or (bufferI[j + 1] >= $FA) then
    i := dim + 10;
   sprintf(str, strings[S_CodeWriting2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   bufferU[j] := $2D;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   ack := $FD;
   j := 0;
   while (ack = $FD) and (j < 20) do
   begin
    PacketIO(2);
    j := 0;
    while (j < 64 - 1) and (bufferI[j] <> $2D) do
    begin
     Inc(j);
    end;
    if (bufferI[j] <> $2D) or (bufferI[j + 1] >= $FA) then
     ack := $FD
    else
     ack := bufferI[j + 1];
    Inc(j);
   end;
   j := 0;
   Inc(i, page);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  k := 0;
  j := 0;
  i := 0;
  while i < dim do
  begin
   if (i < $10000) and (i > $10000 - 64 - 4) then
    inc := $10000 - i
   else
    inc := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   if not (addr) then
   begin
    bufferU[j] := $2C;
    Inc(j);
    bufferU[j] := inc;
    Inc(j);
    bufferU[j] := $A0 + (i shr 7) and $0E;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end
   else
   begin
    bufferU[j] := $2E;
    Inc(j);
    bufferU[j] := inc;
    Inc(j);
    bufferU[j] := $A0 + IfThen(i > $FFFF, addr17, 0);
    Inc(j);
    bufferU[j] := (i shr 8) and $FF;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(8);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $2C) and (bufferI[j] <> $2E) do
   begin
    Inc(j);
   end;
   if ((bufferI[j] = $2C) or (bufferI[j] = $2E)) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     if memEE[k] <> bufferI[z] then
     Inc(k);
     begin
      PrintMessage('' + #13 + '' + NL + '');
      sprintf(str, strings[S_CodeVError], (i + z) - 3, (i + z) - 3, memEE[k - 1], bufferI[z]);
      PrintMessage(str);
      Inc(err);
     end;
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, inc);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Read93x(dim: Integer; na: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  x8: Integer;
  start: Cardinal;
  dim2: Integer;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if (dim > $3000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if na > 13 then
   na := 13;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read93x(%d,%d,%d)    (0x%X,0x%X)' + NL + '', dim, na, options, dim, na);
  end;
  x8 := options and 1;
  sizeEE := dim;
  if memEE then
   free(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(x8, $10, $10 + $20);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  PrintMessage(strings[S_ReadEE]);
  dim2 := IfThen(x8, dim, dim div 2);
  i := 0;
  while i < dim2 do
  begin
   j := 0;
   while (j < 64 - 14) and (i < dim2) do
   begin
    bufferU[j] := $3C;
    Inc(j);
    bufferU[j] := na + 3;
    Inc(j);
    bufferU[j] := $C0 + (i shr (na - 5)) and $1F;
    Inc(j);
    bufferU[j] := (i shl (13 - na)) and $FF;
    Inc(j);
    bufferU[j] := $3D;
    Inc(j);
    bufferU[j] := IfThen(x8, 8, 16);
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(x8, 0, $20);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(x8, $10, $10 + $20);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    Inc(i);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   for z := 0 to (64 - 3) - 1 do
   begin
    while (bufferI[z] <> $3D) and (z < 64 - 3) do
    begin
     Inc(z);
    end;
    if bufferI[z] = $3D then
    begin
     if x8 then
      memEE[k] := bufferI[z + 2];
      Inc(k)
     else
     begin
      memEE[k + 1] := bufferI[z + 2];
      memEE[k] := bufferI[z + 3];
      k := k + 2;
     end;
     z := z + 3;
    end;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim2, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
   sum := sum + memEE[i];
  end;
  sprintf(str, 'Checksum: 0x%X' + #13 + '' + NL + '', sum and $FFFF);
  PrintMessage(str);
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write93Sx(dim: Integer; na: Integer; page: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  start: Cardinal;
  addr: Integer;
  n: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  if (dim > $1000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if na > 13 then
   na := 13;
  if page > 48 then
   page := 48;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write93Sx(%d,%d,%d)    (0x%X,0x%X)' + NL + '', dim, na, page, dim, na);
  end;
  if dim > sizeEE then
  begin
   i := sizeEE;
   memEE := realloc(memEE, dim);
   while i < dim do
   begin
    memEE[i] := $FF;
    Inc(i);
   end;
   sizeEE := dim;
  end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $10 + $20;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $98;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $10 + $20 + $08;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $98;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $20 + $08;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $10 + $20 + $08;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $20 + $08;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $10 + $20;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $98;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $10 + $20 + $08;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $C0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3D;
  Inc(j);
  bufferU[j] := 10;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $20 + $08;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  PrintMessage(strings[S_EEAreaW]);
  addr := 0;
  i := 0;
  j := 0;
  while i < dim do
  begin
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := $10 + $20;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $3C;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $E0;
   Inc(j);
   bufferU[j] := $3C;
   Inc(j);
   bufferU[j] := na;
   Inc(j);
   bufferU[j] := addr shr 8;
   Inc(j);
   if na > 8 then
    bufferU[j] := addr and $FF;
    Inc(j);
   bufferU[j] := $3C;
   Inc(j);
   bufferU[j] := 8 * page;
   Inc(j);
   k := 0;
   while k < page do
   begin
    bufferU[j] := memEE[i + k + 1];
    Inc(j);
    bufferU[j] := memEE[i + k];
    Inc(j);
    Inc(k, 2);
   end;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := $10 + $20;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $3C) do
   begin
    Inc(j);
   end;
   if (bufferI[j] <> $3C) or (bufferI[j + 1] >= $FA) then
    i := dim + 10;
   bufferU[j] := $3D;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   z := 0;
   k := 0;
   while (z < 30) and not (k) do
   begin
    PacketIO(2);
    j := 0;
    while (j < 64 - 1) and (bufferI[j] <> $3D) do
    begin
     Inc(j);
    end;
    if bufferI[j] = $3D then
     k := bufferI[j + 2];
    Inc(z);
   end;
   j := 0;
   sprintf(str, strings[S_CodeWriting2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   Inc(i, page);
   Inc(addr, (($10000 shr na) * page) div 2);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  j := 0;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $10;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $C0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  k := 0;
  n := 64 - 2;
  if n > 30 then
   n := 30;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $3D;
   Inc(j);
   bufferU[j] := IfThen(i < dim - n, n * 8, (dim - i) * 8);
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   while (bufferI[j] <> $3D) and (j < 64 - 1) do
   begin
    Inc(j);
   end;
   if bufferI[j] = $3D then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1] div 8) and (z < 64) do
    begin
     if memEE[k + 1] <> bufferI[z] then
     begin
      PrintMessage('' + #13 + '' + NL + '');
      sprintf(str, strings[S_CodeVError], (i + z) - 3, (i + z) - 3, memEE[k + 1], bufferI[z]);
      PrintMessage(str);
      Inc(err);
     end;
     if memEE[k] <> bufferI[z + 1] then
     begin
      PrintMessage('' + #13 + '' + NL + '');
      sprintf(str, strings[S_CodeVError], (i + z) - 3, (i + z) - 3, memEE[k], bufferI[z + 1]);
      PrintMessage(str);
      Inc(err);
     end;
     Inc(z, 2);
     Inc(k, 2);
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, n);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write93Cx(dim: Integer; na: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  start: Cardinal;
  addr: Integer;
  dim2: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  if (dim > $1000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if na > 13 then
   na := 13;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write93Cx(%d,%d,%d)    (0x%X,0x%X)' + NL + '', dim, na, options, dim, na);
  end;
  if dim > sizeEE then
  begin
   i := sizeEE;
   memEE := realloc(memEE, dim);
   while i < dim do
   begin
    memEE[i] := $FF;
    Inc(i);
   end;
   sizeEE := dim;
  end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $10 + $20 + $08, $10 + $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $98;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $20 + $08, $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $10 + $20 + $08, $10 + $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := na + 3;
  Inc(j);
  bufferU[j] := $90;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $20 + $08, $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $10 + $20 + $08, $10 + $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $3D;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  bufferU[j] := $3D;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  i := 0;
  k := 0;
  while (i < 30) and not (k) do
  begin
   PacketIO(2);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $3D) do
   begin
    Inc(j);
   end;
   if bufferI[j] = $3D then
    k := bufferI[j + 2];
   Inc(i);
  end;
  PrintMessage(strings[S_EEAreaW]);
  addr := 0;
  j := 0;
  i := 0;
  while i < dim do
  begin
   if (memEE[i] < $FF) or (options = 0) and (memEE[i + 1] < $FF) then
   begin
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(options = 0, $20 + $08, $08);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(options = 0, $10 + $20 + $08, $10 + $08);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $3C;
    Inc(j);
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
    bufferU[j] := $3C;
    Inc(j);
    bufferU[j] := na;
    Inc(j);
    bufferU[j] := addr shr 8;
    Inc(j);
    if na > 8 then
     bufferU[j] := addr and $FF;
     Inc(j);
    bufferU[j] := $3C;
    Inc(j);
    if options = 0 then
    begin
     bufferU[j] := 16;
     Inc(j);
     bufferU[j] := memEE[i + 1];
     Inc(j);
     bufferU[j] := memEE[i];
     Inc(j);
    end
    else
    begin
     bufferU[j] := 8;
     Inc(j);
     bufferU[j] := memEE[i];
     Inc(j);
    end;
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(options = 0, $20 + $08, $08);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(options = 0, $10 + $20 + $08, $10 + $08);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $3D;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    sprintf(str, strings[S_CodeWriting2], (i * 100) div dim, i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    if RWstop then
     i := dim;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
    bufferU[j] := $3D;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    z := 0;
    k := 0;
    while (z < 30) and not (k) do
    begin
     PacketIO(2);
     j := 0;
     while (j < 64 - 1) and (bufferI[j] <> $3D) do
     begin
      Inc(j);
     end;
     if bufferI[j] = $3D then
      k := bufferI[j + 2];
     Inc(z);
    end;
    j := 0;
   end;
   Inc(i, IfThen(options = 0, 2, 1));
   Inc(addr, $10000 shr na);
  end;
  msDelay(2);
  if i <> dim then
  begin
   sprintf(str, strings[S_CodeWError4], i, dim);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  j := 0;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $20 + $08, $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := IfThen(options = 0, $10 + $20 + $08, $10 + $08);
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  k := 0;
  dim2 := IfThen(options = 0, dim div 2, dim);
  i := 0;
  while i < dim2 do
  begin
   j := 0;
   while (j < 64 - 14) and (i < dim2) do
   begin
    bufferU[j] := $3C;
    Inc(j);
    bufferU[j] := na + 3;
    Inc(j);
    bufferU[j] := $C0 + (i shr (na - 5)) and $1F;
    Inc(j);
    bufferU[j] := (i shl (13 - na)) and $FF;
    Inc(j);
    bufferU[j] := $3D;
    Inc(j);
    bufferU[j] := IfThen(options = 0, 16, 8);
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(options = 0, $20, 0);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := IfThen(options = 0, $10 + $20, $10);
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    Inc(i);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   for z := 0 to (64 - 3) - 1 do
   begin
    while (bufferI[z] <> $3D) and (z < 64 - 3) do
    begin
     Inc(z);
    end;
    if bufferI[z] = $3D then
    begin
     if options = 1 then
     begin
      if memEE[k] <> bufferI[z + 2] then
      begin
       PrintMessage('' + #13 + '' + NL + '');
       sprintf(str, strings[S_CodeVError], k, k, memEE[k], bufferI[z + 2]);
       PrintMessage(str);
       Inc(err);
      end;
      Inc(k);
     end
     else
     begin
      if memEE[k] <> bufferI[z + 3] then
      begin
       PrintMessage('' + #13 + '' + NL + '');
       sprintf(str, strings[S_CodeVError], k, k, memEE[k], bufferI[z + 3]);
       PrintMessage(str);
       Inc(err);
      end;
      if memEE[k + 1] <> bufferI[z + 2] then
      begin
       PrintMessage('' + #13 + '' + NL + '');
       sprintf(str, strings[S_CodeVError], k + 1, k + 1, memEE[k + 1], bufferI[z + 2]);
       PrintMessage(str);
       Inc(err);
      end;
      k := k + 2;
     end;
     z := z + 3;
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div dim2, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if err >= max_err then
    Break;
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Read25xx(dim: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  ID: Integer;
  start: Cardinal;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if (dim > $1000000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read25xx(%d)    (0x%X)' + NL + '', dim, dim);
  end;
  sizeEE := dim;
  if memEE then
   free(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $2F;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $9F;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  if dim > $10000 then
  begin
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end
  else
   if dim > $200 then
   begin
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
   end
   else
   begin
    bufferU[j] := 2;
    Inc(j);
    bufferU[j] := 3;
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
  PacketIO(5);
  z := 0;
  while (z < 64 - 4) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  ID := (bufferI[z + 2] shl 16) + (bufferI[z + 3] shl 8) + bufferI[z + 4];
  if (ID > 0) and (ID <> $FFFFFF) then
  begin
   sprintf(str, 'DEVICE ID=0x%06X' + #13 + '' + NL + '', ID);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ReadEE]);
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(4);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $30) do
   begin
    Inc(j);
   end;
   if (bufferI[j] = $30) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     memEE[k] := bufferI[z];
     Inc(k);
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   Inc(i, 64 - 4);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
   sum := sum + memEE[i];
  end;
  sprintf(str, 'Checksum: 0x%X' + #13 + '' + NL + '', sum and $FFFF);
  PrintMessage(str);
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write25xx(dim: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  ID: Integer;
  err: Integer;
  page: Integer;
  start: Cardinal;
  pp: Integer;
  i0: Integer;
  k2: Integer;
  valid: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  page := options and $FFF;
  if (dim > $1000000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write25xx(%d,%d)    (0x%X,0x%X)' + NL + '', dim, options, dim, options);
  end;
  if dim > sizeEE then
  begin
   i := sizeEE;
   memEE := realloc(memEE, dim);
   while i < dim do
   begin
    memEE[i] := $FF;
    Inc(i);
   end;
   sizeEE := dim;
  end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $2F;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $9F;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 5;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  if options and $2000 then
  begin
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $35;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  z := 0;
  while (z < 64 - 4) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  ID := (bufferI[z + 2] shl 16) + (bufferI[z + 3] shl 8) + bufferI[z + 4];
  if (ID > 0) and (ID <> $FFFFFF) then
  begin
   sprintf(str, 'DEVICE ID=0x%06X' + #13 + '' + NL + '', ID);
   PrintMessage(str);
   if saveLog then
    fprintf(logfile, 'DEVICE ID=0x%06X' + NL + '', ID);
  end;
  msDelay(10);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 6;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  if options and $2000 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 5;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 8 + 16;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  if options and $1000 then
  begin
   PrintMessage(strings[S_StartErase]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 5;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   if options and $2000 then
   begin
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := 16;
    Inc(j);
    bufferU[j] := $40;
    Inc(j);
    bufferU[j] := $31;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := $35;
    Inc(j);
    bufferU[j] := $30;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := 8 + 16;
    Inc(j);
    bufferU[j] := $40;
    Inc(j);
   end;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 6;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $C7;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   j := 0;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 5;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   pp := 1;
   j := 0;
   while pp and (j < 400) do
   begin
    PacketIO(2);
    msDelay(100);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $30) do
    begin
     Inc(z);
    end;
    pp := bufferI[z + 2] and 1;
    sprintf(str, strings[S_StartErase], 0, 0);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    Inc(j);
   end;
   if saveLog then
    fprintf(logfile, 'Erase time %d ms' + NL + '', j * 100);
   PrintMessage(strings[S_Compl]);
   sprintf(str, strings[S_Compl], 0, 0);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
  end;
  PrintMessage(strings[S_EEAreaW]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
  j := 0;
  i := 0;
  while i < dim do
  begin
   if options and $1000 then
   begin
    k := page;
    while (k = page) and (i < dim - page) do
    begin
     for k := 0 to (page) - 1 do
     begin
      if memEE[i + k] < $FF then
       k := page;
     end;
     if k = page then
      i := i + page;
    end;
   end;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 6;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   if dim > $10000 then
   begin
    bufferU[j] := 4;
    Inc(j);
    bufferU[j] := 2;
    Inc(j);
    bufferU[j] := i shr 16;
    Inc(j);
    bufferU[j] := (i shr 8) and $FF;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
   end
   else
    if dim > $200 then
    begin
     bufferU[j] := 3;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := i and $FF;
     Inc(j);
    end
    else
    begin
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := 2 + IfThen(i and $100, 8, 0);
     Inc(j);
     bufferU[j] := i and $FF;
     Inc(j);
    end;
   pp := IfThen(page < 64 - j - 4, page, 64 - j - 4);
   k := 0;
   while k < page do
   begin
    bufferU[j] := $31;
    Inc(j);
    bufferU[j] := pp;
    Inc(j);
    while (k < page) and pp do
    begin
     bufferU[j] := memEE[i + k];
     Inc(j);
     Inc(k);
     Dec(pp);
    end;
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $31) do
    begin
     Inc(z);
    end;
    if bufferI[z + 1] >= $FA then
     i := dim + 10; k := dim + 10;
    pp := IfThen(page - k < 64 - 4, page - k, 64 - 4);
    j := 0;
   end;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 5;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := 5;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 8 + 16;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   pp := 1;
   j := 0;
   while pp and (j < 50) do
   begin
    PacketIO(2);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $30) do
    begin
     Inc(z);
    end;
    pp := bufferI[z + 2] and 1;
    Inc(j);
   end;
   sprintf(str, strings[S_CodeWriting2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
   Inc(i, page);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_EEV]);
  j := 0;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 16;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  if dim > $10000 then
  begin
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end
  else
   if dim > $200 then
   begin
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
   end
   else
   begin
    bufferU[j] := 2;
    Inc(j);
    bufferU[j] := 3;
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
  PacketIO(2);
  k := 0;
  j := 0;
  i := 0;
  while i < dim do
  begin
   if options and $1000 then
   begin
    i0 := i;
    valid := 0;
    while not (valid) and (i < dim) do
    begin
     k2 := 0;
     while (k2 < 64 - 4) and not (valid) and (i + k2 < dim) do
     begin
      if memEE[i + k2] < $FF then
       valid := 1;
      Inc(k2);
     end;
     Inc(i, IfThen(valid, 0, 64 - 4));
    end;
    if i >= dim then
     Break;
    if i > i0 then
    begin
     j := 0;
     bufferU[j] := $32;
     Inc(j);
     bufferU[j] := 8 + 16;
     Inc(j);
     bufferU[j] := $40;
     Inc(j);
     bufferU[j] := $32;
     Inc(j);
     bufferU[j] := 16;
     Inc(j);
     bufferU[j] := 0;
     Inc(j);
     bufferU[j] := $31;
     Inc(j);
     if dim > $10000 then
     begin
      bufferU[j] := 4;
      Inc(j);
      bufferU[j] := 3;
      Inc(j);
      bufferU[j] := i shr 16;
      Inc(j);
      bufferU[j] := (i shr 8) and $FF;
      Inc(j);
      bufferU[j] := i and $FF;
      Inc(j);
     end
     else
      if dim > $200 then
      begin
       bufferU[j] := 3;
       Inc(j);
       bufferU[j] := 3;
       Inc(j);
       bufferU[j] := i shr 8;
       Inc(j);
       bufferU[j] := i and $FF;
       Inc(j);
      end
      else
      begin
       bufferU[j] := 2;
       Inc(j);
       bufferU[j] := 3 + IfThen(i and $100, 8, 0);
       Inc(j);
       bufferU[j] := i and $FF;
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
    end;
   end;
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(4);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $30) do
   begin
    Inc(j);
   end;
   if (bufferI[j] = $30) and (bufferI[j + 1] < $FA) then
   begin
    z := 0;
    while (z < bufferI[j + 1]) and (z < 64) do
    begin
     if memEE[i + z] <> bufferI[z + j + 2] then
     begin
      sprintf(str, strings[S_CodeVError], i + z, i + z, memEE[i + z], bufferI[z + 3]);
      PrintMessage(str);
      Inc(err);
     end;
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, 64 - 4);
  end;
  if i < dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, i);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function OW_ID(id: Integer): Pointer;
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (SizeOf(OW_LIST) div SizeOf(OW_LIST[0])) - 1 do
  begin
   if id = OW_LIST[i].id then
   begin
    sprintf(s, OW_LIST[i].device, id);
    PrintMessage(s);
    Exit;
   end;
  end;
  sprintf(s, '%s', strings[S_nodev]);
  PrintMessage(s);
end;

function ReadOneWireMem(dim: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  start: Cardinal;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if FWVersion < $800 then
  begin
   sprintf(str, strings[S_FWver2old], '0.8.0');
   PrintMessage(str);
   Exit;
  end;
  if (dim > $10000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'ReadOneWireMem(%d)    (0x%X)' + NL + '', dim, dim);
  end;
  sizeEE := dim;
  if memEE then
   free(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $41;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $33;
  Inc(j);
  bufferU[j] := $42;
  Inc(j);
  bufferU[j] := 8;
  Inc(j);
  if dim <= 32 then
  begin
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $F0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $F0;
   Inc(j);
   bufferU[j] := 0;
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
  PacketIO(12);
  j := 0;
  z := 0;
  while (bufferI[z] <> $40) and (z < 64) do
  begin
   Inc(z);
  end;
  if (bufferI[z] = $40) and (bufferI[z + 1] = 0) then
  begin
   PrintMessage(strings[S_ComErr]);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   Exit;
  end;
  while (bufferI[z] <> $42) and (z < 64) do
  begin
   Inc(z);
  end;
  if (bufferI[z] = $42) and (z < 64 - 9) then
  begin
   sprintf(str, 'Family code: 0x%02X ', bufferI[z + 2]);
   PrintMessage(str);
   OW_ID(bufferI[z + 2]);
   sprintf(str, 'Serial ID: 0x%02X%02X%02X', bufferI[z + 3], bufferI[z + 4], bufferI[z + 5]);
   PrintMessage(str);
   sprintf(str, '%02X%02X%02X', bufferI[z + 6], bufferI[z + 7], bufferI[z + 8]);
   PrintMessage(str);
   sprintf(str, '' + #13 + '' + NL + 'CRC: 0x%02X' + #13 + '' + NL + '', bufferI[z + 9]);
   PrintMessage(str);
  end;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $42;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(37);
   j := 0;
   while (bufferI[j] <> $42) and (j < 64) do
   begin
    Inc(j);
   end;
   if (bufferI[j] = $42) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     memEE[k] := bufferI[z];
     Inc(k);
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   Inc(i, 64 - 4);
  end;
  if options = 1 then
  begin
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $CC;
   Inc(j);
   bufferU[j] := $66;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $42;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $CC;
   Inc(j);
   bufferU[j] := $C3;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $42;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(15);
   j := 0;
   z := 0;
   while (bufferI[z] <> $42) and (z < 64 - 2) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'Status register: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 2;
   while (bufferI[z] <> $42) and (z < 64 - 10) do
   begin
    Inc(z);
   end;
   PrintMessage('Application register: 0x');
   i := z + 2;
   while (i < z + 10) and (i < 64) do
   begin
    sprintf(str, '%02X', bufferI[i]);
    PrintMessage(str);
    Inc(i);
   end;
   PrintMessage('' + #13 + '' + NL + '');
  end
  else
   if options = 2 then
   begin
    bufferU[j] := $42;
    Inc(j);
    if dim = $A00 then
     bufferU[j] := $24;
     Inc(j)
    else
     bufferU[j] := 8;
     Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(25);
    j := 0;
    z := 0;
    while (bufferI[z] <> $42) and (z < 64 - 2) do
    begin
     Inc(z);
    end;
    if (bufferI[z] = $42) and (bufferI[z + 1] < $FA) then
    begin
     if dim = $A00 then
     begin
      for i := 0 to (10) - 1 do
      begin
       sprintf(str, 'Protection Control Byte Block %d: 0x%02X' + #13 + '' + NL + '', i, bufferI[z + 2 + i]);
       PrintMessage(str);
      end;
      PrintMessage('User EEPROM:' + #13 + '' + NL + '');
      for i := 0 to (10) - 1 do
      begin
       sprintf(str, '%02X', bufferI[z + 2 + i + 10]);
       PrintMessage(str);
      end;
      PrintMessage('' + #13 + '' + NL + '');
      for i := 0 to (10) - 1 do
      begin
       sprintf(str, '%02X', bufferI[z + 2 + i + 20]);
       PrintMessage(str);
      end;
      sprintf(str, '' + #13 + '' + NL + 'Memory Block Lock: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 30]);
      PrintMessage(str);
      sprintf(str, 'Register Page Lock: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 31]);
      PrintMessage(str);
      sprintf(str, 'Factory Byte: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 32]);
      PrintMessage(str);
      sprintf(str, 'Factory Trim Bytes: 0x%02X%02X' + #13 + '' + NL + '', bufferI[z + 2 + 33], bufferI[z + 2 + 34]);
      PrintMessage(str);
      sprintf(str, 'Manufacturer ID: 0x%02X%02X' + #13 + '' + NL + '', bufferI[z + 2 + 35], bufferI[z + 2 + 36]);
      PrintMessage(str);
     end
     else
     begin
      sprintf(str, 'Protection Control Byte Page 0: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
      PrintMessage(str);
      sprintf(str, 'Protection Control Byte Page 1: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 1]);
      PrintMessage(str);
      sprintf(str, 'Protection Control Byte Page 2: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 2]);
      PrintMessage(str);
      sprintf(str, 'Protection Control Byte Page 3: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 3]);
      PrintMessage(str);
      sprintf(str, 'Copy Protection Byte: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 4]);
      PrintMessage(str);
      sprintf(str, 'Factory Byte: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2 + 5]);
      PrintMessage(str);
      sprintf(str, 'User Bytes/Manufacturer ID: 0x%02X%02X' + #13 + '' + NL + '', bufferI[z + 2 + 6], bufferI[z + 2 + 7]);
      PrintMessage(str);
     end;
    end;
   end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
   sizeEE := k;
  end;
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
   sum := sum + memEE[i];
  end;
  sprintf(str, 'Checksum: 0x%X' + #13 + '' + NL + '', sum and $FFFF);
  PrintMessage(str);
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function WriteOneWireMem(dim: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  start: Cardinal;
  page: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  if FWVersion < $800 then
  begin
   sprintf(str, strings[S_FWver2old], '0.8.0');
   PrintMessage(str);
   Exit;
  end;
  if (dim > $10000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'WriteOneWireMem(%d,%d)    (0x%X,0x%X)' + NL + '', dim, options, dim, options);
  end;
  if dim > sizeEE then
  begin
   i := sizeEE;
   memEE := realloc(memEE, dim);
   while i < dim do
   begin
    memEE[i] := $FF;
    Inc(i);
   end;
   sizeEE := dim;
  end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $41;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $33;
  Inc(j);
  bufferU[j] := $42;
  Inc(j);
  bufferU[j] := 8;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(12);
  j := 0;
  z := 0;
  while (bufferI[z] <> $40) and (z < 64) do
  begin
   Inc(z);
  end;
  if (bufferI[z] = $40) and (bufferI[z + 1] = 0) then
  begin
   PrintMessage(strings[S_ComErr]);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  z := 0;
  while (bufferI[z] <> $42) and (z < 64) do
  begin
   Inc(z);
  end;
  if bufferI[z] = $42 then
  begin
   sprintf(str, 'Family code: 0x%02X ', bufferI[z + 2]);
   PrintMessage(str);
   OW_ID(bufferI[z + 2]);
   sprintf(str, 'Serial ID: 0x%02X%02X%02X', bufferI[z + 3], bufferI[z + 4], bufferI[z + 5]);
   PrintMessage(str);
   sprintf(str, '%02X%02X%02X', bufferI[z + 6], bufferI[z + 7], bufferI[z + 8]);
   PrintMessage(str);
   sprintf(str, '' + #13 + '' + NL + 'CRC: 0x%02X' + #13 + '' + NL + '', bufferI[z + 9]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_EEAreaW]);
  page := IfThen(options = 0, 8, 32);
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := page + IfThen(dim <= 32, 3, 4);
   Inc(j);
   bufferU[j] := $CC;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := i and $FF;
   Inc(j);
   if dim > 32 then
    bufferU[j] := i shr 8;
    Inc(j);
   for k := 0 to (page) - 1 do
   begin
    bufferU[j] := memEE[i + k];
    Inc(j);
   end;
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := IfThen(dim <= 32, 3, 5);
   Inc(j);
   bufferU[j] := $CC;
   Inc(j);
   bufferU[j] := $55;
   Inc(j);
   if dim <= 32 then
    bufferU[j] := $A5;
    Inc(j)
   else
   begin
    bufferU[j] := i and $FF;
    Inc(j);
    bufferU[j] := i shr 8;
    Inc(j);
    bufferU[j] := page - 1;
    Inc(j);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(6 + 0.8 * page);
   msDelay(10);
   j := 0;
   sprintf(str, strings[S_CodeWriting2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
   Inc(i, page);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_EEV]);
  k := 0;
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $41;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $CC;
  Inc(j);
  if dim <= 32 then
  begin
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $F0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $41;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $F0;
   Inc(j);
   bufferU[j] := 0;
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
  j := 0;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $42;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(37);
   j := 0;
   while (bufferI[j] <> $42) and (j < 64) do
   begin
    Inc(j);
   end;
   if (bufferI[j] = $42) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     if memEE[k] <> bufferI[z] then
     Inc(k);
     begin
      PrintMessage('' + #13 + '' + NL + '');
      sprintf(str, strings[S_CodeVError], (i + z) - (j + 2), (i + z) - (j + 2), memEE[k - 1], bufferI[z]);
      PrintMessage(str);
      Inc(err);
     end;
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, 64 - 4);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
   sizeEE := k;
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure ReadDS1820;
var
  z: Integer;
  j: Integer;
  TLSB: Double;
  start: Cardinal;
  T: Integer;
  stop: Cardinal;
begin
  z := 0;
  TLSB := 0.5;
  hvreg := 0;
  if FWVersion < $800 then
  begin
   sprintf(str, strings[S_FWver2old], '0.8.0');
   PrintMessage(str);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'ReadDS1820()' + NL + '');
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $41;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $33;
  Inc(j);
  bufferU[j] := $42;
  Inc(j);
  bufferU[j] := 8;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $41;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $CC;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(16);
  j := 0;
  z := 0;
  while (bufferI[z] <> $40) and (z < 64) do
  begin
   Inc(z);
  end;
  if (bufferI[z] = $40) and (bufferI[z + 1] = 0) then
  begin
   PrintMessage(strings[S_ComErr]);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  z := 0;
  while (bufferI[z] <> $42) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 9 then
  begin
   sprintf(str, 'Family code: 0x%02X ', bufferI[z + 2]);
   PrintMessage(str);
   OW_ID(bufferI[z + 2]);
   if bufferI[z + 2] = $10 then
    TLSB := 0.5
   else
    if bufferI[z + 2] = $28 then
     TLSB := 0.0625;
   sprintf(str, 'Serial ID: 0x%02X%02X%02X', bufferI[z + 3], bufferI[z + 4], bufferI[z + 5]);
   PrintMessage(str);
   sprintf(str, '%02X%02X%02X', bufferI[z + 6], bufferI[z + 7], bufferI[z + 8]);
   PrintMessage(str);
   sprintf(str, '' + #13 + '' + NL + 'CRC: 0x%02X' + #13 + '' + NL + '', bufferI[z + 9]);
   PrintMessage(str);
  end;
  msDelay(800);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $41;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $CC;
  Inc(j);
  bufferU[j] := $BE;
  Inc(j);
  bufferU[j] := $42;
  Inc(j);
  bufferU[j] := 8;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(10);
  j := 0;
  z := 0;
  while (bufferI[z] <> $42) and (z < 64 - 2) do
  begin
   Inc(z);
  end;
  T := bufferI[z + 2] + (bufferI[z + 3] shl 8);
  if T > $F000 then
   T := T or $FFFF0000;
  sprintf(str, 'T=%.4f°C  (0x%04X)' + #13 + '' + NL + '', T * TLSB, T);
  PrintMessage(str);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Read11xx(dim: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  start: Cardinal;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if FWVersion < $800 then
  begin
   sprintf(str, strings[S_FWver2old], '0.8.0');
   PrintMessage(str);
   Exit;
  end;
  if (dim >= $10000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read11xx(%d)    (0x%X)' + NL + '', dim, dim);
  end;
  sizeEE := dim;
  if memEE then
   free(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $05;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  PrintMessage(strings[S_ReadEE]);
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $44;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 64 - 5, 64 - 5, dim - i);
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := $03;
   Inc(j);
   bufferU[j] := i shr 8;
   Inc(j);
   bufferU[j] := i and $FF;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(14);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $44) do
   begin
    Inc(j);
   end;
   if (bufferI[j] = $44) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     memEE[k] := bufferI[z];
     Inc(k);
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   Inc(i, 64 - 5);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
   sum := sum + memEE[i];
  end;
  sprintf(str, 'Checksum: 0x%X' + #13 + '' + NL + '', sum and $FFFF);
  PrintMessage(str);
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write11xx(dim: Integer; page: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  start: Cardinal;
  status: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  if FWVersion < $800 then
  begin
   sprintf(str, strings[S_FWver2old], '0.8.0');
   PrintMessage(str);
   Exit;
  end;
  hvreg := 0;
  if (dim >= $10000) or (dim < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write11xx(%d,%d)    (0x%X,0x%X)' + NL + '', dim, page, dim, page);
  end;
  if dim > sizeEE then
  begin
   i := sizeEE;
   memEE := realloc(memEE, dim);
   while i < dim do
   begin
    memEE[i] := $FF;
    Inc(i);
   end;
   sizeEE := dim;
  end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $43;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $05;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $05;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(25);
  PrintMessage(strings[S_EEAreaW]);
  while page >= 64 - 8 do
  begin
   page := page shr 1;
  end;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $44;
   Inc(j);
   bufferU[j] := 4 + page;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := $6C;
   Inc(j);
   bufferU[j] := i shr 8;
   Inc(j);
   bufferU[j] := i and $FF;
   Inc(j);
   for k := 0 to (page) - 1 do
   begin
    bufferU[j] := memEE[i + k];
    Inc(j);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO((5 + page) * 0.2 + 2);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $44) do
   begin
    Inc(j);
   end;
   if (bufferI[j] <> $44) or (bufferI[j + 1] >= $FA) then
    i := dim + 10;
   sprintf(str, strings[S_CodeWriting2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   bufferU[j] := $44;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $44;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   status := 1;
   k := 0;
   while status and (k < 20) do
   begin
    PacketIO(2);
    j := 0;
    while (j < 64 - 1) and (bufferI[j] <> $44) do
    begin
     Inc(j);
    end;
    if bufferI[j] = $44 then
     status := bufferI[j + 2] and 1;
    Inc(k);
   end;
   j := 0;
   Inc(i, page);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  k := 0;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $44;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 64 - 4, 64 - 4, dim - i);
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := $03;
   Inc(j);
   bufferU[j] := i shr 8;
   Inc(j);
   bufferU[j] := i and $FF;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(14);
   j := 0;
   while (j < 64 - 1) and (bufferI[j] <> $44) do
   begin
    Inc(j);
   end;
   if (bufferI[j] = $44) and (bufferI[j + 1] < $FA) then
   begin
    z := j + 2;
    while (z < j + 2 + bufferI[j + 1]) and (z < 64) do
    begin
     if memEE[k] <> bufferI[z] then
     Inc(k);
     begin
      PrintMessage('' + #13 + '' + NL + '');
      sprintf(str, strings[S_CodeVError], (i + z) - 3, (i + z) - 3, memEE[k - 1], bufferI[z]);
      PrintMessage(str);
      Inc(err);
     end;
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, 64 - 4);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadEEErr], dim, k);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

end.

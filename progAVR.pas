unit progavr;

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
  LOCK = 1;
  FUSE = 2;
  FUSE_H = 4;
  FUSE_X = 8;
  CAL = 16;
  SLOW = 256;
  RST = $40;
  SPEED = 3000;
  SDI = $10;
  SII = $1;
  SDO = $2;
  SCI = $8;

const
  SLOW = 256;

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
  AVRLIST: array of TAVRID;

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
function AtmelID(id: array of TBYTE): Pointer;
function DisplayCODEAVR(dim: Integer): Pointer;
function SWSPI(data: Integer; speed: Integer): Integer;
function WriteATfuseSlow(fuse: Integer): Pointer;
function SyncSPI: Double;
function ReadAT(dim: Integer; dim2: Integer; options: Integer): Pointer;
function ReadAT_HV(dim: Integer; dim2: Integer; options: Integer): Pointer;
function WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer): Pointer;
function WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
function WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;

implementation

function AtmelID(id: array of TBYTE): Pointer;
var
  str: array[0..128-1] of Char;
  i: Integer;
  idw: Integer;
begin
  str := '';
  idw := (id[1] shl 8) + id[2];
  if (id[0] = 0) and (id[1] = 1) and (id[2] = 2) then
  begin
   PrintMessage(strings[S_Protected]);
   Exit;
  end;
  if id[0] = $1E then
   strcat(str, 'Atmel ');
  for i := 0 to (SizeOf(AVRLIST) div SizeOf(AVRLIST[0])) - 1 do
  begin
   if idw = AVRLIST[i].id then
   begin
    strcat(str, AVRLIST[i].device);
    i := 1000;
   end;
  end;
  case id[1] of
   $90:
   begin
    strcat(str, ' 1KB Flash');
   end;
   $91:
   begin
    strcat(str, ' 2KB Flash');
   end;
   $92:
   begin
    strcat(str, ' 4KB Flash');
   end;
   $93:
   begin
    strcat(str, ' 8KB Flash');
   end;
   $94:
   begin
    strcat(str, ' 16KB Flash');
   end;
   $95:
   begin
    strcat(str, ' 32KB Flash');
   end;
   $96:
   begin
    strcat(str, ' 64KB Flash');
   end;
   $97:
   begin
    strcat(str, ' 128KB Flash');
   end;
  end;
  if i <> 1001 then
   strcat(str, strings[S_nodev])
  else
   strcat(str, '' + #13 + '' + NL + '');
  PrintMessage(str);
end;

function DisplayCODEAVR(dim: Integer): Pointer;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
  aux: PChar;
begin
  s := '';
  t := '';
  valid := 0;
  empty := 1;
  lines := 0;
  aux := malloc((dim div 16 + 1) * (16 + 16 * 6));
  aux[0] := 0;
  s[0] := 0;
  i := 0;
  while (i < dim) and (i < size) do
  begin
   valid := 0;
   j := i;
   while (j < i + 16 * 2) and (j < dim) do
   begin
    sprintf(t, '%02X ', memCODE[j]);
    strcat(s, t);
    if memCODE[j] < $ff then
     valid := 1;
    Inc(j);
   end;
   if valid then
   begin
    sprintf(t, '%04X: %s' + #13 + '' + NL + '', i, s);
    strcat(aux, t);
    empty := 0;
    Inc(lines);
    if lines > 500 then
    begin
     strcat(aux, '(...)' + #13 + '' + NL + '');
     i := IfThen(dim < size, dim, size) - 16 * 4;
     lines := 490;
    end;
   end;
   s[0] := 0;
   Inc(i, 16 * 2);
  end;
  if empty then
   PrintMessage(strings[S_Empty])
  else
   PrintMessage(aux);
  free(aux);
end;

function SWSPI(data: Integer; speed: Integer): Integer;
var
  i: Integer;
  j: Integer;
  din: Integer;
  Tbit: Double;
begin
  din := 0;
  Tbit := (1.0 div speed) * 1e6;
  if saveLog then
   fprintf(logfile, 'SWSPI(0x%X,%d)' + NL + '', data, speed);
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := Tbit div 2 shr 8;
  Inc(j);
  bufferU[j] := Tbit div 2 and $ff;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $F5;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  for i := 0 to (4) - 1 do
  begin
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := data and $80;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := data and $80;
   Inc(j);
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   data := data shl 1;
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1 + 4 * (Tbit div 1000.0 + 0.5));
  j := 0;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 2;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 2;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 2;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 0;
  for i := 0 to (4) - 1 do
  begin
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := data and $80;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := data and $80;
   Inc(j);
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   data := data shl 1;
  end;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
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
  PacketIO(1 + 4 * (Tbit div 1000.0 + 0.5));
  j := 0;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 2;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 2;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  din := din shl 1;
  j := 2;
  while (j < 64 - 1) and (bufferI[j] <> $46) do
  begin
   Inc(j);
  end;
  din := din + bufferI[j + 1] and 1;
  if saveLog then
   fprintf(logfile, 'Read 0x%X' + NL + '', din);
  Exit(din);
end;

function WriteATfuseSlow(fuse: Integer): Pointer;
var
  j: Integer;
  d: Integer;
begin
  fuse := fuse and $FF;
  if FWVersion < $900 then
  begin
   sprintf(str, strings[S_FWver2old], '0.9.0');
   PrintMessage(str);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'WriteATfuseSlow(0x%X)' + NL + '', fuse);
  end;
  PrintMessage(strings[S_FuseAreaW]);
  j := 0;
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $F5;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $35;
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
  msDelay(20);
  SWSPI($AC, 3000);
  SWSPI($53, 3000);
  d := SWSPI(0, 3000);
  SWSPI(0, 3000);
  if d <> $53 then
  begin
   j := 0;
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
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
   PrintMessage(strings[S_SyncErr]);
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  SWSPI($AC, 3000);
  SWSPI($A0, 3000);
  SWSPI($00, 3000);
  SWSPI(fuse, 3000);
  msDelay(9);
  SWSPI($50, 3000);
  SWSPI($00, 3000);
  SWSPI($00, 3000);
  d := SWSPI(0, 3000);
  if d <> fuse then
  begin
   sprintf(str, strings[S_WErr1], 'fuse', fuse, d);
   PrintMessage(str);
  end;
  j := 0;
  bufferU[j] := $35;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $0E;
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
  PrintMessage(strings[S_Compl]);
end;

function SyncSPI: Double;
var
  z: Integer;
  i: Integer;
  j: Integer;
  Tbyte: Double;
  d0: Integer;
  d1: Integer;
  d2: Integer;
  d3: Integer;
  d4: Integer;
  d5: Integer;
  d6: Integer;
  d7: Integer;
begin
  z := 0;
  j := 0;
  bufferU[j] := $2F;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  for i := 1 to (256) - 1 do
  begin
   if i > 10 then
    Inc(i);
   if i > 20 then
    i := i + 2;
   if i > 40 then
    i := i + 4;
   if i > 80 then
    i := i + 4;
   if i > 160 then
    i := i + 8;
   Tbyte := (20 + i * 4) div 1000.0;
   j := 0;
   bufferU[j] := $35;
   Inc(j);
   bufferU[j] := $FF;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $07;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := i;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $32;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $35;
   Inc(j);
   bufferU[j] := 5;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(9);
   msDelay(20);
   j := 0;
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $53;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 11;
   Inc(j);
   bufferU[j] := $55;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $AA;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $55;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $AA;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $53;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $30;
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
   PacketIO(1.5 + 32 * Tbyte * 1.1);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d0 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d1 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d2 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d3 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d4 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d5 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d6 := bufferI[z + 2];
   z := bufferI[z + 1] + 1;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   d7 := bufferI[z + 2];
   if (d0 = $53) and (d6 = $53) and (d1 = d2) and (d1 = d3) and (d1 = d4) and (d1 = d5) and (d1 = d7) then
    Break;
  end;
  if i > 256 then
  begin
   PrintMessage(strings[S_SyncErr]);
   if saveLog then
    fprintf(logfile, strings[S_SyncErr]);
   Exit(0);
  end;
  Inc(i);
  i := i + i div 10;
  if i > 255 then
   i := 255;
  Tbyte := (20 + i * 4) div 1000.0;
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := i;
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
  sprintf(str, strings_it[I_AT_COMM], 8 div Tbyte);
  PrintMessage(str);
  if saveLog then
   fprintf(logfile, str);
  Exit(Tbyte);
end;

function ReadAT(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  Tbyte: Double;
  signature: array of TBYTE;
  start: Cardinal;
  c: Integer;
  n: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  signature := [0, 0, 0];
  if (dim > $20000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $1000) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'ReadAT(0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options);
  end;
  size := dim;
  sizeEE := dim2;
  if memCODE then
   free(memCODE);
  memCODE := malloc(dim);
  if memEE then
   free(memEE);
  memEE := malloc(dim2);
  for j := 0 to (size) - 1 do
  begin
   memCODE[j] := $FF;
  end;
  for j := 0 to (sizeEE) - 1 do
  begin
   memEE[j] := $FF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $06;
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
  Tbyte := SyncSPI();
  if Tbyte = 0 then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  j := 0;
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  if options and 1 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
  end;
  if options and 2 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $50;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
  end;
  if options and 4 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
  end;
  if options and 8 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $50;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1.5 + 7 * 4.5 * Tbyte);
  z := 0;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[0] := bufferI[z + 2];
  z := 3;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[1] := bufferI[z + 2];
  z := 3;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[2] := bufferI[z + 2];
  sprintf(str, 'CHIP ID:%02X%02X%02X' + #13 + '' + NL + '', signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  if options and 1 then
  begin
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, 'LOCK bits:' + #9 + '  0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
   PrintMessage(str);
  end;
  if options and 2 then
  begin
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, 'FUSE bits:' + #9 + '  0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
   PrintMessage(str);
  end;
  if options and 4 then
  begin
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, 'FUSE HIGH bits:' + #9 + '  0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
   PrintMessage(str);
  end;
  if options and 8 then
  begin
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, 'Extended FUSE bits: 0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
   PrintMessage(str);
  end;
  if options and 16 then
  begin
   j := 0;
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $30;
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
   PacketIO(1.5 + 4.5 * 4 * Tbyte);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, 'Calibration bits:' + #9 + '  0x%02X', bufferI[z + 2]);
   PrintMessage(str);
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, ',0x%02X', bufferI[z + 2]);
   PrintMessage(str);
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, ',0x%02X', bufferI[z + 2]);
   PrintMessage(str);
   z := 3;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   sprintf(str, ',0x%02X' + #13 + '' + NL + '', bufferI[z + 2]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeReading1]);
  c := (64 - 5) div 2;
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $33;
   Inc(j);
   bufferU[j] := IfThen(i < dim - 2 * c, c, (dim - i) div 2);
   Inc(j);
   bufferU[j] := i shr 9;
   Inc(j);
   bufferU[j] := i shr 1;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(1.5 + 240 * Tbyte);
   if bufferI[0] = $33 then
   begin
    z := 2;
    while (z < bufferI[1] * 2 + 2) and (z < 64) do
    begin
     memCODE[k] := bufferI[z];
     Inc(k);
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeReading], (i * 100) div (dim + dim2), i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   Inc(i, c * 2);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if dim2 then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ReadEE]);
   n := 0;
   k2 := 0;
   i := 0;
   j := 0;
   while i < dim2 do
   begin
    bufferU[j] := $31;
    Inc(j);
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
    bufferU[j] := i shr 8;
    Inc(j);
    bufferU[j] := i;
    Inc(j);
    bufferU[j] := $30;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    Inc(n);
    if (j > 64 - 9) or (i = dim - 1) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(1.5 + 4 * n * Tbyte * 1.3);
     for z := 0 to (64 - 2) - 1 do
     begin
      if (bufferI[z] = $30) and (bufferI[z + 1] = 1) then
      begin
       memEE[k2] := bufferI[z + 2];
       Inc(k2);
       z := z + 3;
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((i + dim) * 100) div (dim + dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := dim2;
     j := 0;
     n := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
    Inc(i);
   end;
   if k2 <> dim2 then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadEEErr], dim2, k2);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[j] := $35;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
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
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  PrintMessage(strings[S_CodeMem]);
  DisplayCODEAVR(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function ReadAT_HV(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  signature: array of TBYTE;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  signature := [0, 0, 0];
  if FWVersion < $900 then
  begin
   sprintf(str, strings[S_FWver2old], '0.9.0');
   PrintMessage(str);
   Exit;
  end;
  if (dim > $20000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'ReadAT_HV(0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options);
  end;
  size := dim;
  sizeEE := dim2;
  if memCODE then
   free(memCODE);
  memCODE := malloc(dim);
  if memEE then
   free(memEE);
  memEE := malloc(dim2);
  for j := 0 to (size) - 1 do
  begin
   memCODE[j] := $FF;
  end;
  for j := 0 to (sizeEE) - 1 do
  begin
   memEE[j] := $FF;
  end;
  if not (StartHVReg(12)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $FC;
  Inc(j);
  bufferU[j] := $7;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $7;
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
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $68;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $01;
  Inc(j);
  bufferU[j] := $68;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $68;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  if options and 1 then
  begin
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
  end;
  if options and 2 then
  begin
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $68;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
  end;
  if options and 4 then
  begin
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $7A;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7E;
   Inc(j);
   bufferU[j] := $00;
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
  z := 0;
  while (z < 64 - 1) and (bufferI[z] <> $48) do
  begin
   Inc(z);
  end;
  signature[0] := bufferI[z + 1];
  z := 2;
  while (z < 64 - 1) and (bufferI[z] <> $48) do
  begin
   Inc(z);
  end;
  signature[1] := bufferI[z + 1];
  z := 2;
  while (z < 64 - 1) and (bufferI[z] <> $48) do
  begin
   Inc(z);
  end;
  signature[2] := bufferI[z + 1];
  sprintf(str, 'CHIP ID:%02X%02X%02X' + #13 + '' + NL + '', signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  if options and 1 then
  begin
   z := 2;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   sprintf(str, 'LOCK byte:' + #9 + '  0x%02X' + #13 + '' + NL + '', bufferI[z + 1]);
   PrintMessage(str);
  end;
  if options and 2 then
  begin
   z := 2;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   sprintf(str, 'FUSE byte:' + #9 + '  0x%02X' + #13 + '' + NL + '', bufferI[z + 1]);
   PrintMessage(str);
  end;
  if options and 4 then
  begin
   z := 2;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   sprintf(str, 'FUSE HIGH byte:' + #9 + '  0x%02X' + #13 + '' + NL + '', bufferI[z + 1]);
   PrintMessage(str);
  end;
  if options and 8 then
  begin
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
  end;
  if options and 16 then
  begin
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $08;
   Inc(j);
   bufferU[j] := $0C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  PacketIO(2);
  z := 0;
  if options and 8 then
  begin
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   sprintf(str, 'Extended FUSE byte: 0x%02X' + #13 + '' + NL + '', bufferI[z + 1]);
   PrintMessage(str);
   z := z + 2;
  end;
  if options and 16 then
  begin
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   sprintf(str, 'Calibration byte: 0x%02X' + #13 + '' + NL + '', bufferI[z + 1]);
   PrintMessage(str);
  end;
  if saveLog then
   fprintf(logfile, 'READ CODE' + NL + '');
  PrintMessage(strings[S_CodeReading1]);
  j := 0;
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $02;
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
  i := 0;
  while i < dim do
  begin
   if i and 511 = 0 then
   begin
    bufferU[j] := $48;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := $1C;
    Inc(j);
    bufferU[j] := i shr 9;
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
   end;
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $0C;
   Inc(j);
   bufferU[j] := (i shr 1) and $FF;
   Inc(j);
   bufferU[j] := $68;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   i := i + 2;
   if (j > 64 - 14) or (i >= dim - 2) then
   begin
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    for z := 0 to (64 - 1) - 1 do
    begin
     if bufferI[z] = $48 then
     begin
      memCODE[k] := bufferI[z + 1];
      Inc(k);
      z := z + 1;
     end;
    end;
    sprintf(str, strings[S_CodeReading], (i * 100) div (dim + dim2), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if dim2 then
  begin
   if saveLog then
    fprintf(logfile, 'READ EEPROM' + NL + '');
   PrintMessage(strings[S_ReadEE]);
   j := 0;
   k := 0;
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $03;
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
   for i := 0 to (dim2) - 1 do
   begin
    if i and 255 = 0 then
    begin
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 1;
     Inc(j);
     bufferU[j] := $1C;
     Inc(j);
     bufferU[j] := i shr 8;
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
    end;
    bufferU[j] := $48;
    Inc(j);
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := $0C;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
    bufferU[j] := $68;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $6C;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    if (j > 64 - 8) or (i >= dim2 - 2) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     for z := 0 to (64 - 1) - 1 do
     begin
      if bufferI[z] = $48 then
      begin
       memEE[k] := bufferI[z + 1];
       Inc(k);
       z := z + 1;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (i * 100) div (dim + dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
    end;
   end;
   if k <> dim2 then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadEEErr], dim2, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $0E;
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
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  PrintMessage(strings[S_CodeMem]);
  DisplayCODEAVR(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  Tbyte: Double;
  signature: array of TBYTE;
  start: Cardinal;
  errEE: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  signature := [0, 0, 0];
  if (dim > $8000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'WriteAT(0x%X,0x%X)' + NL + '', dim, dim2);
  end;
  if dim > size then
   dim := size;
  if dim2 > sizeEE then
   dim2 := sizeEE;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $06;
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
  Tbyte := SyncSPI();
  if Tbyte = 0 then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  j := 0;
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $30;
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
  PacketIO(1 + 3 * 4 * Tbyte);
  z := 0;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[0] := bufferI[z + 2];
  z := 3;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[1] := bufferI[z + 2];
  z := 3;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[2] := bufferI[z + 2];
  sprintf(str, 'CHIP ID:%02X%02X%02X' + #13 + '' + NL + '', signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $AC;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1 + 4 * Tbyte);
  msDelay(25);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  j := 0;
  for i := 0 to (dim) - 1 do
  begin
   if memCODE[i] <> $FF then
   begin
    bufferU[j] := $31;
    Inc(j);
    bufferU[j] := 4;
    Inc(j);
    bufferU[j] := $40 + IfThen(i and 1, 8, 0);
    Inc(j);
    bufferU[j] := i shr 9;
    Inc(j);
    bufferU[j] := i shr 1;
    Inc(j);
    bufferU[j] := memCODE[i];
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $31;
    Inc(j);
    bufferU[j] := 3;
    Inc(j);
    bufferU[j] := $20 + IfThen(i and 1, 8, 0);
    Inc(j);
    bufferU[j] := i shr 9;
    Inc(j);
    bufferU[j] := i shr 1;
    Inc(j);
    bufferU[j] := $30;
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
    j := 0;
    PacketIO(7 + 2 * 4 * Tbyte);
    sprintf(str, strings[S_CodeWriting], (i * 100) div dim, i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    z := 0;
    while (z < 64 - 2) and (bufferI[z] <> $30) do
    begin
     Inc(z);
    end;
    if (z = 64 - 2) or (memCODE[i] <> bufferI[z + 2]) then
    begin
     Inc(err);
    end;
    if max_err and (err > max_err) then
    begin
     sprintf(str, strings[S_MaxErr], err);
     PrintMessage(str);
     PrintMessage(strings[S_IntW]);
     i := dim;
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   errEE := 0;
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if memEE[i] <> $FF then
    begin
     bufferU[j] := $31;
     Inc(j);
     bufferU[j] := 4;
     Inc(j);
     bufferU[j] := $C0;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := i;
     Inc(j);
     bufferU[j] := memEE[i];
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $31;
     Inc(j);
     bufferU[j] := 3;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := i;
     Inc(j);
     bufferU[j] := $30;
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
     j := 0;
     PacketIO(7 + 2 * 4 * Tbyte);
     sprintf(str, strings[S_CodeWriting], (i * 100) div dim2, i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     z := 0;
     while (z < 64 - 2) and (bufferI[z] <> $30) do
     begin
      Inc(z);
     end;
     if (z = 64 - 2) or (memEE[i] <> bufferI[z + 2]) then
     begin
      Inc(errEE);
     end;
     if max_err and (err + errEE > max_err) then
     begin
      sprintf(str, strings[S_MaxErr], err + errEE);
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim2;
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end;
  if AVRlock < $100 then
  begin
   PrintMessage(strings[S_FuseAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_FuseAreaW]);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $F9 + AVRlock and $06;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(3 + 4 * Tbyte);
   msDelay(15);
   PrintMessage(strings[S_Compl]);
  end;
  bufferU[j] := $35;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $0E;
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
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  Tbyte: Double;
  err: Integer;
  Rtry: Integer;
  maxTry: Integer;
  signature: array of TBYTE;
  start: Cardinal;
  w: Integer;
  v: Integer;
  c: Integer;
  errEE: Integer;
  err_f: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  Rtry := 0;
  maxTry := 0;
  signature := [0, 0, 0];
  if (dim > $20000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $1000) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'WriteATmega(0x%X,0x%X,0x%X,0x%X)' + NL + '', dim, dim2, page, options);
  end;
  if dim > size then
   dim := size
  else
  begin
   size := dim;
   memCODE := realloc(memCODE, dim);
  end;
  if size mod (page * 2) then
  begin
   j := size;
   dim := (j div (page * 2) + 1) * page * 2;
   memCODE := realloc(memCODE, dim);
   while j < dim do
   begin
    memCODE[j] := $FF;
    Inc(j);
   end;
  end;
  if dim2 > sizeEE then
   dim2 := sizeEE;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $06;
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
  Tbyte := SyncSPI();
  if Tbyte = 0 then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  j := 0;
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $30;
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
  PacketIO(1.5 + 3 * 4.5 * Tbyte);
  if saveLog then
   WriteLogIO();
  z := 0;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[0] := bufferI[z + 2];
  z := 3;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[1] := bufferI[z + 2];
  z := 3;
  while (z < 64 - 2) and (bufferI[z] <> $30) do
  begin
   Inc(z);
  end;
  signature[2] := bufferI[z + 2];
  sprintf(str, 'CHIP ID:%02X%02X%02X' + #13 + '' + NL + '', signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $AC;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 5000 shr 8;
  Inc(j);
  bufferU[j] := 5000 and $ff;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1 + 4 * Tbyte);
  msDelay(15);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  w := 0;
  i := 0;
  while i < dim do
  begin
   v := 0;
   for z := i to (i + page * 2) - 1 do
   begin
    if memCODE[z] < $FF then
     v := 1;
   end;
   if v then
   begin
    j := 0;
    v := 0;
    k := 0;
    while k < page do
    begin
     w := IfThen(page - k < (64 - 6) div 2, page - k, (64 - 6) div 2);
     bufferU[j] := $34;
     Inc(j);
     bufferU[j] := w;
     Inc(j);
     bufferU[j] := k shr 8;
     Inc(j);
     bufferU[j] := k;
     Inc(j);
     for z := 0 to (w * 2) - 1 do
     begin
      bufferU[j] := memCODE[i + k * 2 + z];
      Inc(j);
     end;
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     PacketIO(1.5 + w * 9 * Tbyte);
     Inc(k, w);
    end;
    bufferU[j] := $31;
    Inc(j);
    bufferU[j] := 4;
    Inc(j);
    bufferU[j] := $4C;
    Inc(j);
    bufferU[j] := i shr 9;
    Inc(j);
    bufferU[j] := i shr 1;
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    j := 0;
    PacketIO(6 + 4 * Tbyte);
    sprintf(str, strings[S_CodeWriting], (i * 100) div dim, i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    if RWstop then
     i := dim;
    c := (64 - 5) div 2;
    j := 0;
    k := 0;
    while k < page do
    begin
     for Rtry := 0 to (5) - 1 do
     begin
      bufferU[j] := $33;
      Inc(j);
      bufferU[j] := IfThen(k < page - c, c, page - k);
      Inc(j);
      bufferU[j] := (i + k * 2) shr 9;
      Inc(j);
      bufferU[j] := (i + k * 2) shr 1;
      Inc(j);
      bufferU[j] := $04;
      Inc(j);
      while j < 64 do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(1.5 + 240 * Tbyte);
      if bufferI[0] = $33 then
      begin
       w := 0;
       z := 2;
       while (z < bufferI[1] * 2 + 2) and (z < 64) do
       begin
        if memCODE[i + k * 2 + w] <> bufferI[z] then
        begin
         if Rtry < 4 then
          z := 64
         else
          Inc(err);
        end;
        Inc(w);
        Inc(z);
       end;
       if z < 64 then
        Rtry := 100;
      end;
      j := 0;
     end;
     Inc(k, c);
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, w, w, err);
    end;
    if max_err and (err > max_err) then
    begin
     sprintf(str, strings[S_MaxErr], err);
     PrintMessage(str);
     PrintMessage(strings[S_IntW]);
     i := dim;
    end;
   end;
   Inc(i, page * 2);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   errEE := 0;
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if memEE[i] <> $FF then
    begin
     bufferU[j] := $31;
     Inc(j);
     bufferU[j] := 4;
     Inc(j);
     bufferU[j] := $C0;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := i;
     Inc(j);
     bufferU[j] := memEE[i];
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $31;
     Inc(j);
     bufferU[j] := 3;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := i;
     Inc(j);
     bufferU[j] := $30;
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
     j := 0;
     PacketIO(11 + 8.5 * Tbyte);
     sprintf(str, strings[S_CodeWriting], (i * 100) div dim2, i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     z := 0;
     while (z < 64 - 2) and (bufferI[z] <> $30) do
     begin
      Inc(z);
     end;
     if (z = 64 - 2) or (memEE[i] <> bufferI[z + 2]) then
     begin
      if Rtry < 4 then
      begin
       Inc(Rtry);
       if Rtry > maxTry then
        maxTry := Rtry;
       Dec(i);
      end
      else
      begin
       Inc(errEE);
       Rtry := 0;
      end;
     end;
     if max_err and (err + errEE > max_err) then
     begin
      sprintf(str, strings[S_MaxErr], err + errEE);
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim2;
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end;
  err_f := 0;
  if (AVRlock < $100) or (AVRfuse < $100) or (AVRfuse_h < $100) or (AVRfuse_x < $100) then
  begin
   PrintMessage(strings[S_FuseAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_FuseAreaW]);
  end;
  if AVRfuse < $100 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := AVRfuse;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $50;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
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
   j := 0;
   PacketIO(6 + 8.5 * Tbyte);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   if (z = 64 - 2) or (AVRfuse <> bufferI[z + 2]) then
    Inc(err_f);
  end;
  if AVRfuse_h < $100 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $A8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := AVRfuse_h;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
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
   j := 0;
   PacketIO(6 + 8.5 * Tbyte);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   if (z = 64 - 2) or (AVRfuse_h <> bufferI[z + 2]) then
    Inc(err_f);
  end;
  if AVRfuse_x < $100 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $A4;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := AVRfuse_x;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $50;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
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
   j := 0;
   PacketIO(6 + 8.5 * Tbyte);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   if (z = 64 - 2) or (AVRfuse_x <> bufferI[z + 2]) then
    Inc(err_f);
  end;
  if AVRlock < $100 then
  begin
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $AC;
   Inc(j);
   bufferU[j] := $E0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := AVRlock;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $31;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := 0;
   Inc(j);
   bufferU[j] := $30;
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
   j := 0;
   PacketIO(6 + 8.5 * Tbyte);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $30) do
   begin
    Inc(z);
   end;
   if (z = 64 - 2) or (AVRlock <> bufferI[z + 2]) then
    Inc(err_f);
  end;
  err := err + err_f;
  if (AVRlock < $100) or (AVRfuse < $100) or (AVRfuse_h < $100) or (AVRfuse_x < $100) then
  begin
   sprintf(str, strings[S_ComplErr], err_f);
   PrintMessage(str);
  end;
  bufferU[j] := $35;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $31;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
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
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  t: Integer;
  sdo: Integer;
  err: Integer;
  signature: array of TBYTE;
  start: Cardinal;
  currPage: Integer;
  m: Integer;
  errEE: Integer;
  err_f: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  signature := [0, 0, 0];
  if FWVersion < $900 then
  begin
   sprintf(str, strings[S_FWver2old], '0.9.0');
   PrintMessage(str);
   Exit;
  end;
  if (dim > $10000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'WriteAT_HV(0x%X,0x%X,0x%X,0x%X)' + NL + '', dim, dim2, page, options);
  end;
  if dim > size then
   dim := size
  else
  begin
   size := dim;
   memCODE := realloc(memCODE, dim);
  end;
  if page and (size mod (page * 2)) then
  begin
   j := size;
   dim := (j div (page * 2) + 1) * page * 2;
   memCODE := realloc(memCODE, dim);
   while j < dim do
   begin
    memCODE[j] := $FF;
    Inc(j);
   end;
  end;
  if dim2 > sizeEE then
   dim2 := sizeEE;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  if not (StartHVReg(12)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $FC;
  Inc(j);
  bufferU[j] := $7;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $8;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $7;
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
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $68;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $01;
  Inc(j);
  bufferU[j] := $68;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $68;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(8);
  z := 0;
  while (z < 64 - 1) and (bufferI[z] <> $48) do
  begin
   Inc(z);
  end;
  signature[0] := bufferI[z + 1];
  z := 2;
  while (z < 64 - 1) and (bufferI[z] <> $48) do
  begin
   Inc(z);
  end;
  signature[1] := bufferI[z + 1];
  z := 2;
  while (z < 64 - 1) and (bufferI[z] <> $48) do
  begin
   Inc(z);
  end;
  signature[2] := bufferI[z + 1];
  sprintf(str, 'CHIP ID:%02X%02X%02X' + #13 + '' + NL + '', signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  if saveLog then
   fprintf(logfile, 'CHIP ERASE' + NL + '');
  j := 0;
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := 3;
  Inc(j);
  bufferU[j] := $4C;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $64;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $6C;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $46;
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
  bufferU[j] := $46;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  t := 0;
  sdo := 0;
  while (t < 20) and (sdo = 0) do
  begin
   PacketIO(2);
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $46) do
   begin
    Inc(z);
   end;
   sdo := bufferI[z + 1] and 2;
   Inc(t);
  end;
  if (sdo = 0) and saveLog then
   fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, 'WRITE CODE' + NL + '');
  currPage := -1;
  j := 0;
  if page = 0 then
  begin
   k := 0;
   i := 0;
   while i < dim do
   begin
    if (memCODE[i] <> $FF) or (memCODE[i + 1] <> $FF) then
    begin
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 6;
     Inc(j);
     bufferU[j] := $4C;
     Inc(j);
     bufferU[j] := $10;
     Inc(j);
     bufferU[j] := $1C;
     Inc(j);
     bufferU[j] := i shr 9;
     Inc(j);
     bufferU[j] := $0C;
     Inc(j);
     bufferU[j] := (i div 2) and $FF;
     Inc(j);
     bufferU[j] := $2C;
     Inc(j);
     bufferU[j] := memCODE[i];
     Inc(j);
     bufferU[j] := $64;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $6C;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $46;
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
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[j] := $46;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     t := 0;
     sdo := 0;
     while (t < 20) and (sdo = 0) do
     begin
      PacketIO(2);
      z := 0;
      while (z < 64 - 1) and (bufferI[z] <> $46) do
      begin
       Inc(z);
      end;
      sdo := bufferI[z + 1] and 2;
      Inc(t);
     end;
     if saveLog and (sdo = 0) then
      fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 3;
     Inc(j);
     bufferU[j] := $3C;
     Inc(j);
     bufferU[j] := memCODE[i + 1];
     Inc(j);
     bufferU[j] := $74;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $7C;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $46;
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
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[j] := $46;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     t := 0;
     sdo := 0;
     while (t < 20) and (sdo = 0) do
     begin
      PacketIO(2);
      z := 0;
      while (z < 64 - 1) and (bufferI[z] <> $46) do
      begin
       Inc(z);
      end;
      sdo := bufferI[z + 1] and 2;
      Inc(t);
     end;
     if saveLog and (sdo = 0) then
      fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
     sprintf(str, strings[S_CodeWriting], (i * 100) div dim, i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 3;
     Inc(j);
     bufferU[j] := $4C;
     Inc(j);
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $68;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $6C;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := $78;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $7C;
     Inc(j);
     bufferU[j] := $00;
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
     k := i;
     for z := 0 to (64 - 1) - 1 do
     begin
      if bufferI[z] = $48 then
      begin
       if memCODE[k] <> bufferI[z + 1] then
       begin
        sprintf(str, strings[S_CodeVError], k, k, memCODE[k], bufferI[z + 1]);
        PrintMessage(str);
        Inc(err);
       end;
       Inc(k);
       Inc(z);
      end;
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
     if max_err and (err > max_err) then
     begin
      sprintf(str, strings[S_MaxErr], err);
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim;
     end;
    end;
    Inc(i, 2);
   end;
  end
  else
  begin
   i := 0;
   while i < dim do
   begin
    for k := 0 to (page) - 1 do
    begin
     if (memCODE[i + k * 2] <> $FF) or (memCODE[i + k * 2 + 1] <> $FF) then
      k := page;
    end;
    if k > page then
    begin
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 1;
     Inc(j);
     bufferU[j] := $4C;
     Inc(j);
     bufferU[j] := $10;
     Inc(j);
     for k := 0 to (page) - 1 do
     begin
      bufferU[j] := $48;
      Inc(j);
      bufferU[j] := 5;
      Inc(j);
      bufferU[j] := $0C;
      Inc(j);
      bufferU[j] := (i div 2 + k) and $FF;
      Inc(j);
      bufferU[j] := $2C;
      Inc(j);
      bufferU[j] := memCODE[i + k * 2];
      Inc(j);
      bufferU[j] := $3C;
      Inc(j);
      bufferU[j] := memCODE[i + k * 2 + 1];
      Inc(j);
      bufferU[j] := $7D;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      bufferU[j] := $7C;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      if (j > 64 - 13) or (k >= page) or (i >= dim - 2) then
      begin
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
       begin
        fprintf(logfile, strings[S_Log7], i, i, k, k);
       end;
      end;
     end;
     if (i shr 9) <> currPage then
     begin
      bufferU[j] := $48;
      Inc(j);
      bufferU[j] := 1;
      Inc(j);
      bufferU[j] := $1C;
      Inc(j);
      bufferU[j] := i shr 9;
      Inc(j);
      currPage := i shr 9;
     end;
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := $64;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $6C;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $46;
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
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[j] := $46;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     t := 0;
     sdo := 0;
     while (t < 20) and (sdo = 0) do
     begin
      PacketIO(2);
      z := 0;
      while (z < 64 - 1) and (bufferI[z] <> $46) do
      begin
       Inc(z);
      end;
      sdo := bufferI[z + 1] and 2;
      Inc(t);
     end;
     if (sdo = 0) and saveLog then
      fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
     sprintf(str, strings[S_CodeWriting], (i * 100) div dim, i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     m := 0;
     for k := 0 to (page) - 1 do
     begin
      if k = 0 then
      begin
       bufferU[j] := $48;
       Inc(j);
       bufferU[j] := 4;
       Inc(j);
       bufferU[j] := $4C;
       Inc(j);
       bufferU[j] := $02;
       Inc(j);
      end
      else
      begin
       bufferU[j] := $48;
       Inc(j);
       bufferU[j] := 3;
       Inc(j);
      end;
      bufferU[j] := $0C;
      Inc(j);
      bufferU[j] := (i div 2 + k) and $FF;
      Inc(j);
      bufferU[j] := $68;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      bufferU[j] := $6C;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      bufferU[j] := $48;
      Inc(j);
      bufferU[j] := 2;
      Inc(j);
      bufferU[j] := $78;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      bufferU[j] := $7C;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      if (j > 64 - 14) or (k >= page) or (i >= dim - 2) then
      begin
       bufferU[j] := $04;
       Inc(j);
       while j < 64 do
       begin
        bufferU[j] := $0;
        Inc(j);
       end;
       PacketIO(2);
       j := 0;
       for z := 0 to (64 - 1) - 1 do
       begin
        if bufferI[z] = $48 then
        begin
         if memCODE[i + m] <> bufferI[z + 1] then
         begin
          sprintf(str, strings[S_CodeVError], i + m, i + m, memCODE[i + m], bufferI[z + 1]);
          PrintMessage(str);
          Inc(err);
         end;
         Inc(m);
         Inc(z);
        end;
       end;
       if saveLog then
       begin
        fprintf(logfile, strings[S_Log8], i, i, m, m, err);
       end;
       if max_err and (err > max_err) then
       begin
        sprintf(str, strings[S_MaxErr], err);
        PrintMessage(str);
        PrintMessage(strings[S_IntW]);
        i := dim;
       end;
      end;
     end;
    end;
    Inc(i, page * 2);
   end;
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   errEE := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, 'WRITE EEPROM' + NL + '');
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if memEE[i] <> $FF then
    begin
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 7;
     Inc(j);
     bufferU[j] := $4C;
     Inc(j);
     bufferU[j] := $11;
     Inc(j);
     bufferU[j] := $0C;
     Inc(j);
     bufferU[j] := i and $FF;
     Inc(j);
     bufferU[j] := $1C;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := $2C;
     Inc(j);
     bufferU[j] := memEE[i];
     Inc(j);
     bufferU[j] := $6D;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $64;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $6C;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $46;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     PacketIO(2);
     sprintf(str, strings[S_CodeWriting], (i * 100) div dim2, i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[j] := $46;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     t := 0;
     sdo := 0;
     while (t < 20) and (sdo = 0) do
     begin
      PacketIO(2);
      z := 0;
      while (z < 64 - 1) and (bufferI[z] <> $46) do
      begin
       Inc(z);
      end;
      sdo := bufferI[z + 1] and 2;
      Inc(t);
     end;
     if (sdo = 0) and saveLog then
      fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
     bufferU[j] := $48;
     Inc(j);
     bufferU[j] := 5;
     Inc(j);
     bufferU[j] := $4C;
     Inc(j);
     bufferU[j] := $03;
     Inc(j);
     bufferU[j] := $1C;
     Inc(j);
     bufferU[j] := i shr 8;
     Inc(j);
     bufferU[j] := $0C;
     Inc(j);
     bufferU[j] := i and $FF;
     Inc(j);
     bufferU[j] := $68;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $6C;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     z := 0;
     while (z < 64 - 1) and (bufferI[z] <> $48) do
     begin
      Inc(z);
     end;
     if memEE[i] <> bufferI[z + 1] then
     begin
      sprintf(str, strings[S_CodeVError], i, i, memEE[i], bufferI[z + 1]);
      PrintMessage(str);
      Inc(errEE);
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
     if err + errEE >= max_err then
      Break;
    end;
   end;
   err := err + errEE;
   if err >= max_err then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_MaxErr], err);
    PrintMessage(str);
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
  end;
  err_f := 0;
  if (AVRlock < $100) or (AVRfuse < $100) or (AVRfuse_h < $100) or (AVRfuse_x < $100) then
   PrintMessage(strings[S_FuseAreaW]);
  if AVRfuse < $100 then
  begin
   if saveLog then
    fprintf(logfile, 'WRITE FUSE' + NL + '');
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $2C;
   Inc(j);
   bufferU[j] := AVRfuse;
   Inc(j);
   bufferU[j] := $64;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $46) do
   begin
    Inc(z);
   end;
   sdo := bufferI[z + 1] and 2;
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   i := 0;
   while (i < 20) and (sdo = 0) do
   begin
    PacketIO(2);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $46) do
    begin
     Inc(z);
    end;
    sdo := bufferI[z + 1] and 2;
    Inc(i);
   end;
   if (sdo = 0) and saveLog then
    fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
   j := 0;
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $68;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6C;
   Inc(j);
   bufferU[j] := $00;
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
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   if (z = 64 - 1) or (AVRfuse <> bufferI[z + 1]) then
   begin
    sprintf(str, strings[S_WErr1], 'fuse', AVRfuse, bufferI[z + 1]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  if AVRfuse_h < $100 then
  begin
   if saveLog then
    fprintf(logfile, 'WRITE FUSEH' + NL + '');
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $2C;
   Inc(j);
   bufferU[j] := AVRfuse_h;
   Inc(j);
   bufferU[j] := $74;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $46) do
   begin
    Inc(z);
   end;
   sdo := bufferI[z + 1] and 2;
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   i := 0;
   while (i < 20) and (sdo = 0) do
   begin
    PacketIO(2);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $46) do
    begin
     Inc(z);
    end;
    sdo := bufferI[z + 1] and 2;
    Inc(i);
   end;
   if (sdo = 0) and saveLog then
    fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
   j := 0;
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $7A;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7E;
   Inc(j);
   bufferU[j] := $00;
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
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   if (z = 64 - 1) or (AVRfuse_h <> bufferI[z + 1]) then
   begin
    sprintf(str, strings[S_WErr1], 'fuseH', AVRfuse_h, bufferI[z + 1]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  if AVRfuse_x < $100 then
  begin
   if saveLog then
    fprintf(logfile, 'WRITE FUSEX' + NL + '');
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $40;
   Inc(j);
   bufferU[j] := $2C;
   Inc(j);
   bufferU[j] := AVRfuse_x;
   Inc(j);
   bufferU[j] := $66;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $46) do
   begin
    Inc(z);
   end;
   sdo := bufferI[z + 1] and 2;
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   i := 0;
   while (i < 20) and (sdo = 0) do
   begin
    PacketIO(2);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $46) do
    begin
     Inc(z);
    end;
    sdo := bufferI[z + 1] and 2;
    Inc(i);
   end;
   if (sdo = 0) and saveLog then
    fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
   j := 0;
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $00;
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
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   if (z = 64 - 1) or (AVRfuse_x <> bufferI[z + 1]) then
   begin
    sprintf(str, strings[S_WErr1], 'fuseX', AVRfuse_x, bufferI[z + 1]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  if AVRlock < $100 then
  begin
   if saveLog then
    fprintf(logfile, 'WRITE LOCK' + NL + '');
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $2C;
   Inc(j);
   bufferU[j] := AVRlock;
   Inc(j);
   bufferU[j] := $64;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $6C;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $46) do
   begin
    Inc(z);
   end;
   sdo := bufferI[z + 1] and 2;
   bufferU[j] := $46;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   i := 0;
   while (i < 20) and (sdo = 0) do
   begin
    PacketIO(2);
    z := 0;
    while (z < 64 - 1) and (bufferI[z] <> $46) do
    begin
     Inc(z);
    end;
    sdo := bufferI[z + 1] and 2;
    Inc(i);
   end;
   if (sdo = 0) and saveLog then
    fprintf(logfile, 'SDO=0' + #13 + '' + NL + '');
   j := 0;
   bufferU[j] := $48;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   bufferU[j] := $4C;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $7C;
   Inc(j);
   bufferU[j] := $00;
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
   z := 0;
   while (z < 64 - 1) and (bufferI[z] <> $48) do
   begin
    Inc(z);
   end;
   if (z = 64 - 1) or (AVRlock <> bufferI[z + 1]) then
   begin
    sprintf(str, strings[S_WErr1], 'lock', AVRlock, bufferI[z + 1]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  err := err + err_f;
  if (AVRlock < $100) or (AVRfuse < $100) or (AVRfuse_h < $100) or (AVRfuse_x < $100) then
  begin
   sprintf(str, strings[S_ComplErr], err_f);
   PrintMessage(str);
  end;
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $0E;
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
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop - start) div 1000.0, err, IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

end.

unit progp24;

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
  PIC24LIST: array of TID24;

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
function CheckData(a: Integer; b: Integer; addr: Integer; err: ^Integer): Pointer;
function PIC24_ID(id: Integer): Pointer;
function DisplayCODE24F(dim: Integer): Pointer;
procedure DisplayEE24F;
function Read24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
function Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
function Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
function Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;

implementation

function CheckData(a: Integer; b: Integer; addr: Integer; err: ^Integer): Pointer;
var
  // (no local variables detected)
begin
  if a <> b then
  begin
   PrintMessage(strings[S_NL]);
   sprintf(str, strings[S_CodeVError], addr, addr, a, b);
   PrintMessage(str);
   Inc(err^);
  end;
end;

function PIC24_ID(id: Integer): Pointer;
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (SizeOf(PIC24LIST) div SizeOf(PIC24LIST[0])) - 1 do
  begin
   if id = PIC24LIST[i].id then
   begin
    strcpy(s, PIC24LIST[i].device);
    strcat(s, '' + #13 + '' + NL + '');
    PrintMessage(s);
    Exit;
   end;
  end;
  PrintMessage(strings[S_nodev]);
end;

function DisplayCODE24F(dim: Integer): Pointer;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  d: Integer;
  lines: Integer;
begin
  s := '';
  t := '';
  aux := malloc((dim div 16 + 1) * 2 * (16 + 16 * 9));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  i := 0;
  while (i < dim) and (i < size) do
  begin
   valid := 0;
   j := i;
   while (j < i + 16 * 2) and (j < dim) do
   begin
    d := (memCODE[j + 3] shl 24) + (memCODE[j + 2] shl 16) + (memCODE[j + 1] shl 8) + memCODE[j];
    sprintf(t, '%08X ', d);
    strcat(s, t);
    if d <> $ffffffff then
     valid := 1;
    Inc(j, 4);
   end;
   if valid then
   begin
    sprintf(t, '%06X: %s' + #13 + '' + NL + '', i div 2, s);
    empty := 0;
    strcat(aux, t);
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

procedure DisplayEE24F;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  v: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
begin
  valid := 0;
  empty := 1;
  s[0] := 0;
  v[0] := 0;
  aux := malloc(($1000 div 16) * (16 + 16 * 5));
  aux[0] := 0;
  i := 0;
  while (i < $1000) and (i < sizeEE) do
  begin
   valid := 0;
   j := i;
   while (j < i + 16) and (j < $1000) and (i < sizeEE) do
   begin
    sprintf(t, '%02X %02X ', memEE[j], memEE[j + 1]);
    strcat(s, t);
    sprintf(t, '%c', IfThen(isprint(memEE[j]) and (memEE[j] < $FF), memEE[j], #46));
    strcat(v, t);
    if memEE[j] < $ff then
     valid := 1;
    sprintf(t, '%c', IfThen(isprint(memEE[j + 1]) and (memEE[j + 1] < $FF), memEE[j + 1], #46));
    strcat(v, t);
    if memEE[j + 1] < $ff then
     valid := 1;
    Inc(j, 2);
   end;
   if valid then
   begin
    sprintf(t, '%04X: %s %s' + #13 + '' + NL + '', i + $F000, s, v);
    strcat(aux, t);
    empty := 0;
   end;
   s[0] := 0;
   v[0] := 0;
   Inc(i, 16);
  end;
  if empty then
   PrintMessage(strings[S_Empty])
  else
   PrintMessage(aux);
  free(aux);
end;

function Read24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  entry: Integer;
  config: Integer;
  EEbaseAddr: Integer;
  newTABLPAG: Integer;
  memExec: PByte;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  High: Integer;
  stop: Cardinal;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  d: Integer;
  valid: Integer;
  empty: Integer;
  aux: PChar;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := options and $F;
  config := (options shr 4) and $F;
  EEbaseAddr := $1000 - dim2;
  newTABLPAG := IfThen(options and $100, 1, 0);
  if FWVersion < $700 then
  begin
   sprintf(str, strings[S_FWver2old], '0.7.0');
   PrintMessage(str);
   Exit;
  end;
  if (entry < 2) and not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read24Fx(%d,%d,%d,%d,%d)    (0x%X,0x%X,0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options, appIDaddr, executiveArea, dim, dim2, options, appIDaddr, executiveArea);
  end;
  dim := dim * 2;
  if (dim > $80000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $4000) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  memExec := 0;
  executiveArea := executiveArea * 2;
  if executiveArea then
   memExec := malloc(executiveArea);
  for i := 0 to (executiveArea) - 1 do
  begin
   memExec[i] := $FF;
  end;
  size := dim;
  sizeEE := $1000;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  if memEE then
   free(memEE);
  memEE := malloc($1000);
  memset(memCODE, $FF, dim);
  memset(memEE, $FF, $1000);
  if config > 2 then
  begin
   sizeCONFIG := 48;
   for i := 0 to (48) - 1 do
   begin
    memCONFIG[i] := $FF;
   end;
  end;
  if (entry = 1) or (entry = 2) then
  begin
   if not (StartHVReg(IfThen(entry = 2, 12, 6))) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-1);
  start := GetTickCount();
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 10000 shr 8;
  Inc(j);
  bufferU[j] := 10000 and $ff;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $09;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  if (entry = 0) or (entry = 3) then
  begin
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
  end
  else
   PrintMessage(strings[S_HVICSP]);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $4D;
  Inc(j);
  bufferU[j] := $43;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := $51;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 30000 shr 8;
  Inc(j);
  bufferU[j] := 30000 and $ff;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  if entry = 2 then
  begin
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $5;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
  end;
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(55);
  j := 0;
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $78;
  Inc(j);
  bufferU[j] := $47;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
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
  w0 := 0;
  w1 := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w1 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'DevID: 0x%04X' + #13 + '' + NL + 'DevRev: 0x%04X' + #13 + '' + NL + '', w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $20 + (appIDaddr shr 12) and $F;
  Inc(j);
  bufferU[j] := (appIDaddr shr 4) and $FF;
  Inc(j);
  bufferU[j] := (appIDaddr shl 4) and $F0 + 6;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $78;
  Inc(j);
  bufferU[j] := $47;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $78;
  Inc(j);
  bufferU[j] := $47;
  Inc(j);
  bufferU[j] := $38;
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
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'ApplicationID @ 0x80%04X:  0x%04X' + #13 + '' + NL + '', appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_CodeReading1]);
  High := 0;
  i := 0;
  while i < dim do
  begin
   if (i shr 17) <> High then
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := (i shr 21) and $FF;
    Inc(j);
    bufferU[j] := (i shr 13) and $F0;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    if newTABLPAG then
    begin
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $01;
     Inc(j);
     bufferU[j] := $90;
     Inc(j);
    end;
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
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
    High := i shr 17;
   end;
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $D3;
   Inc(j);
   bufferU[j] := $D6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   if i < dim - 16 then
   begin
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
   end;
   if i < dim - 8 then
   begin
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
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
   z := 0;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 1] := bufferI[z + 1];
    memCODE[k] := bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 2] := bufferI[z + 2];
    memCODE[k + 6] := bufferI[z + 1];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 5] := bufferI[z + 1];
    memCODE[k + 4] := bufferI[z + 2];
    k := k + 8;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 1] := bufferI[z + 1];
    memCODE[k + 0] := bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 2] := bufferI[z + 2];
    memCODE[k + 6] := bufferI[z + 1];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 5] := bufferI[z + 1];
    memCODE[k + 4] := bufferI[z + 2];
    k := k + 8;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 1] := bufferI[z + 1];
    memCODE[k + 0] := bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 2] := bufferI[z + 2];
    memCODE[k + 6] := bufferI[z + 1];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 5] := bufferI[z + 1];
    memCODE[k + 4] := bufferI[z + 2];
    k := k + 8;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim, i div 2);
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
   Inc(i, 24);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if config > 2 then
  begin
   if saveLog then
    fprintf(logfile, '' + NL + 'CONFIG:' + NL + '');
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   if newTABLPAG then
   begin
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
   end
   else
   begin
    bufferU[j] := $01;
    Inc(j);
    bufferU[j] := $90;
    Inc(j);
   end;
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $47;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   z := 0;
   for i := 0 to (9) - 1 do
   begin
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    memCONFIG[i * 4] := bufferI[z + 2];
    memCONFIG[i * 4 + 1] := bufferI[z + 1];
    z := z + 3;
   end;
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   z := 0;
   for i := 9 to (12) - 1 do
   begin
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    memCONFIG[i * 4] := bufferI[z + 2];
    memCONFIG[i * 4 + 1] := bufferI[z + 1];
    z := z + 3;
   end;
   gtk_statusbar_push(status_bar, statusID, '');
  end;
  if dim2 then
  begin
   if saveLog then
    fprintf(logfile, '' + NL + 'EEPROM:' + NL + '');
   PrintMessage(strings[S_ReadEE]);
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := $45;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $07;
   Inc(j);
   bufferU[j] := $F0;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   if newTABLPAG then
   begin
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
   end
   else
   begin
    bufferU[j] := $01;
    Inc(j);
    bufferU[j] := $90;
    Inc(j);
   end;
   bufferU[j] := $2F;
   Inc(j);
   bufferU[j] := (EEbaseAddr shr 4) and $FF;
   Inc(j);
   bufferU[j] := EEbaseAddr and $F0 + 6;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $47;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   k2 := 0;
   i := 0;
   while i < dim2 do
   begin
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    if (j > 64 - 6) or (i = dim2 - 2) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
     for z := 0 to (64 - 2) - 1 do
     begin
      if bufferI[z] = $37 then
      begin
       memEE[EEbaseAddr + k2] := bufferI[z + 2];
       Inc(k2);
       memEE[EEbaseAddr + k2] := bufferI[z + 1];
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
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
    Inc(i, 2);
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
  if executiveArea then
  begin
   j := 0;
   PrintMessage(strings[S_Read_EXE_A]);
   if saveLog then
    fprintf(logfile, '' + NL + 'Executive area:' + NL + '');
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := $45;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $08;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   if newTABLPAG then
   begin
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
   end
   else
   begin
    bufferU[j] := $01;
    Inc(j);
    bufferU[j] := $90;
    Inc(j);
   end;
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $47;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
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
   k := 0;
   i := 0;
   while i < executiveArea do
   begin
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
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
    PacketIO(3);
    j := 0;
    z := 0;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 1] := bufferI[z + 1];
     memExec[k] := bufferI[z + 2];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 2] := bufferI[z + 2];
     memExec[k + 6] := bufferI[z + 1];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 5] := bufferI[z + 1];
     memExec[k + 4] := bufferI[z + 2];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 9] := bufferI[z + 1];
     memExec[k + 8] := bufferI[z + 2];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 10] := bufferI[z + 2];
     memExec[k + 14] := bufferI[z + 1];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 13] := bufferI[z + 1];
     memExec[k + 12] := bufferI[z + 2];
    end;
    k := k + 16;
    sprintf(str, strings[S_CodeReading2], (i * 100) div executiveArea, $800000 + i div 2);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
    Inc(i, 16);
   end;
   if k <> executiveArea then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadCodeErr2], executiveArea, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  PrintMessage('' + #13 + '' + NL + '');
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
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
  if config > 2 then
  begin
   PrintMessage(strings[S_ConfigMem]);
   if (config = 3) or (config = 4) or (config = 6) then
   begin
    sprintf(str, '0xF80000: FBS = 0x%02X' + #13 + '' + NL + '', memCONFIG[0]);
    PrintMessage(str);
    if config = 4 then
    begin
     sprintf(str, '0xF80002: FSS = 0x%02X' + #13 + '' + NL + '', memCONFIG[4]);
     PrintMessage(str);
    end;
    sprintf(str, '0xF80004: FGS = 0x%02X' + #13 + '' + NL + '', memCONFIG[8]);
    PrintMessage(str);
    sprintf(str, '0xF80006: FOSCSEL = 0x%02X' + #13 + '' + NL + '', memCONFIG[12]);
    PrintMessage(str);
    sprintf(str, '0xF80008: FOSC = 0x%02X' + #13 + '' + NL + '', memCONFIG[16]);
    PrintMessage(str);
    sprintf(str, '0xF8000A: FWDT = 0x%02X' + #13 + '' + NL + '', memCONFIG[20]);
    PrintMessage(str);
    sprintf(str, '0xF8000C: FPOR = 0x%02X' + #13 + '' + NL + '', memCONFIG[24]);
    PrintMessage(str);
    sprintf(str, '0xF8000E: FICD = 0x%02X' + #13 + '' + NL + '', memCONFIG[28]);
    PrintMessage(str);
    if config = 3 then
    begin
     sprintf(str, '0xF80010: FDS = 0x%02X' + #13 + '' + NL + '', memCONFIG[32]);
     PrintMessage(str);
    end
    else
     if config = 4 then
     begin
      sprintf(str, '0xF80010: UID0 = 0x%02X' + #13 + '' + NL + '', memCONFIG[32]);
      PrintMessage(str);
      sprintf(str, '0xF80012: UID1 = 0x%02X' + #13 + '' + NL + '', memCONFIG[36]);
      PrintMessage(str);
      sprintf(str, '0xF80014: UID2 = 0x%02X' + #13 + '' + NL + '', memCONFIG[40]);
      PrintMessage(str);
      sprintf(str, '0xF80016: UID3 = 0x%02X' + #13 + '' + NL + '', memCONFIG[44]);
      PrintMessage(str);
     end;
   end
   else
    if config = 5 then
    begin
     sprintf(str, '0xF80000: FOSC = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[1], memCONFIG[0]);
     PrintMessage(str);
     sprintf(str, '0xF80002: FWDT = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[5], memCONFIG[4]);
     PrintMessage(str);
     sprintf(str, '0xF80004: FBORPOR = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[9], memCONFIG[8]);
     PrintMessage(str);
     sprintf(str, '0xF80006: FBS = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[13], memCONFIG[12]);
     PrintMessage(str);
     sprintf(str, '0xF80008: FSS = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[17], memCONFIG[16]);
     PrintMessage(str);
     sprintf(str, '0xF8000A: FGS = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[21], memCONFIG[20]);
     PrintMessage(str);
     sprintf(str, '0xF8000C: FICD = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[25], memCONFIG[24]);
     PrintMessage(str);
    end;
  end
  else
  begin
   sprintf(str, 'CONFIG1: 0x%04X' + #13 + '' + NL + 'CONFIG2: 0x%04X' + #13 + '' + NL + '', (memCODE[dim - 3] shl 8) + memCODE[dim - 4], (memCODE[dim - 7] shl 8) + memCODE[dim - 8]);
   PrintMessage(str);
   if config = 1 then
   begin
    sprintf(str, 'CONFIG3: 0x%04X' + #13 + '' + NL + '', (memCODE[dim - 11] shl 8) + memCODE[dim - 12]);
    PrintMessage(str);
   end;
   if config = 2 then
   begin
    sprintf(str, 'CONFIG4: 0x%04X' + #13 + '' + NL + '', (memCODE[dim - 15] shl 8) + memCODE[dim - 16]);
    PrintMessage(str);
   end;
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE24F(dim);
  if dim2 then
  begin
   PrintMessage(strings[S_EEMem]);
   DisplayEE24F();
  end;
  if executiveArea then
  begin
   empty := 1;
   aux := malloc((dim div 16 + 1) * 2 * (16 + 16 * 9));
   aux[0] := 0;
   s[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ExeMem]);
   i := 0;
   while i < executiveArea do
   begin
    valid := 0;
    j := i;
    while (j < i + 16 * 2) and (j < executiveArea) do
    begin
     d := (memExec[j + 3] shl 24) + (memExec[j + 2] shl 16) + (memExec[j + 1] shl 8) + memExec[j];
     sprintf(t, '%08X ', d);
     strcat(s, t);
     if d <> $ffffffff then
      valid := 1;
     Inc(j, 4);
    end;
    if valid then
    begin
     sprintf(t, '%06X: %s' + #13 + '' + NL + '', i div 2, s);
     empty := 0;
     strcat(aux, t);
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
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  UID: array[0..16-1] of Byte;
  memExec: PByte;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  High: Integer;
  stop: Cardinal;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  d: Integer;
  valid: Integer;
  empty: Integer;
  aux: PChar;
begin
  k := 0;
  z := 0;
  for i := 0 to (16) - 1 do
  begin
   UID[i] := $FF;
  end;
  if FWVersion < $900 then
  begin
   sprintf(str, strings[S_FWver2old], '0.9.0');
   PrintMessage(str);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read24Ex(%d,%d,%d,%d,%d)    (0x%X,0x%X,0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options, appIDaddr, executiveArea, dim, dim2, options, appIDaddr, executiveArea);
  end;
  dim := dim * 2;
  if (dim > $100000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  memExec := 0;
  executiveArea := executiveArea * 2;
  if executiveArea then
   memExec := malloc(executiveArea);
  for i := 0 to (executiveArea) - 1 do
  begin
   memExec[i] := $FF;
  end;
  size := dim;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  memset(memCODE, $FF, dim);
  StartHVReg(-1);
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
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $09;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $4D;
  Inc(j);
  bufferU[j] := $43;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := $51;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 55000 shr 8;
  Inc(j);
  bufferU[j] := 55000 and $ff;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(65);
  j := 0;
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $87;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
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
  w0 := 0;
  w1 := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w1 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'DevID: 0x%04X' + #13 + '' + NL + 'DevRev: 0x%04X' + #13 + '' + NL + '', w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $20 + (appIDaddr shr 12) and $F;
  Inc(j);
  bufferU[j] := (appIDaddr shr 4) and $FF;
  Inc(j);
  bufferU[j] := (appIDaddr shl 4) and $F0 + 6;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $87;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $87;
  Inc(j);
  bufferU[j] := $38;
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
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'ApplicationID @ 0x80%04X:  0x%04X' + #13 + '' + NL + '', appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_CodeReading1]);
  High := 0;
  i := 0;
  while i < dim do
  begin
   if (i shr 17) <> High then
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := (i shr 21) and $FF;
    Inc(j);
    bufferU[j] := (i shr 13) and $F0;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $38;
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
    High := i shr 17;
   end;
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $D3;
   Inc(j);
   bufferU[j] := $D6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   if i < dim - 16 then
   begin
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
   end;
   if i < dim - 8 then
   begin
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(4);
   z := 0;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 1] := bufferI[z + 1];
    memCODE[k] := bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 2] := bufferI[z + 2];
    memCODE[k + 6] := bufferI[z + 1];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 5] := bufferI[z + 1];
    memCODE[k + 4] := bufferI[z + 2];
    k := k + 8;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 1] := bufferI[z + 1];
    memCODE[k + 0] := bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 2] := bufferI[z + 2];
    memCODE[k + 6] := bufferI[z + 1];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 5] := bufferI[z + 1];
    memCODE[k + 4] := bufferI[z + 2];
    k := k + 8;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 1] := bufferI[z + 1];
    memCODE[k + 0] := bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 2] := bufferI[z + 2];
    memCODE[k + 6] := bufferI[z + 1];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    memCODE[k + 5] := bufferI[z + 1];
    memCODE[k + 4] := bufferI[z + 2];
    k := k + 8;
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div dim, i div 2);
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
   Inc(i, 24);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if executiveArea then
  begin
   j := 0;
   PrintMessage(strings[S_Read_EXE_A]);
   if saveLog then
    fprintf(logfile, '' + NL + 'Executive area:' + NL + '');
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := $45;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $08;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $87;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
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
   k := 0;
   i := 0;
   while i < executiveArea do
   begin
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $96;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $DB;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $D3;
    Inc(j);
    bufferU[j] := $D6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $49;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(3);
    j := 0;
    z := 0;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 1] := bufferI[z + 1];
     memExec[k] := bufferI[z + 2];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 2] := bufferI[z + 2];
     memExec[k + 6] := bufferI[z + 1];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 5] := bufferI[z + 1];
     memExec[k + 4] := bufferI[z + 2];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 9] := bufferI[z + 1];
     memExec[k + 8] := bufferI[z + 2];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 10] := bufferI[z + 2];
     memExec[k + 14] := bufferI[z + 1];
    end;
    z := 3;
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    if z < 64 - 2 then
    begin
     memExec[k + 13] := bufferI[z + 1];
     memExec[k + 12] := bufferI[z + 2];
    end;
    k := k + 16;
    sprintf(str, strings[S_CodeReading2], (i * 100) div executiveArea, $800000 + i div 2);
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
    Inc(i, 16);
   end;
   if k <> executiveArea then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadCodeErr2], executiveArea, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  PrintMessage('' + #13 + '' + NL + '');
  j := 0;
  if saveLog then
   fprintf(logfile, '' + NL + 'User ID:' + NL + '');
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $45;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $86;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $87;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
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
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $DB;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $D3;
  Inc(j);
  bufferU[j] := $D6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $DB;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $D3;
  Inc(j);
  bufferU[j] := $D6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
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
  PacketIO(3);
  j := 0;
  k := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   UID[k + 1] := bufferI[z + 1];
   UID[k] := bufferI[z + 2];
  end;
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   UID[k + 2] := bufferI[z + 2];
   UID[k + 6] := bufferI[z + 1];
  end;
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   UID[k + 5] := bufferI[z + 1];
   UID[k + 4] := bufferI[z + 2];
  end;
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   UID[k + 9] := bufferI[z + 1];
   UID[k + 8] := bufferI[z + 2];
  end;
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   UID[k + 10] := bufferI[z + 2];
   UID[k + 14] := bufferI[z + 1];
  end;
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   UID[k + 13] := bufferI[z + 1];
   UID[k + 12] := bufferI[z + 2];
  end;
  PrintMessage('' + #13 + '' + NL + '');
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
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
  for i := 0 to (10) - 1 do
  begin
   sprintf(str, 'CONFIG%d(0x%05X): 0x%02X' + #13 + '' + NL + '', i, ((dim - 40) + i * 4) div 2, memCODE[(dim - 40) + i * 4]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE24F(dim);
  if executiveArea then
  begin
   empty := 1;
   aux := malloc((executiveArea div 16 + 1) * 2 * (16 + 16 * 9));
   aux[0] := 0;
   s[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ExeMem]);
   i := 0;
   while i < executiveArea do
   begin
    valid := 0;
    j := i;
    while (j < i + 16 * 2) and (j < executiveArea) do
    begin
     d := (memExec[j + 3] shl 24) + (memExec[j + 2] shl 16) + (memExec[j + 1] shl 8) + memExec[j];
     sprintf(t, '%08X ', d);
     strcat(s, t);
     if d <> $ffffffff then
      valid := 1;
     Inc(j, 4);
    end;
    if valid then
    begin
     sprintf(t, '%06X: %s' + #13 + '' + NL + '', i div 2, s);
     empty := 0;
     strcat(aux, t);
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
  for i := 0 to (4) - 1 do
  begin
   if (UID[i * 4] <> $FF) or (UID[i * 4 + 1] <> $FF) then
   begin
    sprintf(str, 'UserID%d=%04X', i, (UID[i * 4] shl 8) + UID[i * 4 + 1]);
    PrintMessage(str);
   end;
  end;
  sprintf(str, strings[S_End], (stop - start) div 1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  entry: Integer;
  config: Integer;
  EEbaseAddr: Integer;
  newTABLPAG: Integer;
  err: Integer;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  erase: Integer;
  valid: Integer;
  High: Integer;
  r0: Integer;
  r1: Integer;
  r2: Integer;
  r3: Integer;
  w3: Integer;
  w2: Integer;
  eewrite: Integer;
  errE: Integer;
  written: Integer;
  read_: Integer;
  confword: Integer;
  errC: Integer;
  Nconf: Integer;
  value: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := options and $F;
  config := (options shr 4) and $F;
  EEbaseAddr := $1000 - dim2;
  newTABLPAG := IfThen(options and $100000, 1, 0);
  err := 0;
  if FWVersion < $700 then
  begin
   sprintf(str, strings[S_FWver2old], '0.7.0');
   PrintMessage(str);
   Exit;
  end;
  if (entry < 2) and not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write24Fx(%d,%d,%d,%d,%d,%.1f)    (0x%X,0x%X,0x%X,0x%X,0x%X,%.3f)' + NL + '', dim, dim2, options, appIDaddr, rowSize, wait, dim, dim2, options, appIDaddr, rowSize, wait);
  end;
  dim := dim * 2;
  if (dim > $80000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $1000) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  j := size;
  if j mod (rowSize * 4) then
  begin
   size := (j div (rowSize * 4) + 1) * rowSize * 4;
   memCODE := realloc(memCODE, size);
   while j < size do
   begin
    memCODE[j] := $FF;
    Inc(j);
   end;
  end;
  if dim > size then
   dim := size;
  if sizeEE < $1000 then
   dim2 := 0;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  if (entry = 1) or (entry = 2) then
  begin
   if not (StartHVReg(IfThen(entry = 2, 12, 6))) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-1);
  if config > 2 then
  begin
   PrintMessage(strings[S_ConfigMem]);
   if (config = 3) or (config = 4) or (config = 6) then
   begin
    sprintf(str, '0xF80000: FBS = 0x%02X' + #13 + '' + NL + '', memCONFIG[0]);
    PrintMessage(str);
    if config = 4 then
    begin
     sprintf(str, '0xF80002: FSS = 0x%02X' + #13 + '' + NL + '', memCONFIG[4]);
     PrintMessage(str);
    end;
    sprintf(str, '0xF80004: FGS = 0x%02X' + #13 + '' + NL + '', memCONFIG[8]);
    PrintMessage(str);
    sprintf(str, '0xF80006: FOSCSEL = 0x%02X' + #13 + '' + NL + '', memCONFIG[12]);
    PrintMessage(str);
    sprintf(str, '0xF80008: FOSC = 0x%02X' + #13 + '' + NL + '', memCONFIG[16]);
    PrintMessage(str);
    sprintf(str, '0xF8000A: FWDT = 0x%02X' + #13 + '' + NL + '', memCONFIG[20]);
    PrintMessage(str);
    sprintf(str, '0xF8000C: FPOR = 0x%02X' + #13 + '' + NL + '', memCONFIG[24]);
    PrintMessage(str);
    sprintf(str, '0xF8000E: FICD = 0x%02X' + #13 + '' + NL + '', memCONFIG[28]);
    PrintMessage(str);
    if config = 3 then
    begin
     sprintf(str, '0xF80010: FDS = 0x%02X' + #13 + '' + NL + '', memCONFIG[32]);
     PrintMessage(str);
    end
    else
     if config = 4 then
     begin
      sprintf(str, '0xF80010: UID0 = 0x%02X' + #13 + '' + NL + '', memCONFIG[32]);
      PrintMessage(str);
      sprintf(str, '0xF80012: UID1 = 0x%02X' + #13 + '' + NL + '', memCONFIG[36]);
      PrintMessage(str);
      sprintf(str, '0xF80014: UID2 = 0x%02X' + #13 + '' + NL + '', memCONFIG[40]);
      PrintMessage(str);
      sprintf(str, '0xF80016: UID3 = 0x%02X' + #13 + '' + NL + '', memCONFIG[44]);
      PrintMessage(str);
     end;
   end
   else
    if config = 5 then
    begin
     sprintf(str, '0xF80000: FOSC = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[1], memCONFIG[0]);
     PrintMessage(str);
     sprintf(str, '0xF80002: FWDT = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[5], memCONFIG[4]);
     PrintMessage(str);
     sprintf(str, '0xF80004: FBORPOR = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[9], memCONFIG[8]);
     PrintMessage(str);
     sprintf(str, '0xF80006: FBS = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[13], memCONFIG[12]);
     PrintMessage(str);
     sprintf(str, '0xF80008: FSS = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[17], memCONFIG[16]);
     PrintMessage(str);
     sprintf(str, '0xF8000A: FGS = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[21], memCONFIG[20]);
     PrintMessage(str);
     sprintf(str, '0xF8000C: FICD = 0x%02X%02X' + #13 + '' + NL + '', memCONFIG[25], memCONFIG[24]);
     PrintMessage(str);
    end;
  end
  else
  begin
   sprintf(str, 'CONFIG1: 0x%04X' + #13 + '' + NL + 'CONFIG2: 0x%04X' + #13 + '' + NL + '', (memCODE[dim - 3] shl 8) + memCODE[dim - 4], (memCODE[dim - 7] shl 8) + memCODE[dim - 8]);
   PrintMessage(str);
   if config = 1 then
   begin
    sprintf(str, 'CONFIG3: 0x%04X' + #13 + '' + NL + '', (memCODE[dim - 11] shl 8) + memCODE[dim - 12]);
    PrintMessage(str);
   end;
   if config = 2 then
   begin
    sprintf(str, 'CONFIG4: 0x%04X' + #13 + '' + NL + '', (memCODE[dim - 15] shl 8) + memCODE[dim - 16]);
    PrintMessage(str);
   end;
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
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $09;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  if (entry = 0) or (entry = 3) then
  begin
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
  end
  else
   PrintMessage(strings[S_HVICSP]);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $4D;
  Inc(j);
  bufferU[j] := $43;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := $51;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 30000 shr 8;
  Inc(j);
  bufferU[j] := 30000 and $ff;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  if entry = 2 then
  begin
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $5;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $4;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
  end;
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
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
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $78;
  Inc(j);
  bufferU[j] := $47;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
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
  w0 := 0;
  w1 := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w1 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'DevID: 0x%04X' + #13 + '' + NL + 'DevRev: 0x%04X' + #13 + '' + NL + '', w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $20 + (appIDaddr shr 12) and $F;
  Inc(j);
  bufferU[j] := (appIDaddr shr 4) and $FF;
  Inc(j);
  bufferU[j] := (appIDaddr shl 4) and $F0 + 6;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $78;
  Inc(j);
  bufferU[j] := $47;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
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
  PacketIO(2);
  j := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'ApplicationID @ 0x80%04X:  0x%04X' + #13 + '' + NL + '', appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '' + NL + 'ERASE:' + NL + '');
  erase := (options and $F00) shr 8;
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  if erase = 0 then
  begin
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $4A;
   Inc(j);
  end
  else
   if erase = 1 then
   begin
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $FA;
    Inc(j);
   end
   else
    if erase >= 2 then
    begin
     bufferU[j] := $07;
     Inc(j);
     bufferU[j] := $FA;
     Inc(j);
    end;
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $3E;
  Inc(j);
  bufferU[j] := $BB;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  if erase >= 2 then
  begin
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := 4;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $3B;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $A8;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $3B;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $A8;
   Inc(j);
   bufferU[j] := $E7;
   Inc(j);
   bufferU[j] := $61;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   if erase = 3 then
   begin
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(20);
    msDelay(200);
    j := 0;
   end;
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $A9;
   Inc(j);
   bufferU[j] := $E7;
   Inc(j);
   bufferU[j] := $61;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $A8;
   Inc(j);
   bufferU[j] := $E7;
   Inc(j);
   bufferU[j] := $61;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $3B;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $3C;
   Inc(j);
   bufferU[j] := $22;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(7);
  j := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  w0 := bufferI[z + 1] and $80;
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $3C;
  Inc(j);
  bufferU[j] := $22;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  i := 0;
  while (erase < 2) and (i < 100) and w0 do
  begin
   PacketIO(5);
   z := 0;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   w0 := bufferI[z + 1] and $80;
   msDelay(10);
   Inc(i);
  end;
  if saveLog then
   fprintf(logfile, '' + NL + 'Erase time: %dms' + NL + '', i * 12);
  msDelay(10);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 5;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := IfThen(erase > 0, $1A, $4A);
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $3B;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  if newTABLPAG then
  begin
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $A0;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $90;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
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
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '' + NL + 'WRITE CODE:' + NL + '');
  High := 0;
  k := 0;
  i := 0;
  while i < dim do
  begin
   if k = 0 then
   begin
    valid := 0;
    while not (valid) and (i < dim) do
    begin
     k2 := 0;
     while (k2 < rowSize * 4) and not (valid) do
     begin
      if memCODE[i + k2] < $FF then
       valid := 1;
      Inc(k2);
     end;
     Inc(i, IfThen(valid, 0, rowSize * 4));
    end;
    if i >= dim then
     Break;
   end;
   if (i shr 17) <> High then
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := (i shr 21) and $FF;
    Inc(j);
    bufferU[j] := (i shr 13) and $F0;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    if newTABLPAG then
    begin
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $01;
     Inc(j);
     bufferU[j] := $90;
     Inc(j);
    end;
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
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
    High := i shr 17;
   end;
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := $20 + (i shr 13) and $F;
   Inc(j);
   bufferU[j] := (i shr 5) and $FF;
   Inc(j);
   bufferU[j] := (i shl 3) and $F0 + 7;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 1] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 1] shl 4) and $F0 + (memCODE[i] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i] shl 4) and $F0;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 6] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 6] shl 4) and $F0 + (memCODE[i + 2] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 2] shl 4) and $F0 + 1;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 5] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 5] shl 4) and $F0 + (memCODE[i + 4] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 4] shl 4) and $F0 + 2;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 9] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 9] shl 4) and $F0 + (memCODE[i + 8] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 8] shl 4) and $F0 + 3;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 14] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 14] shl 4) and $F0 + (memCODE[i + 10] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 10] shl 4) and $F0 + 4;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 13] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 13] shl 4) and $F0 + (memCODE[i + 12] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 12] shl 4) and $F0 + 5;
   Inc(j);
   bufferU[j] := $EB;
   Inc(j);
   bufferU[j] := $03;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $EB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $1B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $EB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $1B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   Inc(k);
   if k = rowSize div 4 then
   begin
    if erase > 1 then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[j] := $3F;
     Inc(j);
     bufferU[j] := 6;
     Inc(j);
     bufferU[j] := $24;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := IfThen(erase > 0, $1A, $4A);
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $05;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A9;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
    end;
    k := 0;
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
   sprintf(str, strings[S_CodeWriting2], (i * 100) div (dim + dim2), i div 2);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i div 2, i div 2, k, k);
   end;
   Inc(i, 4 * 4);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, '' + NL + 'VERIFY CODE:' + NL + '');
  High := $E0000000;
  r0 := 0;
  r1 := 0;
  r2 := 0;
  r3 := 0;
  i := 0;
  while i < dim do
  begin
   valid := 0;
   while not (valid) and (i < dim) do
   begin
    k2 := 0;
    while (k2 < 16) and not (valid) do
    begin
     if memCODE[i + k2] < $FF then
      valid := 1;
     Inc(k2);
    end;
    Inc(i, IfThen(valid, 0, 16));
   end;
   if i >= dim then
    Break;
   if (i shr 17) <> High then
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := (i shr 21) and $FF;
    Inc(j);
    bufferU[j] := (i shr 13) and $F0;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    if newTABLPAG then
    begin
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $01;
     Inc(j);
     bufferU[j] := $90;
     Inc(j);
    end;
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
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
    High := i shr 17;
   end;
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20 + (i shr 13) and $F;
   Inc(j);
   bufferU[j] := (i shr 5) and $FF;
   Inc(j);
   bufferU[j] := (i shl 3) and $F0 + 6;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $47;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $D3;
   Inc(j);
   bufferU[j] := $D6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $D3;
   Inc(j);
   bufferU[j] := $D6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
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
   PacketIO(3);
   sprintf(str, strings[S_CodeV2], (i * 100) div (dim + dim2), i div 2);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   z := 0;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r0 := r0 + bufferI[z + 2] shl 16;
    r1 := bufferI[z + 1] shl 16;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r1 := r1 + (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r2 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r2 := r2 + bufferI[z + 2] shl 16;
    r3 := bufferI[z + 1] shl 16;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r3 := r3 + (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   w0 := (memCODE[i + 2] shl 16) + (memCODE[i + 1] shl 8) + memCODE[i];
   w1 := (memCODE[i + 6] shl 16) + (memCODE[i + 5] shl 8) + memCODE[i + 4];
   w2 := (memCODE[i + 10] shl 16) + (memCODE[i + 9] shl 8) + memCODE[i + 8];
   w3 := (memCODE[i + 14] shl 16) + (memCODE[i + 13] shl 8) + memCODE[i + 12];
   CheckData(w0, r0, i div 2, @err);
   CheckData(w1, r1, i div 2 + 2, @err);
   CheckData(w2, r2, i div 2 + 4, @err);
   CheckData(w3, r3, i div 2 + 6, @err);
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i div 2);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i div 2, i div 2, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, 16);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if err >= max_err then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  if dim2 and (err < max_err) then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, '' + NL + 'WRITE EEPROM:' + NL + '');
   eewrite := (options and $f000) shr 12;
   if eewrite = 0 then
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $24;
    Inc(j);
    bufferU[j] := $05;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    bufferU[j] := $3B;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $07;
    Inc(j);
    bufferU[j] := $F0;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    if newTABLPAG then
    begin
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $01;
     Inc(j);
     bufferU[j] := $90;
     Inc(j);
    end;
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $2F;
    Inc(j);
    bufferU[j] := EEbaseAddr shr 4;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $BB;
    Inc(j);
    bufferU[j] := $08;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $A8;
    Inc(j);
    bufferU[j] := $E7;
    Inc(j);
    bufferU[j] := $61;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $24;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $4A;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    bufferU[j] := $3B;
    Inc(j);
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(9);
    j := 0;
   end
   else
    if eewrite = 2 then
    begin
     bufferU[j] := $3F;
     Inc(j);
     bufferU[j] := 6;
     Inc(j);
     bufferU[j] := $24;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     bufferU[j] := $6A;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $05;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A9;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $3F;
     Inc(j);
     bufferU[j] := 6;
     Inc(j);
     bufferU[j] := $24;
     Inc(j);
     bufferU[j] := $05;
     Inc(j);
     bufferU[j] := $6A;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $05;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A9;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(6);
     j := 0;
     bufferU[j] := $3F;
     Inc(j);
     bufferU[j] := 6;
     Inc(j);
     bufferU[j] := $24;
     Inc(j);
     bufferU[j] := $06;
     Inc(j);
     bufferU[j] := $6A;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $05;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A9;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
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
    end
    else
     if eewrite = 1 then
     begin
      bufferU[j] := $36;
      Inc(j);
      bufferU[j] := $20;
      Inc(j);
      bufferU[j] := $07;
      Inc(j);
      bufferU[j] := $F0;
      Inc(j);
      bufferU[j] := $36;
      Inc(j);
      bufferU[j] := $88;
      Inc(j);
      if newTABLPAG then
      begin
       bufferU[j] := $02;
       Inc(j);
       bufferU[j] := $A0;
       Inc(j);
      end
      else
      begin
       bufferU[j] := $01;
       Inc(j);
       bufferU[j] := $90;
       Inc(j);
      end;
      bufferU[j] := $04;
      Inc(j);
      while j < 64 do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(1);
      j := 0;
     end;
   k2 := 0;
   i := $1000 - dim2;
   while i < $1000 do
   begin
    if (memEE[i] < $FF) or (memEE[i + 1] < $FF) then
    begin
     bufferU[j] := $36;
     Inc(j);
     bufferU[j] := $2F;
     Inc(j);
     bufferU[j] := i shr 4;
     Inc(j);
     bufferU[j] := (i shl 4) and $F0 + 7;
     Inc(j);
     bufferU[j] := $36;
     Inc(j);
     bufferU[j] := $20 + (memEE[i + 1] shr 4) and $F;
     Inc(j);
     bufferU[j] := (memEE[i + 1] shl 4) and $F0 + (memEE[i] shr 4) and $F;
     Inc(j);
     bufferU[j] := (memEE[i] shl 4) and $F0;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $BB;
     Inc(j);
     bufferU[j] := $1B;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     if eewrite = 0 then
     begin
      bufferU[j] := $3E;
      Inc(j);
      bufferU[j] := $A8;
      Inc(j);
      bufferU[j] := $E7;
      Inc(j);
      bufferU[j] := $61;
      Inc(j);
     end
     else
      if eewrite = 1 then
      begin
       bufferU[j] := $3F;
       Inc(j);
       bufferU[j] := 6;
       Inc(j);
       bufferU[j] := $24;
       Inc(j);
       bufferU[j] := $00;
       Inc(j);
       bufferU[j] := $4A;
       Inc(j);
       bufferU[j] := $88;
       Inc(j);
       bufferU[j] := $3B;
       Inc(j);
       bufferU[j] := $0A;
       Inc(j);
       bufferU[j] := $20;
       Inc(j);
       bufferU[j] := $05;
       Inc(j);
       bufferU[j] := $58;
       Inc(j);
       bufferU[j] := $88;
       Inc(j);
       bufferU[j] := $3B;
       Inc(j);
       bufferU[j] := $38;
       Inc(j);
       bufferU[j] := $20;
       Inc(j);
       bufferU[j] := $0A;
       Inc(j);
       bufferU[j] := $A8;
       Inc(j);
       bufferU[j] := $88;
       Inc(j);
       bufferU[j] := $3B;
       Inc(j);
       bufferU[j] := $38;
       Inc(j);
       bufferU[j] := $3E;
       Inc(j);
       bufferU[j] := $A8;
       Inc(j);
       bufferU[j] := $E7;
       Inc(j);
       bufferU[j] := $61;
       Inc(j);
       bufferU[j] := $0A;
       Inc(j);
       bufferU[j] := $38;
       Inc(j);
       bufferU[j] := $38;
       Inc(j);
       bufferU[j] := $3E;
       Inc(j);
       bufferU[j] := $A9;
       Inc(j);
       bufferU[j] := $E7;
       Inc(j);
       bufferU[j] := $61;
       Inc(j);
      end;
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(wait + 2);
     j := 0;
     sprintf(str, strings[S_CodeWriting], (((i - $1000) + dim2) * 100) div dim2, i);
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
    end;
    Inc(i, 2);
   end;
   if saveLog then
    fprintf(logfile, '' + NL + 'VERIFY EEPROM:' + NL + '');
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $2F;
   Inc(j);
   bufferU[j] := EEbaseAddr shr 4;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $47;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   errE := 0;
   k2 := EEbaseAddr;
   k2 := EEbaseAddr;
   i := k2;
   while i < EEbaseAddr + dim2 do
   begin
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    if (j > 64 - 7) or (i = dim2 - 4) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     for z := 0 to (64 - 2) - 1 do
     begin
      if bufferI[z] = $37 then
      begin
       CheckData(memEE[k2], bufferI[z + 2], i, @errE);
       CheckData(memEE[k2 + 1], bufferI[z + 1], i + 1, @errE);
       z := z + 3;
       k2 := k2 + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((i - EEbaseAddr) * 100) div dim2, i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := EEbaseAddr + dim2;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
    Inc(i, 2);
   end;
   sprintf(str, strings[S_ComplErr], errE);
   PrintMessage(str);
   err := err + errE;
   gtk_statusbar_push(status_bar, statusID, '');
  end;
  j := 0;
  if (config > 2) and (config < 5) and (err < max_err) then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
    fprintf(logfile, '' + NL + 'WRITE CONFIG:' + NL + '');
   confword := (options and $F0000) shr 16;
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := 6;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $0F;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   if newTABLPAG then
   begin
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
   end
   else
   begin
    bufferU[j] := $01;
    Inc(j);
    bufferU[j] := $90;
    Inc(j);
   end;
   bufferU[j] := $24;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   if confword = 0 then
    bufferU[j] := $0A;
    Inc(j)
   else
    if confword = 1 then
     bufferU[j] := $3A;
     Inc(j)
    else
     if confword = 2 then
      bufferU[j] := $4A;
      Inc(j)
     else
      if confword = 3 then
       bufferU[j] := $8A;
       Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $3B;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $07;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   for i := 0 to (12) - 1 do
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := (memCONFIG[i * 4] shr 4) and $F;
    Inc(j);
    bufferU[j] := (memCONFIG[i * 4] shl 4) and $F0;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BB;
    Inc(j);
    bufferU[j] := $1B;
    Inc(j);
    bufferU[j] := $80;
    Inc(j);
    if memCONFIG[i * 4] < $FF then
    begin
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
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
    msDelay(27);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   errC := 0;
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $78;
   Inc(j);
   bufferU[j] := $47;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   z := 0;
   for i := 0 to (9) - 1 do
   begin
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    written := memCONFIG[i * 4];
    read_ := bufferI[z + 2];
    if not (written) and read_ then
     CheckData(written, read_, $F80000 + i * 2, @errC);
    z := z + 3;
   end;
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $3E;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   z := 0;
   while i < 12 do
   begin
    while (bufferI[z] <> $37) and (z < 64) do
    begin
     Inc(z);
    end;
    written := memCONFIG[i * 4];
    read_ := bufferI[z + 2];
    if not (written) and read_ then
     CheckData(written, read_, $F80000 + i * 2, @errC);
    z := z + 3;
    Inc(i);
   end;
   sprintf(str, strings[S_ComplErr], errC);
   PrintMessage(str);
   gtk_statusbar_push(status_bar, statusID, '');
   err := err + errC;
  end
  else
   if (config >= 5) and (err < max_err) then
   begin
    PrintMessage(strings[S_ConfigW]);
    if saveLog then
     fprintf(logfile, '' + NL + 'WRITE CONFIG:' + NL + '');
    Nconf := IfThen(config = 5, 7, 8);
    bufferU[j] := $3F;
    Inc(j);
    bufferU[j] := 4;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $0F;
    Inc(j);
    bufferU[j] := $80;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    if newTABLPAG then
    begin
     bufferU[j] := $02;
     Inc(j);
     bufferU[j] := $A0;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $01;
     Inc(j);
     bufferU[j] := $90;
     Inc(j);
    end;
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $07;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    for i := 0 to (Nconf) - 1 do
    begin
     bufferU[j] := $36;
     Inc(j);
     bufferU[j] := $2F;
     Inc(j);
     bufferU[j] := $FF;
     Inc(j);
     bufferU[j] := $F0;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $BB;
     Inc(j);
     bufferU[j] := $1B;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     bufferU[j] := $3F;
     Inc(j);
     bufferU[j] := 6;
     Inc(j);
     bufferU[j] := $24;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $8A;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $05;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $20;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $88;
     Inc(j);
     bufferU[j] := $3B;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A8;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $A9;
     Inc(j);
     bufferU[j] := $E7;
     Inc(j);
     bufferU[j] := $61;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, 0, 0);
     end;
    end;
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $07;
    Inc(j);
    for i := 0 to (Nconf) - 1 do
    begin
     value := memCONFIG[i * 4] + (memCONFIG[i * 4 + 1] shl 8);
     bufferU[j] := $36;
     Inc(j);
     bufferU[j] := $20 + (value shr 12);
     Inc(j);
     bufferU[j] := value shr 4;
     Inc(j);
     bufferU[j] := value shl 4;
     Inc(j);
     bufferU[j] := $38;
     Inc(j);
     bufferU[j] := $3E;
     Inc(j);
     bufferU[j] := $BB;
     Inc(j);
     bufferU[j] := $1B;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     if value < $FFFF then
     begin
      bufferU[j] := $3F;
      Inc(j);
      bufferU[j] := 6;
      Inc(j);
      bufferU[j] := $24;
      Inc(j);
      bufferU[j] := $00;
      Inc(j);
      bufferU[j] := $8A;
      Inc(j);
      bufferU[j] := $88;
      Inc(j);
      bufferU[j] := $3B;
      Inc(j);
      bufferU[j] := $0A;
      Inc(j);
      bufferU[j] := $20;
      Inc(j);
      bufferU[j] := $05;
      Inc(j);
      bufferU[j] := $58;
      Inc(j);
      bufferU[j] := $88;
      Inc(j);
      bufferU[j] := $3B;
      Inc(j);
      bufferU[j] := $38;
      Inc(j);
      bufferU[j] := $20;
      Inc(j);
      bufferU[j] := $0A;
      Inc(j);
      bufferU[j] := $A8;
      Inc(j);
      bufferU[j] := $88;
      Inc(j);
      bufferU[j] := $3B;
      Inc(j);
      bufferU[j] := $38;
      Inc(j);
      bufferU[j] := $3E;
      Inc(j);
      bufferU[j] := $A8;
      Inc(j);
      bufferU[j] := $E7;
      Inc(j);
      bufferU[j] := $61;
      Inc(j);
      bufferU[j] := $0A;
      Inc(j);
      bufferU[j] := $38;
      Inc(j);
      bufferU[j] := $38;
      Inc(j);
      bufferU[j] := $3E;
      Inc(j);
      bufferU[j] := $A9;
      Inc(j);
      bufferU[j] := $E7;
      Inc(j);
      bufferU[j] := $61;
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
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, 0, 0);
     end;
    end;
    errC := 0;
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $06;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $78;
    Inc(j);
    bufferU[j] := $47;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $BA;
    Inc(j);
    bufferU[j] := $0B;
    Inc(j);
    bufferU[j] := $B6;
    Inc(j);
    bufferU[j] := $37;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(3);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
    end;
    z := 0;
    for i := 0 to (7) - 1 do
    begin
     while (bufferI[z] <> $37) and (z < 64) do
     begin
      Inc(z);
     end;
     written := memCONFIG[i * 4 + 1] + (memCONFIG[i * 4] shl 8);
     read_ := bufferI[z + 1] + (bufferI[z + 2] shl 8);
     if not (written) and read_ then
      CheckData(written, read_, $F80000 + i * 2, @errC);
     z := z + 3;
    end;
    sprintf(str, strings[S_ComplErr], errC);
    PrintMessage(str);
    gtk_statusbar_push(status_bar, statusID, '');
    err := err + errC;
   end;
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
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
  j := 0;
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

function Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  valid: Integer;
  High: Integer;
  r0: Integer;
  r1: Integer;
  r2: Integer;
  r3: Integer;
  w3: Integer;
  w2: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  err := 0;
  if FWVersion < $900 then
  begin
   sprintf(str, strings[S_FWver2old], '0.9.0');
   PrintMessage(str);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write24Ex(%d,%d,%d,%d,%d,%.1f)    (0x%X,0x%X,0x%X,0x%X,0x%X,%.3f)' + NL + '', dim, dim2, options, appIDaddr, rowSize, wait, dim, dim2, options, appIDaddr, rowSize, wait);
  end;
  dim := dim * 2;
  if (dim > $100000) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if dim > size then
   for i := size to (dim) - 1 do
   begin
    memCODE[i] := $FF;
   end;
  if dim < 1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  StartHVReg(-1);
  for i := 0 to (10) - 1 do
  begin
   sprintf(str, 'CONFIG%d(0x%05X): 0x%02X' + #13 + '' + NL + '', i, ((dim - 40) + i * 4) div 2, memCODE[(dim - 40) + i * 4]);
   PrintMessage(str);
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
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $09;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $4D;
  Inc(j);
  bufferU[j] := $43;
  Inc(j);
  bufferU[j] := $48;
  Inc(j);
  bufferU[j] := $51;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 55000 shr 8;
  Inc(j);
  bufferU[j] := 55000 and $ff;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(65);
  j := 0;
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $06;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $87;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $B6;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
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
  w0 := 0;
  w1 := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  z := 3;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w1 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'DevID: 0x%04X' + #13 + '' + NL + 'DevRev: 0x%04X' + #13 + '' + NL + '', w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $44;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $08;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $A0;
  Inc(j);
  bufferU[j] := $20 + (appIDaddr shr 12) and $F;
  Inc(j);
  bufferU[j] := (appIDaddr shr 4) and $FF;
  Inc(j);
  bufferU[j] := (appIDaddr shl 4) and $F0 + 6;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $87;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $BA;
  Inc(j);
  bufferU[j] := $0B;
  Inc(j);
  bufferU[j] := $96;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
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
  PacketIO(2);
  j := 0;
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
   w0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  sprintf(str, 'ApplicationID @ 0x80%04X:  0x%04X' + #13 + '' + NL + '', appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '' + NL + 'ERASE:' + NL + '');
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $DA;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $4A;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $7C;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $05;
  Inc(j);
  bufferU[j] := $51;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $71;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $A1;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $71;
  Inc(j);
  bufferU[j] := $49;
  Inc(j);
  bufferU[j] := $A8;
  Inc(j);
  bufferU[j] := $E7;
  Inc(j);
  bufferU[j] := $29;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $7C;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $37;
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
  z := 0;
  while (bufferI[z] <> $37) and (z < 64) do
  begin
   Inc(z);
  end;
  w0 := bufferI[z + 1] and $80;
  w0 := 1;
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $7C;
  Inc(j);
  bufferU[j] := $40;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $37;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  i := 0;
  while (i < 50) and w0 do
  begin
   PacketIO(5);
   z := 0;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   w0 := bufferI[z + 1] and $80;
   msDelay(10);
   Inc(i);
  end;
  if saveLog then
   fprintf(logfile, 'ERASE TIME: %d ms' + NL + '', i * 10);
  msDelay(70);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $36;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $38;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := 4;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $AC;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $02;
  Inc(j);
  bufferU[j] := $AC;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $1A;
  Inc(j);
  bufferU[j] := $88;
  Inc(j);
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := $4A;
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
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '' + NL + 'WRITE CODE:' + NL + '');
  High := 0;
  k := 0;
  i := 0;
  while i < dim do
  begin
   valid := 0;
   while not (valid) and (i < dim) do
   begin
    k2 := 0;
    while (k2 < 2 * 4) and not (valid) do
    begin
     if memCODE[i + k2] < $FF then
      valid := 1;
     Inc(k2);
    end;
    Inc(i, IfThen(valid, 0, 2 * 4));
   end;
   if i >= dim then
    Break;
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := 5;
   Inc(j);
   bufferU[j] := $EB;
   Inc(j);
   bufferU[j] := $03;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $EB;
   Inc(j);
   bufferU[j] := $03;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 1] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 1] shl 4) and $F0 + (memCODE[i] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i] shl 4) and $F0;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 6] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 6] shl 4) and $F0 + (memCODE[i + 2] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 2] shl 4) and $F0 + 1;
   Inc(j);
   bufferU[j] := $20 + (memCODE[i + 5] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 5] shl 4) and $F0 + (memCODE[i + 4] shr 4) and $F;
   Inc(j);
   bufferU[j] := (memCODE[i + 4] shl 4) and $F0 + 2;
   Inc(j);
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := $84;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $EB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $BB;
   Inc(j);
   bufferU[j] := $1B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $3F;
   Inc(j);
   bufferU[j] := 8;
   Inc(j);
   bufferU[j] := $20 + (i shr 13) and $F;
   Inc(j);
   bufferU[j] := (i shr 5) and $FF;
   Inc(j);
   bufferU[j] := (i shl 3) and $F0 + 3;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := (i shr 21) and $FF;
   Inc(j);
   bufferU[j] := (i shr 13) and $F0 + 4;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := $53;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := $64;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $51;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := $71;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $A1;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := $71;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $A8;
   Inc(j);
   bufferU[j] := $E7;
   Inc(j);
   bufferU[j] := $29;
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
   sprintf(str, strings[S_CodeWriting2], (i * 100) div (dim + dim2), i div 2);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i div 2, i div 2, k, k);
   end;
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := $42;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $88;
   Inc(j);
   bufferU[j] := $7C;
   Inc(j);
   bufferU[j] := $42;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $38;
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
   Inc(i, 2 * 4);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, '' + NL + 'VERIFY CODE:' + NL + '');
  High := $E0000000;
  r0 := 0;
  r1 := 0;
  r2 := 0;
  r3 := 0;
  i := 0;
  while i < dim do
  begin
   valid := 0;
   while not (valid) and (i < dim) do
   begin
    k2 := 0;
    while (k2 < 16) and not (valid) do
    begin
     if memCODE[i + k2] < $FF then
      valid := 1;
     Inc(k2);
    end;
    Inc(i, IfThen(valid, 0, 16));
   end;
   if i >= dim then
    Break;
   if (i shr 17) <> High then
   begin
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := (i shr 21) and $FF;
    Inc(j);
    bufferU[j] := (i shr 13) and $F0;
    Inc(j);
    bufferU[j] := $36;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $A0;
    Inc(j);
    bufferU[j] := $3E;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $02;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $38;
    Inc(j);
    bufferU[j] := $38;
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
    High := i shr 17;
   end;
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20 + (i shr 13) and $F;
   Inc(j);
   bufferU[j] := (i shr 5) and $FF;
   Inc(j);
   bufferU[j] := (i shl 3) and $F0 + 6;
   Inc(j);
   bufferU[j] := $36;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $87;
   Inc(j);
   bufferU[j] := $38;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $D3;
   Inc(j);
   bufferU[j] := $D6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $96;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $DB;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $D3;
   Inc(j);
   bufferU[j] := $D6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $BA;
   Inc(j);
   bufferU[j] := $0B;
   Inc(j);
   bufferU[j] := $B6;
   Inc(j);
   bufferU[j] := $37;
   Inc(j);
   bufferU[j] := $49;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $02;
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
   PacketIO(4);
   sprintf(str, strings[S_CodeV2], (i * 100) div (dim + dim2), i div 2);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   z := 0;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r0 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r0 := r0 + bufferI[z + 2] shl 16;
    r1 := bufferI[z + 1] shl 16;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r1 := r1 + (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r2 := (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r2 := r2 + bufferI[z + 2] shl 16;
    r3 := bufferI[z + 1] shl 16;
   end;
   z := 3;
   while (bufferI[z] <> $37) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    r3 := r3 + (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   w0 := (memCODE[i + 2] shl 16) + (memCODE[i + 1] shl 8) + memCODE[i];
   w1 := (memCODE[i + 6] shl 16) + (memCODE[i + 5] shl 8) + memCODE[i + 4];
   w2 := (memCODE[i + 10] shl 16) + (memCODE[i + 9] shl 8) + memCODE[i + 8];
   w3 := (memCODE[i + 14] shl 16) + (memCODE[i + 13] shl 8) + memCODE[i + 12];
   CheckData(w0, r0, i div 2, @err);
   CheckData(w1, r1, i div 2 + 2, @err);
   CheckData(w2, r2, i div 2 + 4, @err);
   CheckData(w3, r3, i div 2 + 6, @err);
   sprintf(str, strings[S_CodeV2], (i * 100) div dim, i div 2);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i div 2, i div 2, k, k, err);
   end;
   if err >= max_err then
    Break;
   Inc(i, 16);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if err >= max_err then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
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
  j := 0;
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

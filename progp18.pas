unit progp18;

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
  LOAD_PC_ADDR = $80;
  BULK_ERASE = $18;
  ROW_ERASE_PROGRAM_MEM = $F0;
  LOAD_NVM = $00;
  LOAD_NVM_INC = $02;
  READ_NVM = $FC;
  READ_NVM_INC = $FE;
  INC_ADDR8 = $F8;
  BEGIN_INT_PROG = $E0;
  BEGIN_EXT_PROG = $C0;
  PROGRAM_DATA = $C0;
  PROGRAM_DATA_INC = $E0;
  END_EXT_PROG = $82;
  PROGRAM_ACCESS_EN = $4C;
  IDaddr = $200000;
  CONFIGaddr = $300000;

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
  PIC18LIST: array of TID18;

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
function PIC18_ID(id: Integer): Pointer;
function DisplayCODE18F(dim: Integer): Pointer;
function Read18Fx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer): Pointer;
function Read18FKx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer): Pointer;

implementation

function PIC18_ID(id: Integer): Pointer;
var
  s: array[0..128-1] of Char;
  i: Integer;
  MJrev: Integer;
  MNrev: Integer;
begin
  for i := 0 to (SizeOf(PIC18LIST) div SizeOf(PIC18LIST[0])) - 1 do
  begin
   if (PIC18LIST[i].revmask <> $FFFF) and (PIC18LIST[i].id = id and not (PIC18LIST[i].revmask)) then
   begin
    sprintf(s, PIC18LIST[i].device, id and PIC18LIST[i].revmask);
    PrintMessage(s);
    Exit;
   end
   else
    if (PIC18LIST[i].revmask = $FFFF) and (PIC18LIST[i].id = id and $FFFF) then
    begin
     MJrev := (id shr 22) and $3F;
     MNrev := (id shr 16) and $3F;
     sprintf(s, PIC18LIST[i].device, MJrev + #65, MNrev);
     PrintMessage(s);
     Exit;
    end;
  end;
  sprintf(s, '%s', strings[S_nodev]);
  PrintMessage(s);
end;

function DisplayCODE18F(dim: Integer): Pointer;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
begin
  s := '';
  t := '';
  aux := malloc((dim div 16 + 1) * (16 + 16 * 6));
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

function Read18Fx(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  entry: Integer;
  newAddr: Integer;
  vpp: Double;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := options and $F;
  newAddr := (options shr 4) and $F;
  if (dim > $1FFFFF) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if (entry > 0) and not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := -1;
  if entry = 0 then
   vpp := 12
  else
   if (entry = 1) or (entry = 3) then
    vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read18F(%d,%d,%d)    (0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options, dim, dim2, options);
  end;
  size := dim;
  sizeEE := dim2;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  if memEE then
   free(memEE);
  memEE := malloc(sizeEE);
  for j := 0 to (8) - 1 do
  begin
   memID[j] := $FF;
  end;
  for j := 0 to (14) - 1 do
  begin
   memCONFIG[j] := $FF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 100;
  Inc(j);
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
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  if entry = 2 then
  begin
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
  end;
  if (entry = 2) or (entry = 3) then
  begin
   bufferU[j] := $0A;
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
   bufferU[j] := $50;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $5;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
  end;
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F6;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F6;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(entry = 2, 11, 4));
  z := 0;
  while (bufferI[z] <> $24) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 3 then
  begin
   sprintf(str, strings[S_DevID2], bufferI[z + 3], bufferI[z + 2]);
   PrintMessage(str);
   PIC18_ID(bufferI[z + 2] + (bufferI[z + 3] shl 8));
  end;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, 'Read code' + NL + '');
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $24;
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
   PacketIO(2);
   z := 0;
   while (bufferI[z] <> $24) and (z < 64) do
   begin
    Inc(z);
   end;
   j := z + 2;
   while (j < z + 2 + bufferI[z + 1]) and (j < 64) do
   begin
    memCODE[k] := bufferI[j];
    Inc(k);
    Inc(j);
   end;
   sprintf(str, strings[S_CodeReading2], (i * 100) div (dim + dim2), i);
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
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if saveLog then
   fprintf(logfile, 'Read config' + NL + '');
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $20;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F6;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := 8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $30;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F6;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := 14;
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
  while (bufferI[z] <> $24) and (z < 64 - 28) do
  begin
   Inc(z);
  end;
  if z < 64 - 28 then
  begin
   for i := 0 to (8) - 1 do
   begin
    memID[k2] := bufferI[z + i + 2];
    Inc(k2);
   end;
   while i < 14 + 8 do
   begin
    memCONFIG[-8 + k2] := bufferI[z + i + 8];
    Inc(k2);
    Inc(i);
   end;
  end;
  j := 0;
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log7], i, i, k2, k2);
  end;
  if k2 <> 22 then
  begin
   sprintf(str, strings[S_ReadConfigErr], 22, k2);
   PrintMessage(str);
  end;
  if dim2 then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, 'Read EEPROM' + NL + '');
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $9E;
   Inc(j);
   bufferU[j] := IfThen(newAddr = 0, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $9C;
   Inc(j);
   bufferU[j] := IfThen(newAddr = 0, $A6, $7F);
   Inc(j);
   k2 := 0;
   i := 0;
   while i < dim2 do
   begin
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := IfThen(newAddr = 0, $A9, $74);
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := (i shr 8) and $FF;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := IfThen(newAddr = 0, $AA, $75);
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $80;
    Inc(j);
    bufferU[j] := IfThen(newAddr = 0, $A6, $7F);
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $50;
    Inc(j);
    bufferU[j] := IfThen(newAddr = 0, $A8, $73);
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F5;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $00;
    Inc(j);
    bufferU[j] := $22;
    Inc(j);
    if (j > 64 - 26) or (i = dim2 - 1) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(10);
     for z := 0 to (64 - 1) - 1 do
     begin
      if bufferI[z] = $22 then
      begin
       memEE[k2] := bufferI[z + 1];
       Inc(k2);
       z := z + 8;
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
  PrintMessage('' + #13 + '' + NL + '');
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
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
  PacketIO(1);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  i := 0;
  while i < 8 do
  begin
   sprintf(str, strings[S_ChipID2], i, memID[i], i + 1, memID[i + 1]);
   PrintMessage(str);
   Inc(i, 2);
  end;
  for i := 0 to (7) - 1 do
  begin
   sprintf(str, strings[S_ConfigWordH], i + 1, memCONFIG[i * 2 + 1]);
   PrintMessage(str);
   sprintf(str, strings[S_ConfigWordL], i + 1, memCONFIG[i * 2]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE18F(dim);
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

function Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  EEalgo: Integer;
  entry: Integer;
  optWrite: Integer;
  vpp: Double;
  start: Cardinal;
  ww: Integer;
  wdly: Double;
  valid: Integer;
  i0: Integer;
  errEE: Integer;
  errID: Integer;
  errC: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  EEalgo := (options shr 4) and $F;
  entry := options and $F;
  optWrite := (options shr 8) and $F;
  if (dim > $1FFFFF) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if wbuf > 64 then
  begin
   PrintMessage(strings[S_WbufLim]);
   Exit;
  end;
  if (entry > 0) and not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := -1;
  if entry = 0 then
   vpp := 12
  else
   if (entry = 1) or (entry = 3) then
    vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write18F(%d,%d,%d,%d)    (0x%X,0x%X,0x%X,0x%X)' + NL + '', dim, dim2, wbuf, options, dim, dim2, wbuf, options);
  end;
  if dim > size then
   dim := size;
  if dim mod wbuf then
  begin
   dim := dim + wbuf - dim mod wbuf;
   j := size;
   if j < dim then
   begin
    size := dim;
    memCODE := realloc(memCODE, size);
    while j < dim do
    begin
     memCODE[j] := $FF;
     Inc(j);
    end;
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
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 100;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  if entry = 2 then
  begin
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $1;
   Inc(j);
  end;
  if (entry = 2) or (entry = 3) then
  begin
   bufferU[j] := $0A;
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
   bufferU[j] := $50;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $5;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
  end;
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $3F;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6E;
  Inc(j);
  bufferU[j] := $F6;
  Inc(j);
  bufferU[j] := $24;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 5100 shr 8;
  Inc(j);
  bufferU[j] := 5100 and $ff;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(entry = 2, 10, 3));
  z := 0;
  while (bufferI[z] <> $24) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 3 then
  begin
   sprintf(str, strings[S_DevID2], bufferI[z + 3], bufferI[z + 2]);
   PrintMessage(str);
   PIC18_ID(bufferI[z + 2] + (bufferI[z + 3] shl 8));
  end;
  j := 0;
  PrintMessage(strings[S_StartErase]);
  if optWrite <> 3 then
  begin
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $3C;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F7;
   Inc(j);
   if eraseW1 < $10000 then
   begin
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := $05;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F6;
    Inc(j);
    bufferU[j] := $25;
    Inc(j);
    bufferU[j] := (eraseW1 shr 8) and $FF;
    Inc(j);
    bufferU[j] := eraseW1 and $FF;
    Inc(j);
   end;
   if eraseW2 < $10000 then
   begin
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F6;
    Inc(j);
    bufferU[j] := $25;
    Inc(j);
    bufferU[j] := (eraseW2 shr 8) and $FF;
    Inc(j);
    bufferU[j] := eraseW2 and $FF;
    Inc(j);
   end;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(16);
   if optWrite <> 0 then
    msDelay(550);
   j := 0;
  end
  else
  begin
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $3C;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F7;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $01;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK0' + NL + '');
   end;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK1' + NL + '');
   end;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK2' + NL + '');
   end;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $08;
   Inc(j);
   bufferU[j] := $08;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK3' + NL + '');
   end;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BOOT BLOCK' + NL + '');
   end;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $02;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $25;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $00;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $00;
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
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE CONFIG' + NL + '');
   end;
   if programID then
   begin
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $8E;
    Inc(j);
    bufferU[j] := $7F;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $9C;
    Inc(j);
    bufferU[j] := $7F;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $84;
    Inc(j);
    bufferU[j] := $7F;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := $20;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F8;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6A;
    Inc(j);
    bufferU[j] := $F7;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6A;
    Inc(j);
    bufferU[j] := $F6;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $88;
    Inc(j);
    bufferU[j] := $7F;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $82;
    Inc(j);
    bufferU[j] := $7F;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $00;
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
    PacketIO(7);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, 'ERASE ID' + NL + '');
    end;
   end;
  end;
  PrintMessage(strings[S_Compl]);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $8E;
  Inc(j);
  bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $9C;
  Inc(j);
  bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $84;
  Inc(j);
  bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F6;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1);
  j := 0;
  PrintMessage(strings[S_StartCodeProg]);
  wdly := 1.0;
  if optWrite = 1 then
   wdly := 1.2;
  if optWrite = 2 then
   wdly := 3.4;
  if saveLog then
  begin
   fprintf(logfile, 'WRITE CODE' + NL + 'dim=%d(0x%X)' + NL + '', dim, dim);
  end;
  j := 0;
  k := 0;
  k := 0;
  k := 0; i := 0;
  while i < dim do
  begin
   if k = 0 then
   begin
    i0 := i;
    valid := 0;
    while not (valid) and (i < dim) do
    begin
     k2 := 0;
     while (k2 < wbuf) and not (valid) do
     begin
      if memCODE[i + k2] < $FF then
       valid := 1;
      Inc(k2);
     end;
     Inc(i, IfThen(valid, 0, wbuf));
    end;
    if i >= dim then
     Break;
    if i > i0 then
    begin
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $0E;
     Inc(j);
     bufferU[j] := (i shr 16) and $FF;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $6E;
     Inc(j);
     bufferU[j] := $F8;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $0E;
     Inc(j);
     bufferU[j] := (i shr 8) and $FF;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $6E;
     Inc(j);
     bufferU[j] := $F7;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $0E;
     Inc(j);
     bufferU[j] := i and $FF;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $6E;
     Inc(j);
     bufferU[j] := $F6;
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
   end;
   if 64 - 4 - j < wbuf - 2 - k then
    ww := (64 - 4 - j) div 2
   else
    ww := (wbuf - 2 - k) div 2;
   bufferU[j] := $26;
   Inc(j);
   bufferU[j] := ww;
   Inc(j);
   for z := 0 to (ww) - 1 do
   begin
    bufferU[j] := memCODE[i + 1];
    Inc(j);
    bufferU[j] := memCODE[i];
    Inc(j);
    i := i + 2;
   end;
   k := k + ww * 2;
   if k = wbuf - 2 then
   begin
    if j > 64 - 8 then
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
    end;
    bufferU[j] := $28;
    Inc(j);
    bufferU[j] := memCODE[i + 1];
    Inc(j);
    bufferU[j] := memCODE[i];
    Inc(j);
    if optWrite = 1 then
    begin
     bufferU[j] := 1200 shr 8;
     Inc(j);
     bufferU[j] := 1200 and $FF;
     Inc(j);
    end
    else
     if optWrite = 2 then
     begin
      bufferU[j] := 3400 shr 8;
      Inc(j);
      bufferU[j] := 3400 and $FF;
      Inc(j);
     end
     else
     begin
      bufferU[j] := 1000 shr 8;
      Inc(j);
      bufferU[j] := 1000 and $FF;
      Inc(j);
     end;
    i := i + 2;
    k := 0;
   end;
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(IfThen(k = 0, wdly, 2));
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
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
  end;
  PrintMessage(strings[S_Compl]);
  if programID and ((optWrite = 0) or (optWrite = 3)) then
  begin
   PrintMessage(strings[S_IDW]);
   if saveLog then
    fprintf(logfile, 'Write ID' + NL + '');
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $8E;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $9C;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F7;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $26;
   Inc(j);
   bufferU[j] := 3;
   Inc(j);
   for i := 0 to (3) - 1 do
   begin
    bufferU[j] := memID[i * 2 + 1];
    Inc(j);
    bufferU[j] := memID[i * 2];
    Inc(j);
   end;
   bufferU[j] := $27;
   Inc(j);
   bufferU[j] := memID[i * 2 + 1];
   Inc(j);
   bufferU[j] := memID[i * 2];
   Inc(j);
   bufferU[j] := 1000 shr 8;
   Inc(j);
   bufferU[j] := 1000 and $FF;
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
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
   PrintMessage(strings[S_Compl]);
  end;
  if dim2 and ((optWrite = 0) or (optWrite = 3)) then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, 'Write EEPROM' + NL + '');
   errEE := 0;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $9E;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $9C;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $84;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   i := 0;
   while (i < dim2) and (err <= max_err) do
   begin
    if memEE[i] <> $FF then
    begin
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $0E;
     Inc(j);
     bufferU[j] := i and $FF;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $6E;
     Inc(j);
     bufferU[j] := IfThen(optWrite <> 3, $A9, $74);
     Inc(j);
     if EEalgo = 0 then
     begin
      bufferU[j] := $21;
      Inc(j);
      bufferU[j] := $0E;
      Inc(j);
      bufferU[j] := (i shr 8) and $FF;
      Inc(j);
      bufferU[j] := $21;
      Inc(j);
      bufferU[j] := $6E;
      Inc(j);
      bufferU[j] := IfThen(optWrite <> 3, $AA, $75);
      Inc(j);
     end;
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $0E;
     Inc(j);
     bufferU[j] := memEE[i];
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $6E;
     Inc(j);
     bufferU[j] := IfThen(optWrite <> 3, $A8, $73);
     Inc(j);
     if EEalgo = 1 then
     begin
      bufferU[j] := $21;
      Inc(j);
      bufferU[j] := $0E;
      Inc(j);
      bufferU[j] := $55;
      Inc(j);
      bufferU[j] := $21;
      Inc(j);
      bufferU[j] := $6E;
      Inc(j);
      bufferU[j] := $A7;
      Inc(j);
      bufferU[j] := $21;
      Inc(j);
      bufferU[j] := $0E;
      Inc(j);
      bufferU[j] := $AA;
      Inc(j);
      bufferU[j] := $21;
      Inc(j);
      bufferU[j] := $6E;
      Inc(j);
      bufferU[j] := $A7;
      Inc(j);
     end;
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $82;
     Inc(j);
     bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $50;
     Inc(j);
     bufferU[j] := IfThen(optWrite <> 3, $A8, $73);
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $6E;
     Inc(j);
     bufferU[j] := $F5;
     Inc(j);
     bufferU[j] := $21;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := $22;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(8);
     sprintf(str, strings[S_CodeWriting], ((i + dim) * 100) div (dim + dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := dim2;
     j := 0;
     z := 64 - 1;
     while z and not ((bufferI[z] = $22) and (bufferI[z - 1] = $21)) do
     begin
      Dec(z);
     end;
     if z and (memEE[i] <> bufferI[z + 1]) then
      Inc(errEE);
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
    Inc(i);
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end;
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, 'VERIFY CODE' + NL + '');
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $8E;
  Inc(j);
  bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $9C;
  Inc(j);
  bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F8;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F7;
  Inc(j);
  bufferU[j] := $21;
  Inc(j);
  bufferU[j] := $6A;
  Inc(j);
  bufferU[j] := $F6;
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
  begin
   fprintf(logfile, '' + NL + '' + NL + '');
  end;
  j := 0;
  k := 0;
  i := 0;
  while i < dim do
  begin
   i0 := i;
   valid := 0;
   while not (valid) and (i < dim) do
   begin
    k2 := 0;
    while (k2 < 64 - 4) and not (valid) and (i + k2 < dim) do
    begin
     if memCODE[i + k2] < $FF then
      valid := 1;
     Inc(k2);
    end;
    Inc(i, IfThen(valid, 0, 64 - 4));
   end;
   if i >= dim then
    Break;
   if i > i0 then
   begin
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := (i shr 16) and $FF;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F8;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := (i shr 8) and $FF;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F7;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := i and $FF;
    Inc(j);
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $6E;
    Inc(j);
    bufferU[j] := $F6;
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
   bufferU[j] := $24;
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
   PacketIO(2);
   if bufferI[1] = $24 then
   begin
    z := 0;
    while (z < bufferI[2]) and (z < 64) do
    begin
     if memCODE[i + z] <> bufferI[z + 3] then
     begin
      sprintf(str, strings[S_CodeVError], i + z, i + z, memCODE[i + z], bufferI[z + 3]);
      PrintMessage(str);
      Inc(err);
     end;
     Inc(z);
    end;
   end;
   sprintf(str, strings[S_CodeV2], (i * 100) div (dim + dim2), i);
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
   sprintf(str, strings[S_CodeVError2], dim, i);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if err >= max_err then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  if programID and (err < max_err) and (optWrite = 0) then
  begin
   PrintMessage(strings[S_IDV]);
   errID := 0;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $20;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F7;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $24;
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
   PacketIO(2);
   z := 0;
   while (bufferI[z] <> $24) and (z < 64) do
   begin
    Inc(z);
   end;
   for i := 0 to (8) - 1 do
   begin
    if (memID[i] <> $FF) and (memID[i] <> bufferI[z + i + 2]) then
     Inc(errID);
   end;
   sprintf(str, strings[S_ComplErr], errID);
   PrintMessage(str);
   err := err + errID;
   if err >= max_err then
   begin
    sprintf(str, strings[S_MaxErr], err);
    PrintMessage(str);
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, 0, 0, err);
   end;
  end;
  if (err < max_err) and ((optWrite = 0) or (optWrite = 3)) then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
    fprintf(logfile, 'Write CONFIG' + NL + '');
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $8E;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $8C;
   Inc(j);
   bufferU[j] := IfThen(optWrite <> 3, $A6, $7F);
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F7;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   for i := 0 to (14) - 1 do
   begin
    if memCONFIG[i] < $FF then
    begin
     bufferU[j] := $27;
     Inc(j);
     bufferU[j] := 0;
     Inc(j);
     bufferU[j] := memCONFIG[i];
     Inc(j);
     bufferU[j] := 5000 shr 8;
     Inc(j);
     bufferU[j] := 5000 and $FF;
     Inc(j);
    end;
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $2A;
    Inc(j);
    bufferU[j] := $F6;
    Inc(j);
    Inc(i);
    if memCONFIG[i] < $FF then
    begin
     bufferU[j] := $27;
     Inc(j);
     bufferU[j] := memCONFIG[i];
     Inc(j);
     bufferU[j] := 0;
     Inc(j);
     bufferU[j] := 5000 shr 8;
     Inc(j);
     bufferU[j] := 5000 and $FF;
     Inc(j);
    end;
    bufferU[j] := $21;
    Inc(j);
    bufferU[j] := $2A;
    Inc(j);
    bufferU[j] := $F6;
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
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   PrintMessage(strings[S_Compl]);
   PrintMessage(strings[S_ConfigV]);
   errC := 0;
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $0E;
   Inc(j);
   bufferU[j] := $30;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6E;
   Inc(j);
   bufferU[j] := $F8;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F7;
   Inc(j);
   bufferU[j] := $21;
   Inc(j);
   bufferU[j] := $6A;
   Inc(j);
   bufferU[j] := $F6;
   Inc(j);
   bufferU[j] := $24;
   Inc(j);
   bufferU[j] := 14;
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
   while (bufferI[z] <> $24) and (z < 64 - 16) do
   begin
    Inc(z);
   end;
   if z < 64 - 16 then
   begin
    for i := 0 to (14) - 1 do
    begin
     if not (memCONFIG[i]) and bufferI[z + i + 2] then
      Inc(errC);
    end;
   end;
   sprintf(str, strings[S_ComplErr], errC);
   PrintMessage(str);
   err := err + errC;
   if err >= max_err then
   begin
    sprintf(str, strings[S_MaxErr], err);
    PrintMessage(str);
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, 0, 0, err);
   end;
  end;
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
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
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
  PacketIO(1);
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

function Read18FKx(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  devID: Integer;
  devREV: Integer;
  MemAddr: Integer;
  EEaddr: Integer;
  DCIaddr: Integer;
  DIAaddr: Integer;
  DIAlen: Integer;
  UIDlen: Integer;
  CONFIGlen: Integer;
  CONFIGorg: Integer;
  type_: Integer;
  vpp: Double;
  memDIA: PByte;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  devID := 0;
  devREV := 0;
  EEaddr := 0;
  DCIaddr := 0;
  DIAaddr := 0;
  DIAlen := 0;
  UIDlen := 0;
  CONFIGlen := 0;
  CONFIGorg := 0;
  type_ := (options shr 4) and $F;
  if type_ = 0 then
  begin
   EEaddr := $310000;
   DCIaddr := $3FFF00;
   DIAaddr := $3F0000;
   DIAlen := $40;
   UIDlen := $10;
   CONFIGlen := 5;
   CONFIGorg := 0;
  end
  else
   if type_ = 1 then
   begin
    EEaddr := $380000;
    DCIaddr := $3C0000;
    DIAaddr := $2C0000;
    DIAlen := $100;
    UIDlen := $40;
    CONFIGlen := 10;
    CONFIGorg := 1;
   end
   else
    if type_ = 2 then
    begin
     EEaddr := $380000;
     DCIaddr := $3C0000;
     DIAaddr := $2C0000;
     DIAlen := $100;
     UIDlen := $40;
     CONFIGlen := 35;
     CONFIGorg := 1;
    end
    else
     if type_ = 3 then
     begin
      EEaddr := $310000;
      DCIaddr := 0;
      DIAaddr := 0;
      DIAlen := 0;
      UIDlen := 8;
      CONFIGlen := 6;
      CONFIGorg := 0;
     end
     else
      if type_ = 4 then
      begin
       EEaddr := $310000;
       DCIaddr := 0;
       DIAaddr := 0;
       DIAlen := 0;
       UIDlen := $100;
       CONFIGlen := 6;
       CONFIGorg := 0;
      end
      else
       if type_ = 5 then
       begin
        EEaddr := $380000;
        DCIaddr := $3C0000;
        DIAaddr := $2C0000;
        DIAlen := $100;
        UIDlen := $40;
        CONFIGlen := 26;
        CONFIGorg := 1;
       end
       else
        PrintMessage('unexpected parameter');
  if (dim > $1FFFFF) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read18FKx(%d,%d,%d)    (0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options, dim, dim2, options);
  end;
  size := dim;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  memDIA := malloc(DIAlen);
  for j := 0 to (SizeOf(memID)) - 1 do
  begin
   memID[j] := $FF;
  end;
  for j := 0 to (48) - 1 do
  begin
   memCONFIG[j] := $FF;
  end;
  for j := 0 to (DIAlen) - 1 do
  begin
   memDIA[j] := $FF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 100;
  Inc(j);
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
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  MemAddr := $3FFFFc shl 1;
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := MemAddr shr 16;
  Inc(j);
  bufferU[j] := (MemAddr shr 8) and $FF;
  Inc(j);
  bufferU[j] := MemAddr and $FF;
  Inc(j);
  bufferU[j] := $58;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $58;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  if DCIaddr > 0 then
  begin
   MemAddr := DCIaddr shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
  end;
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0;
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
  PacketIO(4);
  z := 0;
  while (bufferI[z] <> $58) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   devREV := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  end;
  z := 3;
  while (bufferI[z] <> $58) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   devID := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  end;
  sprintf(str, 'DevID: 0x%04X' + #13 + '' + NL + '', devID);
  PrintMessage(str);
  sprintf(str, 'RevID: 0x%04X' + #13 + '' + NL + '', devREV);
  PrintMessage(str);
  PIC18_ID(devID + (devREV shl 16));
  if DCIaddr > 0 then
  begin
   PrintMessage('Device Configuration Information:' + #13 + '' + NL + '');
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'Erase row size: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'Write latches per row: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'User rows: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'EEPROM size: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
    sizeEE := (bufferI[z + 1] shl 8) + bufferI[z + 2];
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 3 then
   begin
    sprintf(str, 'Pin count: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
  end
  else
   sizeEE := dim2;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeReading1]);
  j := 0;
  i := 0;
  while i < dim do
  begin
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   if (((j + 1) div 2) * 3 + 3 > 64) or (i = dim - 2) then
   begin
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to (64 - 2) - 1 do
    begin
     if bufferI[z] = $58 then
     begin
      memCODE[k] := bufferI[z + 2];
      Inc(k);
      memCODE[k] := bufferI[z + 1];
      Inc(k);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((i + sizeEE + 10 + UIDlen + DIAlen) * 100) div (dim + sizeEE + 10 + UIDlen + DIAlen), i);
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
   Inc(i, 2);
  end;
  if k <> dim then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_Read_CONFIG_A]);
  MemAddr := $300000 shl 1;
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := MemAddr shr 16;
  Inc(j);
  bufferU[j] := (MemAddr shr 8) and $FF;
  Inc(j);
  bufferU[j] := MemAddr and $FF;
  Inc(j);
  k2 := 0;
  for i := 0 to (CONFIGlen) - 1 do
  begin
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   if (((j + 1) div 2) * 3 + 3 > 64) or (i = CONFIGlen - 1) then
   begin
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to (64 - 2) - 1 do
    begin
     if bufferI[z] = $58 then
     begin
      memCONFIG[k2] := bufferI[z + 2];
      Inc(k2);
      if CONFIGorg = 0 then
       memCONFIG[k2] := bufferI[z + 1];
       Inc(k2);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((dim + sizeEE + i + UIDlen + DIAlen) * 100) div (dim + sizeEE + CONFIGlen + UIDlen + DIAlen), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if CONFIGorg = 0 then
   CONFIGlen := CONFIGlen * 2;
  if k2 <> CONFIGlen then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadConfigErr], CONFIGlen, k2);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, 'Read user ID' + NL + '');
  MemAddr := $200000 shl 1;
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := MemAddr shr 16;
  Inc(j);
  bufferU[j] := (MemAddr shr 8) and $FF;
  Inc(j);
  bufferU[j] := MemAddr and $FF;
  Inc(j);
  k2 := 0;
  i := 0;
  while i < UIDlen do
  begin
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   if (((j + 1) div 2) * 3 + 3 > 64) or (i = UIDlen - 2) then
   begin
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to (64 - 2) - 1 do
    begin
     if bufferI[z] = $58 then
     begin
      memID[k2] := bufferI[z + 2];
      Inc(k2);
      memID[k2] := bufferI[z + 1];
      Inc(k2);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((dim + sizeEE + 10 + i + DIAlen) * 100) div (dim + sizeEE + 10 + UIDlen + DIAlen), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
   Inc(i, 2);
  end;
  if k2 <> UIDlen then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadConfigErr], UIDlen, k2);
   PrintMessage(str);
  end;
  if DIAaddr > 0 then
  begin
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, 'Read device info area' + NL + '');
   MemAddr := DIAaddr shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   k2 := 0;
   i := 0;
   while i < DIAlen do
   begin
    bufferU[j] := $58;
    Inc(j);
    bufferU[j] := $FE;
    Inc(j);
    if (((j + 1) div 2) * 3 + 3 > 64) or (i = DIAlen - 2) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to (64 - 2) - 1 do
     begin
      if bufferI[z] = $58 then
      begin
       memDIA[k2] := bufferI[z + 2];
       Inc(k2);
       memDIA[k2] := bufferI[z + 1];
       Inc(k2);
       z := z + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((dim + sizeEE + 10 + UIDlen + i) * 100) div (dim + sizeEE + 10 + UIDlen + DIAlen), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
    Inc(i, 2);
   end;
   if k2 <> DIAlen then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadConfigErr], DIAlen, k2);
    PrintMessage(str);
   end;
  end;
  if dim2 then
  begin
   if (sizeEE > $1000) or (sizeEE < 0) then
   begin
    PrintMessage(strings[S_EELim]);
    Exit;
   end;
   if memEE then
    free(memEE);
   memEE := malloc(sizeEE);
   for i := 0 to (sizeEE) - 1 do
   begin
    memEE[i] := $FF;
   end;
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ReadEE]);
   MemAddr := EEaddr shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   k := 0;
   for i := k to (sizeEE) - 1 do
   begin
    bufferU[j] := $58;
    Inc(j);
    bufferU[j] := $FE;
    Inc(j);
    if (((j + 1) div 2) * 3 + 3 > 64) or (i = sizeEE - 1) then
    begin
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to (64 - 2) - 1 do
     begin
      if bufferI[z] = $58 then
      begin
       memEE[k] := bufferI[z + 2];
       Inc(k);
       z := z + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((dim + i + 10 + UIDlen + DIAlen) * 100) div (dim + sizeEE + 10 + UIDlen + DIAlen), i);
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
   if k <> sizeEE then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadEEErr], sizeEE, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
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
  PacketIO(1);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  PrintMessage(strings[S_ConfigMem]);
  i := 0;
  while i < UIDlen do
  begin
   if (memID[i] < $FF) or (memID[i + 1] < $FF) then
   begin
    sprintf(str, strings[S_ChipID2], i, memID[i], i + 1, memID[i + 1]);
    PrintMessage(str);
   end;
   Inc(i, 2);
  end;
  if CONFIGorg = 0 then
  begin
   for i := 0 to (CONFIGlen) - 1 do
   begin
    sprintf(str, strings[S_ConfigWordH], i + 1, memCONFIG[i * 2 + 1]);
    PrintMessage(str);
    sprintf(str, strings[S_ConfigWordL], i + 1, memCONFIG[i * 2]);
    PrintMessage(str);
   end;
  end
  else
  begin
   for i := 0 to (CONFIGlen) - 1 do
   begin
    if (type_ = 5) and (i >= $B) and (i <= $17) then
    else
    begin
     sprintf(str, 'CONFIG%d: 0x%02X' + #13 + '' + NL + '', i + 1, memCONFIG[i]);
     PrintMessage(str);
    end;
   end;
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE18F(dim);
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

function Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  x: Integer;
  w: Integer;
  err: Integer;
  devID: Integer;
  devREV: Integer;
  MemAddr: Integer;
  rowN: Integer;
  EEaddr: Integer;
  DCIaddr: Integer;
  DIAaddr: Integer;
  DIAlen: Integer;
  UIDlen: Integer;
  CONFIGlen: Integer;
  CONFIGorg: Integer;
  delayErase: Integer;
  delayWrite: Integer;
  delayWriteConfig: Integer;
  type_: Integer;
  vpp: Double;
  start: Cardinal;
  valid: Integer;
  errEE: Integer;
  errID: Integer;
  errC: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  x := 0;
  w := 0;
  err := 0;
  devID := 0;
  devREV := 0;
  rowN := 0;
  EEaddr := 0;
  DCIaddr := 0;
  DIAaddr := 0;
  DIAlen := 0;
  UIDlen := 0;
  CONFIGlen := 0;
  CONFIGorg := 0;
  delayErase := 0;
  delayWrite := 0;
  delayWriteConfig := 0;
  type_ := (options shr 4) and $F;
  if type_ = 0 then
  begin
   EEaddr := $310000;
   DCIaddr := $3FFF00;
   DIAaddr := $3F0000;
   DIAlen := $40;
   UIDlen := $10;
   CONFIGlen := 5;
   CONFIGorg := 0;
   delayErase := 25500;
   delayWrite := 2800;
   delayWriteConfig := 5600;
  end
  else
   if type_ = 1 then
   begin
    EEaddr := $380000;
    DCIaddr := $3C0000;
    DIAaddr := $2C0000;
    DIAlen := $100;
    UIDlen := $40;
    CONFIGlen := 10;
    CONFIGorg := 1;
    delayErase := 11500;
    delayWriteConfig := 11000;
   end
   else
    if type_ = 2 then
    begin
     EEaddr := $380000;
     DCIaddr := $3C0000;
     DIAaddr := $2C0000;
     DIAlen := $100;
     UIDlen := $40;
     CONFIGlen := 35;
     CONFIGorg := 1;
     delayErase := 11500;
     delayWriteConfig := 11000;
    end
    else
     if type_ = 3 then
     begin
      EEaddr := $310000;
      DCIaddr := 0;
      DIAaddr := 0;
      DIAlen := 0;
      UIDlen := 8;
      CONFIGlen := 6;
      CONFIGorg := 0;
      rowN := 32;
      delayErase := 25500;
      delayWrite := 2800;
      delayWriteConfig := 5600;
     end
     else
      if type_ = 4 then
      begin
       EEaddr := $310000;
       DCIaddr := 0;
       DIAaddr := 0;
       DIAlen := 0;
       UIDlen := $100;
       CONFIGlen := 6;
       CONFIGorg := 2;
       delayErase := 75500;
       delayWrite := 11000;
       delayWriteConfig := 11000;
      end
      else
       if type_ = 5 then
       begin
        EEaddr := $380000;
        DCIaddr := $3C0000;
        DIAaddr := $2C0000;
        DIAlen := $100;
        UIDlen := $40;
        CONFIGlen := 11;
        CONFIGorg := 1;
        delayErase := 11500;
        delayWriteConfig := 11000;
       end
       else
        PrintMessage('unexpected parameter');
  if (dim > $1FFFFF) or (dim < 0) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim2 > $800) or (dim2 < 0) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write18FKx(%d,%d,%d)    (0x%X,0x%X,0x%X)' + NL + '', dim, dim2, options, dim, dim2, options);
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
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := 35;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 11000 shr 8;
  Inc(j);
  bufferU[j] := 11000 and $ff;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  MemAddr := $3FFFFc shl 1;
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := MemAddr shr 16;
  Inc(j);
  bufferU[j] := (MemAddr shr 8) and $FF;
  Inc(j);
  bufferU[j] := MemAddr and $FF;
  Inc(j);
  bufferU[j] := $58;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $58;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  if DCIaddr > 0 then
  begin
   MemAddr := DCIaddr shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
   bufferU[j] := $58;
   Inc(j);
   bufferU[j] := $FE;
   Inc(j);
  end;
  bufferU[j] := $39;
  Inc(j);
  bufferU[j] := 2;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0;
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
  PacketIO(14);
  z := 0;
  while (bufferI[z] <> $58) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   devREV := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  end;
  z := 3;
  while (bufferI[z] <> $58) and (z < 64) do
  begin
   Inc(z);
  end;
  if z < 64 - 2 then
  begin
   devID := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  end;
  sprintf(str, 'DevID: 0x%04X' + #13 + '' + NL + '', devID);
  PrintMessage(str);
  sprintf(str, 'RevID: 0x%04X' + #13 + '' + NL + '', devREV);
  PrintMessage(str);
  PIC18_ID(devID + (devREV shl 16));
  if DCIaddr > 0 then
  begin
   PrintMessage('Device Configuration Information:' + #13 + '' + NL + '');
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'Erase row size: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    rowN := (bufferI[z + 1] shl 8) + bufferI[z + 2];
    sprintf(str, 'Write latches per row: %d' + #13 + '' + NL + '', rowN);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'User rows: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 2 then
   begin
    sprintf(str, 'EEPROM size: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
   z := 3;
   while (bufferI[z] <> $58) and (z < 64) do
   begin
    Inc(z);
   end;
   if z < 64 - 3 then
   begin
    sprintf(str, 'Pin count: %d' + #13 + '' + NL + '', (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    PrintMessage(str);
   end;
  end;
  j := 0;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
  begin
   fprintf(logfile, strings[S_sepLine]);
   fprintf(logfile, strings[S_StartErase]);
   fprintf(logfile, strings[S_NL]);
  end;
  if (type_ = 0) or (type_ = 3) or (type_ = 4) then
  begin
   bufferU[j] := $07;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := delayErase shr 8;
   Inc(j);
   bufferU[j] := delayErase and $ff;
   Inc(j);
   MemAddr := $300000 shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   bufferU[j] := $57;
   Inc(j);
   bufferU[j] := $18;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   MemAddr := $310000 shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   bufferU[j] := $57;
   Inc(j);
   bufferU[j] := $18;
   Inc(j);
   bufferU[j] := $0A;
   Inc(j);
   bufferU[j] := $07;
   Inc(j);
   bufferU[j] := 1;
   Inc(j);
   bufferU[j] := delayWrite shr 8;
   Inc(j);
   bufferU[j] := delayWrite and $ff;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO((delayErase div 1000) * 2);
  end
  else
   if (type_ = 1) or (type_ = 2) or (type_ = 5) then
   begin
    bufferU[j] := $59;
    Inc(j);
    bufferU[j] := $18;
    Inc(j);
    bufferU[j] := 0;
    Inc(j);
    bufferU[j] := $F;
    Inc(j);
    bufferU[j] := $07;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := delayWriteConfig shr 8;
    Inc(j);
    bufferU[j] := delayWriteConfig and $ff;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(1);
    msDelay(delayErase div 1000);
   end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
  begin
   fprintf(logfile, strings[S_sepLine]);
   fprintf(logfile, 'WRITE CODE' + NL + 'dim=%d(0x%X)' + NL + '', dim, dim);
  end;
  if (type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5) then
  begin
   j := 0;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := $0;
   Inc(j);
   bufferU[j] := $0;
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
   k := 0;
   k := 0;
   i := k;
   while i < dim do
   begin
    if (memCODE[i] < $FF) or (memCODE[i + 1] < $FF) then
    begin
     bufferU[j] := $59;
     Inc(j);
     bufferU[j] := $C0;
     Inc(j);
     bufferU[j] := memCODE[i + 1];
     Inc(j);
     bufferU[j] := memCODE[i];
     Inc(j);
     bufferU[j] := $09;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $FE;
     Inc(j);
    end
    else
    begin
     x := 0;
     while (i + x < dim) and (memCODE[i + x] = $FF) and (memCODE[i + x + 1] = $FF) do
     begin
      Inc(x, 2);
     end;
     if x > 9 then
     begin
      i := i + x;
      MemAddr := i shl 1;
      bufferU[j] := $39;
      Inc(j);
      bufferU[j] := 2;
      Inc(j);
      bufferU[j] := $80;
      Inc(j);
      bufferU[j] := MemAddr shr 16;
      Inc(j);
      bufferU[j] := (MemAddr shr 8) and $FF;
      Inc(j);
      bufferU[j] := MemAddr and $FF;
      Inc(j);
      i := i - 2;
     end
     else
     begin
      bufferU[j] := $57;
      Inc(j);
      bufferU[j] := $F8;
      Inc(j);
     end;
    end;
    if (j > 64 - 8) or (i = dim - 2) then
    begin
     sprintf(str, strings[S_CodeWriting], (i * 100) div (dim + dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     for z := 0 to (64 - 4) - 1 do
     begin
      if (bufferI[z] = $57) and (memCODE[k] = $ff) and (memCODE[k + 1] = $ff) then
       k := k + 2
      else
       if bufferI[z] = $39 then
       begin
        while (k < dim) and (memCODE[k] = $FF) and (memCODE[k + 1] = $FF) do
        begin
         Inc(k, 2);
        end;
       end
       else
        if (bufferI[z] = $59) and (bufferI[z + 2] = $58) then
        begin
         if (memCODE[k] <> bufferI[z + 4]) or (memCODE[k + 1] <> bufferI[z + 3]) then
         begin
          PrintMessage('' + #13 + '' + NL + '');
          sprintf(str, strings[S_CodeWError2], k, (memCODE[k + 1] shl 8) + memCODE[k], (bufferI[z + 3] shl 8) + bufferI[z + 4]);
          PrintMessage(str);
          Inc(err);
          if max_err and (err > max_err) then
          begin
           sprintf(str, strings[S_MaxErr], err);
           PrintMessage(str);
           i := dim;
           z := 64;
          end;
         end;
         k := k + 2;
         z := z + 4;
        end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i, 2);
   end;
   err := err + i - k;
  end
  else
   if (type_ = 0) or (type_ = 3) then
   begin
    while (dim > 0) and (memCODE[dim - 1] = $ff) and (memCODE[dim - 2] = $ff) do
    begin
     Dec(dim, 2);
    end;
    if dim mod rowN then
     dim := dim + rowN - dim mod rowN;
    if dim > size then
    begin
     memCODE := realloc(memCODE, dim);
     while size < dim do
     begin
      memCODE[size] := $FF;
      Inc(size);
     end;
    end;
    k := 0;
    k := 0;
    j := 0;
    i := k;
    while i < dim do
    begin
     valid := 0;
     while (i < dim) and not (valid) do
     begin
      valid := 0;
      for k := 0 to (rowN) - 1 do
      begin
       if memCODE[i + k] < $ff then
       begin
        valid := 1;
        k := rowN;
       end;
      end;
      Inc(i, IfThen(valid, 0, rowN));
     end;
     MemAddr := i shl 1;
     bufferU[j] := $39;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     bufferU[j] := MemAddr shr 16;
     Inc(j);
     bufferU[j] := (MemAddr shr 8) and $FF;
     Inc(j);
     bufferU[j] := MemAddr and $FF;
     Inc(j);
     k := 0;
     while k < rowN do
     begin
      bufferU[j] := $59;
      Inc(j);
      bufferU[j] := IfThen(k < rowN - 2, $02, $00);
      Inc(j);
      bufferU[j] := memCODE[i + k + 1];
      Inc(j);
      bufferU[j] := memCODE[i + k];
      Inc(j);
      if j > 64 - 5 then
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
      end;
      Inc(k, 2);
     end;
     if i < dim then
     begin
      bufferU[j] := $57;
      Inc(j);
      bufferU[j] := $E0;
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
      PacketIO(6);
      j := 0;
      if saveLog then
      begin
       fprintf(logfile, strings[S_Log7], i, i, 0, 0);
      end;
      sprintf(str, strings[S_CodeWriting], (i * 100) div (dim * 2 + dim2), i);
      gtk_statusbar_push(status_bar, statusID, str);
      while gtk_events_pending() do
      begin
       gtk_main_iteration();
      end;
     end;
     Inc(i, rowN);
    end;
    PrintMessage(strings[S_Compl]);
    PrintMessage(strings[S_CodeV]);
    if saveLog then
    begin
     fprintf(logfile, strings[S_sepLine]);
     fprintf(logfile, '%s' + NL + '', strings[S_CodeV]);
    end;
    j := 0;
    bufferU[j] := $39;
    Inc(j);
    bufferU[j] := 2;
    Inc(j);
    bufferU[j] := $80;
    Inc(j);
    bufferU[j] := $0;
    Inc(j);
    bufferU[j] := $0;
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
    k := 0;
    k := 0;
    i := k;
    while i < dim do
    begin
     if j = 0 then
     begin
      x := 0;
      while (i + x < dim) and (memCODE[i + x] = $FF) and (memCODE[i + x + 1] = $FF) do
      begin
       Inc(x, 2);
      end;
      if x > 9 then
      begin
       i := i + x;
       k := i;
       MemAddr := i shl 1;
       bufferU[j] := $39;
       Inc(j);
       bufferU[j] := 2;
       Inc(j);
       bufferU[j] := $80;
       Inc(j);
       bufferU[j] := MemAddr shr 16;
       Inc(j);
       bufferU[j] := (MemAddr shr 8) and $FF;
       Inc(j);
       bufferU[j] := MemAddr and $FF;
       Inc(j);
      end;
     end;
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $FE;
     Inc(j);
     if (((j + 1) div 2) * 3 + 3 > 64) or (i = dim - 2) then
     begin
      bufferU[j] := $04;
      Inc(j);
      while j < 64 do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(2);
      for z := 0 to (64 - 2) - 1 do
      begin
       if bufferI[z] = $58 then
       begin
        if (memCODE[k] <> bufferI[z + 2]) or (memCODE[k + 1] <> bufferI[z + 1]) then
        begin
         sprintf(str, strings[S_CodeWError2], k, memCODE[k] + (memCODE[k + 1] shl 8), (bufferI[z + 1] shl 8) + bufferI[z + 2]);
         PrintMessage(str);
         Inc(err);
        end;
        z := z + 2;
        k := k + 2;
       end;
      end;
      sprintf(str, strings[S_CodeV2], ((i + dim) div (dim * 2 + dim2)) * 100, i);
      gtk_statusbar_push(status_bar, statusID, str);
      while gtk_events_pending() do
      begin
       gtk_main_iteration();
      end;
      j := 0;
      if saveLog then
      begin
       fprintf(logfile, strings[S_Log8], i, i, k, k, err);
      end;
      if err >= max_err then
      begin
       sprintf(str, strings[S_MaxErr], err);
       PrintMessage(str);
       i := dim;
      end;
     end;
     Inc(i, 2);
    end;
    bufferU[j] := $07;
    Inc(j);
    bufferU[j] := 1;
    Inc(j);
    bufferU[j] := delayWriteConfig shr 8;
    Inc(j);
    bufferU[j] := delayWriteConfig and $ff;
    Inc(j);
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
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, 'WRITE EEPROM' + NL + 'dim2=%d(0x%X)' + NL + '', dim2, dim2);
   end;
   errEE := 0;
   j := 0;
   MemAddr := EEaddr shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   k := 0;
   for i := k to (dim2) - 1 do
   begin
    if memEE[i] < $FF then
    begin
     if (type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5) then
     begin
      bufferU[j] := $59;
      Inc(j);
      bufferU[j] := $C0;
      Inc(j);
      bufferU[j] := 0;
      Inc(j);
      bufferU[j] := memEE[i];
      Inc(j);
     end
     else
      if (type_ = 0) or (type_ = 3) then
      begin
       bufferU[j] := $59;
       Inc(j);
       bufferU[j] := $00;
       Inc(j);
       bufferU[j] := 0;
       Inc(j);
       bufferU[j] := memEE[i];
       Inc(j);
       bufferU[j] := $57;
       Inc(j);
       bufferU[j] := $E0;
       Inc(j);
      end;
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $FE;
     Inc(j);
     Inc(w);
    end
    else
    begin
     bufferU[j] := $57;
     Inc(j);
     bufferU[j] := $F8;
     Inc(j);
    end;
    if (j > 64 - 8) or (i = dim2 - 1) then
    begin
     sprintf(str, strings[S_CodeWriting], ((i + dim) * 100) div (dim + dim2), i + EEaddr);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     w := w * (delayWriteConfig div 1000.0);
     PacketIO(w + 10);
     for z := 0 to (64 - 4) - 1 do
     begin
      if (bufferI[z] = $57) and (memEE[k] = $ff) then
       Inc(k)
      else
       if bufferI[z] = $59 then
       begin
        w := IfThen((type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5), bufferI[z + 4], bufferI[z + 5]);
        if memEE[k] <> w then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError2], k, memEE[k], w);
         PrintMessage(str);
         Inc(errEE);
         if max_err and (err + errEE > max_err) then
         begin
          sprintf(str, strings[S_MaxErr], err + errEE);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := dim2;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + IfThen((type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5), 4, 5);
       end;
     end;
     j := 0;
     w := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
   end;
   errEE := errEE + i - k;
   err := err + errEE;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
  end;
  if programID then
  begin
   PrintMessage(strings[S_IDW]);
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, 'Write ID' + NL + '');
   end;
   errID := 0;
   j := 0;
   MemAddr := $200000 shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   k := 0;
   k := 0;
   i := k;
   while i < UIDlen do
   begin
    if (memID[i] < $FF) or (memID[i + 1] < $FF) then
    begin
     if (type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5) then
     begin
      bufferU[j] := $59;
      Inc(j);
      bufferU[j] := $C0;
      Inc(j);
      bufferU[j] := memID[i + 1];
      Inc(j);
      bufferU[j] := memID[i];
      Inc(j);
     end
     else
      if (type_ = 0) or (type_ = 3) then
      begin
       bufferU[j] := $59;
       Inc(j);
       bufferU[j] := $00;
       Inc(j);
       bufferU[j] := memID[i + 1];
       Inc(j);
       bufferU[j] := memID[i];
       Inc(j);
       bufferU[j] := $57;
       Inc(j);
       bufferU[j] := $E0;
       Inc(j);
      end;
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $FE;
     Inc(j);
    end
    else
    begin
     bufferU[j] := $57;
     Inc(j);
     bufferU[j] := $F8;
     Inc(j);
    end;
    if (j > 64 - 8) or (i = UIDlen - 2) then
    begin
     sprintf(str, strings[S_CodeWriting], 99, $200000 + i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO((9 * delayWriteConfig) div 1000 + 2);
     for z := 0 to (64 - 4) - 1 do
     begin
      if (bufferI[z] = $57) and (memID[k] = $ff) and (memID[k + 1] = $ff) then
       k := k + 2
      else
       if bufferI[z] = $59 then
       begin
        if (type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5) then
         w := (bufferI[z + 3] shl 8) + bufferI[z + 4]
        else
         if (type_ = 0) or (type_ = 3) then
          w := (bufferI[z + 4] shl 8) + bufferI[z + 5];
        x := (memID[k + 1] shl 8) + memID[k];
        if x <> w then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError2], k, x, w);
         PrintMessage(str);
         Inc(errID);
         if max_err and (err + errID > max_err) then
         begin
          sprintf(str, strings[S_MaxErr], err + errID);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := UIDlen;
          z := 64;
         end;
        end;
        k := k + 2;
        z := z + IfThen((type_ = 1) or (type_ = 2) or (type_ = 4) or (type_ = 5), 4, 5);
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errID);
     end;
    end;
    Inc(i, 2);
   end;
   errID := errID + i - k;
   err := err + errID;
   sprintf(str, strings[S_ComplErr], errID);
   PrintMessage(str);
  end;
  if err < max_err then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, 'Write CONFIG' + NL + '');
   end;
   errC := 0;
   j := 0;
   MemAddr := $300000 shl 1;
   bufferU[j] := $39;
   Inc(j);
   bufferU[j] := 2;
   Inc(j);
   bufferU[j] := $80;
   Inc(j);
   bufferU[j] := MemAddr shr 16;
   Inc(j);
   bufferU[j] := (MemAddr shr 8) and $FF;
   Inc(j);
   bufferU[j] := MemAddr and $FF;
   Inc(j);
   k := 0;
   for i := k to (CONFIGlen) - 1 do
   begin
    if CONFIGorg = 0 then
    begin
     bufferU[j] := $59;
     Inc(j);
     bufferU[j] := $00;
     Inc(j);
     bufferU[j] := memCONFIG[i * 2 + 1];
     Inc(j);
     bufferU[j] := memCONFIG[i * 2];
     Inc(j);
     bufferU[j] := $57;
     Inc(j);
     bufferU[j] := $E0;
     Inc(j);
    end
    else
     if CONFIGorg = 1 then
     begin
      bufferU[j] := $59;
      Inc(j);
      bufferU[j] := $C0;
      Inc(j);
      bufferU[j] := 0;
      Inc(j);
      bufferU[j] := memCONFIG[i];
      Inc(j);
     end
     else
      if CONFIGorg = 2 then
      begin
       bufferU[j] := $59;
       Inc(j);
       bufferU[j] := $C0;
       Inc(j);
       bufferU[j] := memCONFIG[i * 2 + 1];
       Inc(j);
       bufferU[j] := memCONFIG[i * 2];
       Inc(j);
      end;
    bufferU[j] := $0A;
    Inc(j);
    bufferU[j] := $58;
    Inc(j);
    bufferU[j] := $FE;
    Inc(j);
    if (j > 64 - 8) or (i = CONFIGlen - 1) then
    begin
     sprintf(str, strings[S_CodeWriting], 99, i + $300000);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO((9 * delayWriteConfig) div 1000.0 + 2);
     for z := 0 to (64 - 4) - 1 do
     begin
      if bufferI[z] = $59 then
      begin
       if CONFIGorg = 1 then
       begin
        w := bufferI[z + 4];
        x := memCONFIG[k];
       end
       else
        if CONFIGorg = 2 then
        begin
         w := (bufferI[z + 3] shl 8) + bufferI[z + 4];
         x := (memCONFIG[k + 1] shl 8) + memCONFIG[k];
        end
        else
         if CONFIGorg = 0 then
         begin
          w := (bufferI[z + 4] shl 8) + bufferI[z + 5];
          x := (memCONFIG[k + 1] shl 8) + memCONFIG[k];
         end;
       if not (x) and w then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k + $300000, x, w);
        PrintMessage(str);
        Inc(errC);
        if max_err and (err + errC > max_err) then
        begin
         sprintf(str, strings[S_MaxErr], err + errC);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim2;
         z := 64;
        end;
       end;
       if CONFIGorg = 1 then
       begin
        Inc(k);
        z := z + 4;
       end
       else
        if CONFIGorg = 2 then
        begin
         k := k + 2;
         z := z + 4;
        end
        else
         if CONFIGorg = 0 then
         begin
          k := k + 2;
          z := z + 5;
         end;
      end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errC);
     end;
    end;
   end;
   if CONFIGorg = 1 then
    errC := errC + CONFIGlen - k
   else
    errC := errC + CONFIGlen * 2 - k;
   err := err + errC;
   if useSAFLOCK_flag and (type_ = 5) and (memCONFIG[$18] <> $FF) and (err > 0) then
    PrintMessage(strings[S_SkipSaflock]);
   if useSAFLOCK_flag and (type_ = 5) and (memCONFIG[$18] <> $FF) and (err = 0) then
   begin
    PrintMessage('' + #13 + '' + NL + 'Write SAFLOCK');
    if saveLog then
    begin
     fprintf(logfile, strings[S_sepLine]);
     fprintf(logfile, 'Write SAFLOCK' + NL + '');
    end;
    errC := 0;
    if memCONFIG[$19] <> $FF then
    begin
     errC := 1;
     j := 0;
     MemAddr := $300019 shl 1;
     bufferU[j] := $39;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     bufferU[j] := MemAddr shr 16;
     Inc(j);
     bufferU[j] := (MemAddr shr 8) and $FF;
     Inc(j);
     bufferU[j] := MemAddr and $FF;
     Inc(j);
     bufferU[j] := $59;
     Inc(j);
     bufferU[j] := $C0;
     Inc(j);
     bufferU[j] := 0;
     Inc(j);
     bufferU[j] := memCONFIG[$19];
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $FE;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(delayWriteConfig div 1000.0 + 2);
     for z := 0 to (64 - 4) - 1 do
     begin
      if bufferI[z] = $59 then
      begin
       w := bufferI[z + 4];
       x := memCONFIG[$19];
       if not (x) and w then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], $300019, x, w);
        PrintMessage(str);
        PrintMessage(strings[S_IntW]);
       end
       else
        errC := 0;
       z := 64 * 2;
      end;
     end;
     err := err + errC;
    end;
    if errC > 0 then
     PrintMessage(strings[S_SkipSaflock])
    else
    begin
     errC := 1;
     j := 0;
     MemAddr := $300018 shl 1;
     bufferU[j] := $39;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := $80;
     Inc(j);
     bufferU[j] := MemAddr shr 16;
     Inc(j);
     bufferU[j] := (MemAddr shr 8) and $FF;
     Inc(j);
     bufferU[j] := MemAddr and $FF;
     Inc(j);
     bufferU[j] := $39;
     Inc(j);
     bufferU[j] := 2;
     Inc(j);
     bufferU[j] := $4C;
     Inc(j);
     bufferU[j] := $4F;
     Inc(j);
     bufferU[j] := $43;
     Inc(j);
     bufferU[j] := $4B;
     Inc(j);
     bufferU[j] := $59;
     Inc(j);
     bufferU[j] := $C0;
     Inc(j);
     bufferU[j] := 0;
     Inc(j);
     bufferU[j] := memCONFIG[$18];
     Inc(j);
     bufferU[j] := $0A;
     Inc(j);
     bufferU[j] := $58;
     Inc(j);
     bufferU[j] := $FE;
     Inc(j);
     bufferU[j] := $04;
     Inc(j);
     while j < 64 do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(delayWriteConfig div 1000.0 + 2);
     for z := 0 to (64 - 4) - 1 do
     begin
      if bufferI[z] = $58 then
      begin
       w := bufferI[z + 2];
       x := memCONFIG[$18];
       if not (x) and w then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], $300018, x, w);
        PrintMessage(str);
        PrintMessage(strings[S_IntW]);
       end
       else
        errC := 0;
       z := 64 * 2;
      end;
     end;
     err := err + errC;
    end;
   end;
   sprintf(str, strings[S_ComplErr], errC);
   PrintMessage(str);
  end;
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0F;
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
  PacketIO(1);
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

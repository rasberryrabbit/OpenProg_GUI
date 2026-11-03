unit icd;

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
  coff,
  glib_types,
  gtk_types,
  libc_types,
  sys_types;

const
  NL = #10;
  Tck = 30;
  VER = 1;
  STEP = 2;
  GO = 3;
  RREG = 4;
  WREG = 5;
  EEADR = $10D;
  EEADRH = $10F;
  EEDATA = $10C;
  EEDATH = $10E;
  EECON1 = $18C;
  EECON2 = $18D;
  w_temp = $6B;
  status_temp = $6C;
  pclath_temp = $6D;
  fsr_temp = $6E;
  LINES_BEFORE = 5;
  LINES_AFTER = 7;
  NLINES = LINES_BEFORE + LINES_AFTER;
  LISTLINES = 10;

const
  VER = 1;
  STEP = 2;
  GO = 3;
  RREG = 4;
  WREG = 5;
  EEADR = $10D;
  EEADRH = $10F;
  EEDATA = $10C;
  EEDATH = $10E;
  EECON1 = $18C;
  EECON2 = $18D;
  w_temp = $6B;
  status_temp = $6C;
  pclath_temp = $6D;
  fsr_temp = $6E;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

  Tvar = record
    name_: PChar;
    display: Integer;
  end;

type
  TGSourceFunc = ^TProcedure;

var
  saveLog: Integer;
  Tcom: Double;
  running: Integer;
  DeviceDetected: Integer;
  b_log: ^TControl;
  cur_path: PChar;
  statusTxt: ^TControl;
  sourceTxt: ^TControl;
  sourceBuf: ^TMemo;
  icdVbox1: ^TControl;
  icdMenuPC: ^TControl;
  icdMenuSTAT: ^TControl;
  icdMenuBank0: ^TControl;
  icdMenuBank1: ^TControl;
  icdMenuBank2: ^TControl;
  icdMenuBank3: ^TControl;
  icdMenuEE: ^TControl;
  icdCommand: ^TControl;
  statusBuf: ^TMemo;
  icdTimer: Integer;
  break_addr: Integer;
  print_addr: Integer;
  currentSource: Integer;
  sourceHilight: Integer;
  lastCmd: array[0..64-1] of Char;
  UseCoff: Integer;
  source_info: array[0..0x2200-1] of Tsrc_i;
  s_files: ^Tsrcfile;
  sym: ^Tsymbol;
  nsym: Integer;
  Slabel: array[0..0x2200-1] of PChar;
  Sulabel: array[0..0x400-1] of PChar;
  watch: ^Tsymbol;
  nwatch: Integer;
  coff_data: array[0..0x2200-1] of Word;
  ver: Integer;
  reset: Integer;
  freeze: Integer;
  icdConnected: Integer;
  variables: array[0..0x200-1] of Tvar;

  variables: array[0..$200-1] of Tvar;

// --- function declarations ---
procedure ShowContext;
function startICD(tck: Integer): Pointer;
function isRunning: Integer;
function cont(break_addr: Integer; freeze: Integer): Pointer;
procedure step;
procedure run;
function version: Integer;
procedure Halt_;
function ReadRegister(addr: Integer): Integer;
function ReadRegisterN(addr: Integer; n: Integer; buf: ^Integer): Integer;
function WriteRegister(addr: Integer; data: Integer): Pointer;
function ReadProgMem(addr: Integer): Integer;
function ReadProgMemN(addr: Integer; n: Integer; buf: ^Integer): Integer;
function ReadDataMem(addr: Integer): Integer;
function ReadDataMemN(addr: Integer; n: Integer; buf: PByte): Integer;
function getVar(addr: Integer; var_: PChar): PChar;
function decodeCmd(cmd: Integer; str: PChar; addrH: Integer): PChar;
function PrintMessageICD(msg: PChar): Pointer;
function AppendMessageICD(msg: PChar): Pointer;
function scrollToLine(line: Integer): Pointer;
function SourceHilightLine(line: Integer): Pointer;
function SourceRemoveHilightLine(line: Integer): Pointer;
function loadSource(f: ^TextFile): Integer;
function loadCoff(widget: ^TControl; window: ^TControl): Pointer;
procedure initVar;
function ICDHelp(widget: ^TControl; window: ^TControl): Pointer;
function icdCheck(widget: ^TControl; window: ^TControl): Pointer;
function icdRun(widget: ^TControl; window: ^TControl): Pointer;
function icdHalt(widget: ^TControl; window: ^TControl): Pointer;
function icdStep(widget: ^TControl; window: ^TControl): Pointer;
function icdStepOver(widget: ^TControl; window: ^TControl): Pointer;
function icdStop(widget: ^TControl; window: ^TControl): Pointer;
function icdRefresh(widget: ^TControl; window: ^TControl): Pointer;
function ShowBank(bank: Integer; status: PChar): Pointer;
procedure ShowContext;
function addWatch(s: Tsymbol): Integer;
function executeCommand(command: PChar): Integer;
function removeWatch(name_: PChar): Integer;
function source_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
function icdStatus_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
function icdCommand_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
function icd_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;

implementation

function startICD(tck: Integer): Pointer;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := tck;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(3);
  if saveLog then
  begin
   fprintf(logfile, 'startICD()' + NL + '');
  end;
end;

function isRunning: Integer;
var
  z: Integer;
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $10;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, 'isRunning()' + NL + '');
  end;
  z := 0;
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($10)) do
  begin
   Inc(z);
  end;
  if (bufferI[(z) + (1)]) and (1) then
   running := 0
  else
   running := 1;
  Exit(running);
end;

function cont(break_addr: Integer; freeze: Integer): Pointer;
var
  j: Integer;
begin
  j := 0;
  break_addr := break_addr and $1FFF;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := ((break_addr) shr (8)) + (IfThen(freeze, $40, 0));
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $8E;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (break_addr) and ($FF);
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $8F;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((5) * (Tcom)));
  if saveLog then
  begin
   fprintf(logfile, 'continue()' + NL + '');
  end;
  running := 1;
end;

procedure step;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + (Tcom));
  if saveLog then
  begin
   fprintf(logfile, 'step()' + NL + '');
  end;
end;

procedure run;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, 'run()' + NL + '');
  end;
  running := 1;
end;

function version: Integer;
var
  j: Integer;
  z: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $3A;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((2) * (Tcom)));
  if saveLog then
  begin
   fprintf(logfile, 'version()' + NL + '');
  end;
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($3A)) do
  begin
   Inc(z);
  end;
  Exit(bufferI[(z) + (3)]);
end;

procedure Halt_;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $6;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, 'halt()' + NL + '');
  end;
  running := 0;
end;

function ReadRegister(addr: Integer): Integer;
var
  j: Integer;
  z: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := ((addr) shr (8)) and ($FF);
  bufferU[Inc(j)] := (addr) and ($FF);
  bufferU[Inc(j)] := $3A;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((3) * (Tcom)));
  if saveLog then
  begin
   fprintf(logfile, 'ReadRegister(0x%X)' + NL + '', addr);
  end;
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($3A)) do
  begin
   Inc(z);
  end;
  Exit(bufferI[(z) + (3)]);
end;

function ReadRegisterN(addr: Integer; n: Integer; buf: ^Integer): Integer;
var
  i: Integer;
  j: Integer;
  z: Integer;
  w: Integer;
begin
  j := 0;
  i := 0;
  while (i) < (n) do
  begin
   w := IfThen(((i) + (((64) - (9)) div (2))) < (n), ((64) - (9)) div (2), (n) - (i));
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $2;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := w;
   bufferU[Inc(j)] := ((addr) + (i)) shr (8);
   bufferU[Inc(j)] := ((addr) + (i)) and ($FF);
   bufferU[Inc(j)] := $3A;
   bufferU[Inc(j)] := w;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO((1) + (((w) + (2)) * (Tcom)));
   if saveLog then
   begin
    fprintf(logfile, 'ReadRegisterN(0x%X,%d)' + NL + '', addr, n);
   end;
   z := 0;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($3A)) do
   begin
    Inc(z);
   end;
   for j := 0 to (w) - 1 do
   begin
    buf[(i) + (j)] := bufferI[((z) + (3)) + ((j) * (2))];
   end;
   j := 0;
   Inc(i, w);
  end;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  Exit(IfThen((i) = (n), 0, -(1)));
end;

function WriteRegister(addr: Integer; data: Integer): Pointer;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (data) and ($FF);
  bufferU[Inc(j)] := ((addr) shr (8)) and ($FF);
  bufferU[Inc(j)] := (addr) and ($FF);
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((2) * (Tcom)));
  if saveLog then
  begin
   fprintf(logfile, 'WriteRegister(0x%X,0x%X)' + NL + '', addr, data);
  end;
end;

function ReadProgMem(addr: Integer): Integer;
var
  addr_temp: Integer;
  data_temp: Integer;
  eecon_temp: Integer;
  data: Integer;
begin
  addr_temp := ((ReadRegister($10F)) shl (8)) + (ReadRegister($10D));
  data_temp := ((ReadRegister($10E)) shl (8)) + (ReadRegister($10C));
  eecon_temp := ReadRegister($18C);
  WriteRegister($10F, (addr) shr (8));
  WriteRegister($10D, (addr) and ($FF));
  WriteRegister($18C, (eecon_temp) or ($80));
  WriteRegister($18C, (eecon_temp) or ($81));
  data := ((ReadRegister($10E)) shl (8)) + (ReadRegister($10C));
  WriteRegister($10F, (addr_temp) shl (8));
  WriteRegister($10D, (addr_temp) and ($FF));
  WriteRegister($10E, (data_temp) shl (8));
  WriteRegister($10C, (data_temp) and ($FF));
  WriteRegister($18C, eecon_temp);
  Exit(data);
end;

function ReadProgMemN(addr: Integer; n: Integer; buf: ^Integer): Integer;
var
  addr_temp: Integer;
  data_temp: Integer;
  eecon_temp: Integer;
  i: Integer;
  j: Integer;
  z: Integer;
  w: Integer;
  k: Integer;
begin
  if saveLog then
   fprintf(logfile, 'ReadProgMemN(0x%X,%d)' + NL + '', addr, n);
  j := 0;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := (($10C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10C) and ($FF);
  bufferU[Inc(j)] := $3A;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($18C) and ($FF);
  bufferU[Inc(j)] := $3A;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($18C) and ($FF);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((13) * (Tcom)));
  j := 0;
  z := 0;
  while ((z) < ((64) - (5))) and ((bufferI[z]) <> ($3A)) do
  begin
   Inc(z);
  end;
  data_temp := (bufferI[(z) + (3)]) + ((bufferI[(z) + (7)]) shl (8));
  addr_temp := (bufferI[(z) + (5)]) + ((bufferI[(z) + (9)]) shl (8));
  z := 10;
  while ((z) < ((64) - (3))) and ((bufferI[z]) <> ($3A)) do
  begin
   Inc(z);
  end;
  eecon_temp := bufferI[(z) + (3)];
  k := 0; w := 0;
  for i := 0 to (n) - 1 do
  begin
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := ((addr) + (i)) and ($FF);
   bufferU[Inc(j)] := (($10D) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($10D) and ($FF);
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := (((addr) + (i)) shr (8)) and ($FF);
   bufferU[Inc(j)] := (($10F) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($10F) and ($FF);
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($18C) and ($FF);
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := (($10C) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($10C) and ($FF);
   bufferU[Inc(j)] := $3A;
   bufferU[Inc(j)] := 3;
   Inc(w);
   if ((j) > ((64) - (21))) or ((i) = ((n) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO((2) + (((13) * (Tcom)) * (w)));
    j := 0;
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if (bufferI[z]) = ($3A) then
     begin
      buf[Inc(k)] := (bufferI[(z) + (3)]) + ((bufferI[(z) + (7)]) shl (8));
      z := z + 8;
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 10;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := eecon_temp;
  bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($18C) and ($FF);
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (data_temp) and ($FF);
  bufferU[Inc(j)] := (($10C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10C) and ($FF);
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (data_temp) shr (8);
  bufferU[Inc(j)] := (($10E) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10E) and ($FF);
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (addr_temp) and ($FF);
  bufferU[Inc(j)] := (($10D) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10D) and ($FF);
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (addr_temp) shr (8);
  bufferU[Inc(j)] := (($10F) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10F) and ($FF);
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((10) * (Tcom)));
  Exit(i);
end;

function ReadDataMem(addr: Integer): Integer;
var
  addr_temp: Integer;
  data_temp: Integer;
  eecon_temp: Integer;
  data: Integer;
begin
  addr_temp := ReadRegister($10D);
  data_temp := ReadRegister($10C);
  eecon_temp := ReadRegister($18C);
  WriteRegister($10D, addr);
  WriteRegister($18C, (eecon_temp) and ($7F));
  WriteRegister($18C, ((eecon_temp) and ($7F)) or ($1));
  data := ReadRegister($10C);
  WriteRegister($10D, addr_temp);
  WriteRegister($10C, data_temp);
  WriteRegister($18C, eecon_temp);
  Exit(data);
end;

function ReadDataMemN(addr: Integer; n: Integer; buf: PByte): Integer;
var
  addr_temp: Integer;
  data_temp: Integer;
  eecon_temp: Integer;
  i: Integer;
  j: Integer;
  z: Integer;
  w: Integer;
  k: Integer;
begin
  if saveLog then
   fprintf(logfile, 'ReadDataMemN(0x%X,%d)' + NL + '', addr, n);
  j := 0;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := (($10C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10C) and ($FF);
  bufferU[Inc(j)] := $3A;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($18C) and ($FF);
  bufferU[Inc(j)] := $3A;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($18C) and ($FF);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((13) * (Tcom)));
  j := 0;
  z := 0;
  while ((z) < ((64) - (5))) and ((bufferI[z]) <> ($3A)) do
  begin
   Inc(z);
  end;
  data_temp := bufferI[(z) + (3)];
  addr_temp := bufferI[(z) + (5)];
  z := 6;
  while ((z) < ((64) - (3))) and ((bufferI[z]) <> ($3A)) do
  begin
   Inc(z);
  end;
  eecon_temp := bufferI[(z) + (3)];
  k := 0; w := 0;
  for i := 0 to (n) - 1 do
  begin
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := ((addr) + (i)) and ($FF);
   bufferU[Inc(j)] := (($10D) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($10D) and ($FF);
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($18C) and ($FF);
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (($10C) shr (8)) and ($FF);
   bufferU[Inc(j)] := ($10C) and ($FF);
   bufferU[Inc(j)] := $3A;
   bufferU[Inc(j)] := 1;
   Inc(w);
   if ((j) > ((64) - (17))) or ((i) = ((n) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO((2) + (((10) * (Tcom)) * (w)));
    j := 0;
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if (bufferI[z]) = ($3A) then
     begin
      buf[Inc(k)] := bufferI[(z) + (3)];
      z := z + 4;
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 6;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := eecon_temp;
  bufferU[Inc(j)] := (($18C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($18C) and ($FF);
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (data_temp) and ($FF);
  bufferU[Inc(j)] := (($10C) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10C) and ($FF);
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := (addr_temp) and ($FF);
  bufferU[Inc(j)] := (($10D) shr (8)) and ($FF);
  bufferU[Inc(j)] := ($10D) and ($FF);
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((10) * (Tcom)));
  Exit(i);
end;

function getVar(addr: Integer; var_: PChar): PChar;
var
  // (no local variables detected)
begin
  addr := addr and $1FF;
  if variables[addr].name_ then
   strcpy(var_, variables[addr].name_)
  else
   sprintf(var_, '0x%03X', addr);
  Exit(var_);
end;

function decodeCmd(cmd: Integer; str: PChar; addrH: Integer): PChar;
var
  ins: array[0..32-1] of Char;
  reg: array[0..32-1] of Char;
begin
  if ((cmd) and ($3F9F)) = (0) then
   sprintf(str, 'nop')
  else
   if (cmd) = ($0001) then
    sprintf(str, 'reset')
   else
    if (cmd) = ($0008) then
     sprintf(str, 'return')
    else
     if (cmd) = ($0009) then
      sprintf(str, 'retfie')
     else
      if (cmd) = ($000A) then
       sprintf(str, 'callw')
      else
       if (cmd) = ($000B) then
        sprintf(str, 'brw')
       else
        if (cmd) = ($0062) then
         sprintf(str, 'option')
        else
         if (cmd) = ($0063) then
          sprintf(str, 'sleep')
         else
          if (cmd) = ($0064) then
           sprintf(str, 'clrwdt')
          else
           if (cmd) = ($0065) then
            sprintf(str, 'trisa')
           else
            if (cmd) = ($0066) then
             sprintf(str, 'trisb')
            else
             if (cmd) = ($0067) then
              sprintf(str, 'trisc')
             else
              if ((cmd) shr (12)) = (0) then
              begin
               if (((cmd) shr (8)) = (0)) and ((cmd) and ($80)) then
                sprintf(str, 'movwf %s', getVar((addrH) + ((cmd) and ($7F)), reg))
               else
                if ((cmd) shr (8)) = (1) then
                begin
                 if (cmd) and ($80) then
                  sprintf(str, 'clrf %s', getVar((addrH) + ((cmd) and ($7F)), reg))
                 else
                  sprintf(str, 'clrf w');
                end
                else
                begin
                 case (cmd) shr (8) of
                  2:
                  begin
                   sprintf(ins, 'subwf');
                  end;
                  3:
                  begin
                   sprintf(ins, 'decf');
                  end;
                  4:
                  begin
                   sprintf(ins, 'iorwf');
                  end;
                  5:
                  begin
                   sprintf(ins, 'andwf');
                  end;
                  6:
                  begin
                   sprintf(ins, 'xorwf');
                  end;
                  7:
                  begin
                   sprintf(ins, 'addwf');
                  end;
                  8:
                  begin
                   sprintf(ins, 'movf');
                  end;
                  9:
                  begin
                   sprintf(ins, 'comf');
                  end;
                  10:
                  begin
                   sprintf(ins, 'incf');
                  end;
                  11:
                  begin
                   sprintf(ins, 'decfsz');
                  end;
                  12:
                  begin
                   sprintf(ins, 'rrf');
                  end;
                  13:
                  begin
                   sprintf(ins, 'rlf');
                  end;
                  14:
                  begin
                   sprintf(ins, 'swapf');
                  end;
                  15:
                  begin
                   sprintf(ins, 'incfsz');
                  end;
                  else
                  begin
                   sprintf(ins, '???');
                  end;
                 end;
                 sprintf(str, '%s %s,%c', ins, getVar((addrH) + ((cmd) and ($7F)), reg), IfThen((cmd) and ($80), #102, #119));
                end;
              end
              else
               if ((cmd) shr (12)) = (1) then
               begin
                case (cmd) shr (10) of
                 4:
                 begin
                  sprintf(ins, 'bcf');
                 end;
                 5:
                 begin
                  sprintf(ins, 'bsf');
                 end;
                 6:
                 begin
                  sprintf(ins, 'btfsc');
                 end;
                 7:
                 begin
                  sprintf(ins, 'btfss');
                 end;
                 else
                 begin
                  sprintf(ins, '??');
                 end;
                end;
                sprintf(str, '%s %s,%d', ins, getVar((addrH) + ((cmd) and ($7F)), reg), ((cmd) and ($380)) shr (7));
               end
               else
                if ((cmd) shr (12)) = (2) then
                 sprintf(str, '%s 0x%X', IfThen((cmd) and ($800), 'goto', 'call'), (cmd) and ($7FF))
                else
                 if ((cmd) shr (10)) = ($C) then
                  sprintf(str, 'movlw 0x%X', (cmd) and ($FF))
                 else
                  if ((cmd) shr (10)) = ($D) then
                   sprintf(str, 'retlw 0x%X', (cmd) and ($FF))
                  else
                   if ((cmd) shr (9)) = ($1E) then
                    sprintf(str, 'sublw 0x%X', (cmd) and ($FF))
                   else
                    if ((cmd) shr (9)) = ($1F) then
                     sprintf(str, 'addlw 0x%X', (cmd) and ($FF))
                    else
                     if ((cmd) shr (8)) = ($38) then
                      sprintf(str, 'iorlw 0x%X', (cmd) and ($FF))
                     else
                      if ((cmd) shr (8)) = ($39) then
                       sprintf(str, 'andlw 0x%X', (cmd) and ($FF))
                      else
                       if ((cmd) shr (8)) = ($3A) then
                        sprintf(str, 'xorlw 0x%X', (cmd) and ($FF))
                       else
                        sprintf(str, 'unknown command');
  Exit(str);
end;

function PrintMessageICD(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
begin
  gtk_text_buffer_set_text(statusBuf, msg, -(1));
  gtk_text_buffer_get_start_iter(statusBuf, @(iter));
  gtk_text_view_scroll_to_iter(statusTxt, @(iter), 0.0, FALSE_, 0, 0);
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
end;

function AppendMessageICD(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
begin
  gtk_text_buffer_get_end_iter(statusBuf, @(iter));
  gtk_text_buffer_insert(statusBuf, @(iter), msg, -(1));
  gtk_text_buffer_get_start_iter(statusBuf, @(iter));
  gtk_text_view_scroll_to_iter(statusTxt, @(iter), 0.0, FALSE_, 0, 0);
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
end;

function scrollToLine(line: Integer): Pointer;
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
begin
  gtk_text_buffer_get_end_iter(sourceBuf, @(iter));
  if (line) > (0) then
  begin
   gtk_text_iter_set_line(@(iter), (line) - (1));
   iter2 := iter;
   gtk_text_iter_forward_char(@(iter2));
   gtk_text_iter_forward_to_line_end(@(iter2));
  end
  else
  begin
   gtk_text_buffer_get_selection_bounds(sourceBuf, @(iter), @(iter2));
   iter2 := iter;
  end;
  gtk_text_buffer_select_range(sourceBuf, @(iter), @(iter2));
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
  gtk_text_view_scroll_to_iter(sourceTxt, @(iter), 0.0, TRUE_, 0, 0.5);
end;

function SourceHilightLine(line: Integer): Pointer;
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  tag: ^TGtkTextTag;
begin
  if (line) > (0) then
  begin
   tag := gtk_text_tag_table_lookup(gtk_text_buffer_get_tag_table(sourceBuf), 'break_text');
   if not (tag) then
    tag := gtk_text_buffer_create_tag(sourceBuf, 'break_text', 'background', 'red', NULL);
   gtk_text_buffer_get_end_iter(sourceBuf, @(iter));
   gtk_text_iter_set_line(@(iter), (line) - (1));
   iter2 := iter;
   gtk_text_iter_forward_char(@(iter2));
   gtk_text_iter_forward_to_line_end(@(iter2));
   gtk_text_buffer_apply_tag(sourceBuf, tag, @(iter), @(iter2));
  end;
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
end;

function SourceRemoveHilightLine(line: Integer): Pointer;
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
begin
  if (line) > (0) then
  begin
   gtk_text_buffer_get_end_iter(sourceBuf, @(iter));
   gtk_text_iter_set_line(@(iter), (line) - (1));
   iter2 := iter;
   gtk_text_iter_forward_char(@(iter2));
   gtk_text_iter_forward_to_line_end(@(iter2));
   gtk_text_buffer_remove_tag_by_name(sourceBuf, 'break_text', @(iter), @(iter2));
  end;
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
end;

function loadSource(f: ^TextFile): Integer;
var
  size: Integer;
  tmp: PChar;
  g: PChar;
begin
  if not (f) then
   Exit(0);
  fseek(f, 0, SEEK_END);
  size := ftell(f);
  fseek(f, 0, SEEK_SET);
  tmp := malloc((size) + (1));
  size := fread(tmp, 1, size, f);
  tmp[size] := 0;
  g := g_locale_to_utf8(tmp, -(1), NULL, NULL, NULL);
  gtk_text_buffer_set_text(sourceBuf, g, -(1));
  free(tmp);
  g_free(g);
  Exit(1);
end;

function loadCoff(widget: ^TControl; window: ^TControl): Pointer;
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
begin
  dialog := gtk_file_chooser_dialog_new(strings[I_LOAD_COFF], window, GTK_FILE_CHOOSER_ACTION_OPEN, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_OPEN], GTK_RESPONSE_ACCEPT, NULL);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  if (gtk_dialog_run(GTK_DIALOG(dialog))) = (GTK_RESPONSE_ACCEPT) then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   UseCoff := analyzeCOFF(filename, Slabel, Sulabel, source_info, @(s_files), coff_data, @(sym), @(nsym));
   g_free(filename);
   if (source_info[0].src_file) <> (-(1)) then
   begin
    if (currentSource) = (source_info[0].src_file) then
    begin
     scrollToLine(source_info[0].src_line);
    end
    else
     if loadSource(s_files[source_info[0].src_file].ptr) then
     begin
      scrollToLine(source_info[0].src_line);
      currentSource := source_info[0].src_file;
     end;
   end;
  end;
  gtk_widget_destroy(GTK_WIDGET(dialog));
end;

procedure initVar;
var
  i: Integer;
begin
  for i := 0 to ($200) - 1 do
  begin
   variables[i].name_ := 0;
   variables[i].display := 0;
  end;
  variables[0].name_ := 'INDF';
  variables[1].name_ := 'TMR0';
  variables[2].name_ := 'PCL';
  variables[3].name_ := 'STATUS';
  variables[4].name_ := 'FSR';
  variables[5].name_ := 'PORTA';
  variables[6].name_ := 'PORTB';
  variables[7].name_ := 'PORTC';
  variables[8].name_ := 'PORTD';
  variables[9].name_ := 'PORTE';
  variables[10].name_ := 'PCLATH';
  variables[11].name_ := 'INTCON';
  variables[12].name_ := 'PIR1';
  variables[13].name_ := 'PIR2';
  variables[14].name_ := 'TMR1L';
  variables[15].name_ := 'TMR1H';
  variables[16].name_ := 'T1CON';
  variables[17].name_ := 'TMR2';
  variables[18].name_ := 'T2CON';
  variables[19].name_ := 'SSPBUF';
  variables[20].name_ := 'SSPCON';
  variables[21].name_ := 'CCPR1L';
  variables[22].name_ := 'CCPR1H';
  variables[23].name_ := 'CCP1CON';
  variables[24].name_ := 'RCSTA';
  variables[25].name_ := 'TXREG';
  variables[26].name_ := 'RCREG';
  variables[27].name_ := 'CCPR2L';
  variables[28].name_ := 'CCPR2H';
  variables[29].name_ := 'CCP2CON';
  variables[30].name_ := 'ADRESH';
  variables[31].name_ := 'ADCON0';
  variables[$6B].name_ := 'DEBUG_VAR1';
  variables[$6C].name_ := 'DEBUG_VAR2';
  variables[$6D].name_ := 'DEBUG_VAR3';
  variables[$6E].name_ := 'DEBUG_VAR4';
  variables[$6F].name_ := 'DEBUG_VAR5';
  variables[$70].name_ := 'DEBUG_VAR6';
  variables[$71].name_ := 'DEBUG_VAR7';
  variables[$72].name_ := 'DEBUG_VAR8';
  variables[$80].name_ := 'INDF';
  variables[$81].name_ := 'OPTION_REG';
  variables[$82].name_ := 'PCL';
  variables[$83].name_ := 'STATUS';
  variables[$84].name_ := 'FSR';
  variables[$85].name_ := 'TRISA';
  variables[$86].name_ := 'TRISB';
  variables[$87].name_ := 'TRISC';
  variables[$88].name_ := 'TRISD';
  variables[$89].name_ := 'TRISE';
  variables[$8A].name_ := 'PCLATH';
  variables[$8B].name_ := 'INTCON';
  variables[$8C].name_ := 'PIE1';
  variables[$8D].name_ := 'PIE2';
  variables[$8E].name_ := 'PCON';
  variables[$91].name_ := 'SSPCON2';
  variables[$92].name_ := 'PR2';
  variables[$93].name_ := 'SSPADD';
  variables[$94].name_ := 'SSPSTAT';
  variables[$98].name_ := 'TXSTA';
  variables[$99].name_ := 'SPBRG';
  variables[$9E].name_ := 'ADRESL';
  variables[$9F].name_ := 'ADCON1';
  variables[$100].name_ := 'INDF';
  variables[$101].name_ := 'TMR0';
  variables[$102].name_ := 'PCL';
  variables[$103].name_ := 'STATUS';
  variables[$104].name_ := 'FSR';
  variables[$106].name_ := 'PORTB';
  variables[$10A].name_ := 'PCLATH';
  variables[$10B].name_ := 'INTCON';
  variables[$10C].name_ := 'EEDATA';
  variables[$10D].name_ := 'EEADR';
  variables[$10E].name_ := 'EEDATH';
  variables[$10F].name_ := 'EEADRH';
  variables[$180].name_ := 'INDF';
  variables[$181].name_ := 'OPTION_REG';
  variables[$182].name_ := 'PCL';
  variables[$183].name_ := 'STATUS';
  variables[$184].name_ := 'FSR';
  variables[$186].name_ := 'TRISB';
  variables[$18A].name_ := 'PCLATH';
  variables[$18B].name_ := 'INTCON';
  variables[$18C].name_ := 'EECON1';
  variables[$18D].name_ := 'EECON2';
end;

function ICDHelp(widget: ^TControl; window: ^TControl): Pointer;
var
  dialog: ^TControl;
begin
  dialog := gtk_message_dialog_new(window, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_INFO, GTK_BUTTONS_CLOSE, strings[I_ICD_HELP_TXT]);
  g_signal_connect_swapped(dialog, 'response', gtk_widget_destroy, dialog);
  gtk_window_set_title(dialog, strings[I_ICD_HELP]);
  gtk_widget_show_all(dialog);
end;

function icdCheck(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if not (isRunning()) then
  begin
   g_source_remove(icdTimer);
   ShowContext();
  end;
end;

function icdRun(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if not (icdConnected) then
  begin
   saveLog := gtk_toggle_button_get_active(b_log);
   if saveLog then
   begin
    OpenLogFile();
    fprintf(logfile, 'ICD start' + NL + '');
   end;
   startICD(30);
   run();
   icdConnected := 1;
   icdTimer := g_timeout_add(20, icdCheck, NULL);
   PrintMessageICD('running');
  end
  else
   if not (running) then
   begin
    cont(break_addr, freeze);
    icdTimer := g_timeout_add(20, icdCheck, NULL);
    PrintMessageICD('running');
   end;
end;

function icdHalt(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt_();
   ShowContext();
  end;
end;

function icdStep(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt_();
  end;
  step();
  ShowContext();
end;

function icdStepOver(widget: ^TControl; window: ^TControl): Pointer;
var
  addr: Integer;
  data: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt_();
  end;
  addr := (((ReadRegister($18E)) and ($1F)) shl (8)) + (ReadRegister($18F));
  data := ReadProgMem(addr);
  if ((data) shr (11)) = (4) then
  begin
   cont((addr) + (1), freeze);
   icdTimer := g_timeout_add(20, icdCheck, NULL);
  end
  else
  begin
   step();
   ShowContext();
  end;
end;

function icdStop(widget: ^TControl; window: ^TControl): Pointer;
var
  j: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt_();
  end;
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(3);
  if saveLog then
   WriteLogIO();
  icdConnected := 0;
  PrintMessageICD('stopped');
  scrollToLine(source_info[0].src_line);
end;

function icdRefresh(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if not (running) then
  begin
   ShowContext();
  end;
end;

function ShowBank(bank: Integer; status: PChar): Pointer;
var
  b: array[0..128-1] of Integer;
  temp: array[0..128-1] of Char;
  i: Integer;
begin
  if (bank) > (3) then
   bank := 3;
  if (bank) < (0) then
   bank := 0;
  sprintf(temp, 'bank %d:', bank);
  strcat(status, temp);
  ReadRegisterN((bank) * ($80), 128, b);
  for i := 0 to (128) - 1 do
  begin
   if ((i) mod (16)) = (0) then
   begin
    sprintf(temp, '' + NL + '0x%03X:', (i) + ((bank) * ($80)));
    strcat(status, temp);
   end;
   sprintf(temp, '%02X', b[i]);
   strcat(status, temp);
  end;
  strcat(status, NL);
end;

procedure ShowContext;
var
  i: Integer;
  addr: Integer;
  data: Integer;
  s: Integer;
  cmd: array[0..32-1] of Char;
  status: array[0..4096-1] of Char;
  temp: array[0..128-1] of Char;
  rawsource: Integer;
  addr0: Integer;
  addr1: Integer;
  line_pc: Integer;
  tmp: array[0..((64 * 5) + 7)-1] of Char;
  t2: array[0..64-1] of Char;
  progmem: array[0..(5 + 7)-1] of Integer;
  data: array[0..256-1] of Byte;
  s: array[0..64-1] of Char;
  t: array[0..9-1] of Char;
  g: PChar;
begin
  cmd := '';
  status := '';
  addr := (((ReadRegister($18E)) and ($1F)) shl (8)) + (ReadRegister($18F));
  data := ReadProgMem(addr);
  s := ReadRegister($6C);
  s := ((s) shr (4)) + (((s) shl (4)) and ($F0));
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuPC)) then
  begin
   sprintf(temp, '%s: %s (0x%04X) ' + NL + 'PC=0x%04X' + NL + '', strings[S_NextIns], decodeCmd(data, cmd, ((s) and ($60)) shl (2)), data, addr);
   strcat(status, temp);
  end;
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuSTAT)) then
  begin
   sprintf(temp, 'STATUS=0x%02X (', s);
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($80), 'IRP', '   '));
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($40), 'RP1', '   '));
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($20), 'RP0', '   '));
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($10), 'TO', '  '));
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($8), 'PD', '  '));
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($4), 'Z', ' '));
   strcat(status, temp);
   sprintf(temp, '%s ', IfThen((s) and ($2), 'DC', '  '));
   strcat(status, temp);
   sprintf(temp, '%s)' + NL + '', IfThen((s) and ($1), 'C', ' '));
   strcat(status, temp);
   sprintf(temp, 'W=0x%02X PCLATH=0x%02X FSR=0x%02X' + NL + '', ReadRegister($6B), ReadRegister($6D), ReadRegister($6E));
   strcat(status, temp);
  end;
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank0)) then
   ShowBank(0, status);
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank1)) then
   ShowBank(1, status);
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank2)) then
   ShowBank(2, status);
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank3)) then
   ShowBank(3, status);
  rawsource := 0;
  if UseCoff then
  begin
   if (data) <> (coff_data[addr]) then
   begin
    sprintf(temp, 'code at address 0x%04X (0x%04X) is different than what specified in coff file (0x%04X)' + NL + '', addr, data, coff_data[addr]);
    strcat(status, temp);
    rawsource := 1;
   end
   else
   begin
    if (source_info[addr].src_file) <> (-(1)) then
    begin
     if (currentSource) = (source_info[addr].src_file) then
      scrollToLine(source_info[addr].src_line)
     else
      if loadSource(s_files[source_info[addr].src_file].ptr) then
      begin
       scrollToLine(source_info[addr].src_line);
       currentSource := source_info[addr].src_file;
      end
      else
       rawsource := 1;
    end
    else
     rawsource := 1;
   end;
  end;
  if (not (UseCoff)) or ((rawsource) = (1)) then
  begin
   line_pc := 0;
   tmp[0] := 0;
   addr0 := IfThen(((addr) - (5)) < (0), 0, (addr) - (5));
   addr1 := IfThen(((addr) + (7)) > ($1FFF), $1FFF, (addr) + (7));
   ReadProgMemN(addr0, (addr1) - (addr0), progmem);
   for i := addr0 to (addr1) - 1 do
   begin
    sprintf(t2, '0x%04X: %s (0x%04X)' + NL + '', i, decodeCmd(progmem[(i) - (addr0)], cmd, ((s) and ($60)) shl (2)), progmem[(i) - (addr0)]);
    strcat(tmp, t2);
    if (i) = (addr) then
     line_pc := i;
   end;
   gtk_text_buffer_set_text(sourceBuf, tmp, -(1));
   currentSource := -(1);
   scrollToLine(((line_pc) - (addr0)) + (1));
  end;
  for i := 0 to (nwatch) - 1 do
  begin
   sprintf(temp, '%s=0x%02X' + NL + '', watch[i].name_, ReadRegister(watch[i].value));
   strcat(status, temp);
  end;
  PrintMessageICD(status);
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuEE)) then
  begin
   str[0] := 0;
   t[8] := 0;
   ReadDataMemN(0, 256, data);
   strcat(str, 'EEPROM:' + NL + '');
   for i := 0 to ($100) - 1 do
   begin
    if ((i) mod (8)) = (0) then
    begin
     sprintf(s, '' + NL + '0x%02X: ', i);
     strcat(str, s);
    end;
    sprintf(s, '%02X ', data[i]);
    strcat(str, s);
    t[(i) and ($7)] := IfThen(isprint(data[i]), data[i], #46);
    if ((i) mod (8)) = (7) then
    begin
     g := g_locale_to_utf8(t, -(1), NULL, NULL, NULL);
     if g then
      strcat(str, g);
     g_free(g);
    end;
   end;
   AppendMessageICD(str);
  end;
end;

function addWatch(s: Tsymbol): Integer;
var
  i: Integer;
begin
  i := 0;
  while ((i) < (nwatch)) and (strcmp(watch[i].name_, s.name_)) do
  begin
   Inc(i);
  end;
  if (i) < (nwatch) then
  begin
   while (i) < ((nwatch) - (1)) do
   begin
    watch[i].name_ := watch[(i) + (1)].name_;
    watch[i].value := watch[(i) + (1)].value;
    Inc(i);
   end;
   Dec(nwatch);
   watch := realloc(watch, (nwatch) * (SizeOf(struct symbol)));
  end
  else
  begin
   Inc(nwatch);
   watch := realloc(watch, (nwatch) * (SizeOf(struct symbol)));
   watch[(nwatch) - (1)].name_ := s.name_;
   watch[(nwatch) - (1)].value := s.value;
   Exit(1);
  end;
  Exit(0);
end;

function executeCommand(command: PChar): Integer;
var
  option: array[0..32-1] of Char;
  addr: Integer;
  i: Integer;
  tmp: array[0..(32 * 10)-1] of Char;
  t2: array[0..32-1] of Char;
  cmd: array[0..32-1] of Char;
  progmem: array[0..10-1] of Integer;
  bank: Integer;
  i: Integer;
  addr: Integer;
  data: Integer;
  var_: array[0..128-1] of Char;
  addr: Integer;
  data: array[0..256-1] of Byte;
  s: array[0..64-1] of Char;
  t: array[0..9-1] of Char;
  g: PChar;
  i: Integer;
  n: Integer;
  i: Integer;
  n: Integer;
  i: Integer;
  var_addr: Integer;
  var_: array[0..64-1] of Char;
  s: Tsymbol;
  s: Tsymbol;
  var_: array[0..64-1] of Char;
  p: PChar;
  data: Integer;
  i: Integer;
  addr: Integer;
begin
  if strstr(command, 'break') then
  begin
   if (sscanf(command, 'break %x', @(break_addr))) = (1) then
   begin
    if running then
     Halt_();
    break_addr := break_addr and $1FFF;
    sprintf(str, 'break at address 0x%04X' + NL + '', break_addr);
    AppendMessageICD(str);
    SourceRemoveHilightLine(sourceHilight);
    SourceHilightLine(source_info[break_addr].src_line);
    sourceHilight := source_info[break_addr].src_line;
   end;
  end;
  if strstr(command, 'clear') then
  begin
   PrintMessageICD('');
  end
  else
   if strstr(command, 'freeze') then
   begin
    if (sscanf(command, 'freeze %s', option)) = (1) then
    begin
     if running then
      Halt_();
     if not (strcmp(option, 'on')) then
      freeze := 1;
     if not (strcmp(option, 'off')) then
      freeze := 0;
     WriteRegister($18E, ((break_addr) shr (8)) + (IfThen(freeze, $40, 0)));
    end;
    sprintf(str, 'peripheral freeze is %s' + NL + '', IfThen(freeze, 'on', 'off'));
    AppendMessageICD(str);
   end
   else
    if (not (strcmp(command, 'h'))) or (not (strcmp(command, 'halt'))) then
    begin
     icdHalt(NULL, NULL);
    end
    else
     if not (strcmp(command, 'help')) then
     begin
      ICDHelp(NULL, NULL);
     end
     else
      if strstr(command, 'list ') then
      begin
       cmd := '';
       tmp[0] := 0;
       if (sscanf(command, 'list %x', @(addr))) = (1) then
       begin
        addr := addr and $1FFF;
        ReadProgMemN(addr, 10, progmem);
        for i := 0 to (10) - 1 do
        begin
         sprintf(t2, '0x%04X: %s (0x%04X)' + NL + '', (i) + (addr), decodeCmd(progmem[i], cmd, 0), progmem[i]);
         strcat(tmp, t2);
        end;
        AppendMessageICD(tmp);
       end;
      end
      else
       if (strstr(command, 'print ')) or (strstr(command, 'p ')) then
       begin
        if (strstr(command, 'print p')) or (strstr(command, 'p p')) then
        begin
         if ((sscanf(command, 'print p %x', @(addr))) = (1)) or ((sscanf(command, 'p p %x', @(addr))) = (1)) then
         begin
          addr := addr and $1FFF;
          if running then
           Halt_();
          data := ReadProgMem(addr);
          sprintf(str, '0x%04X: %s (0x%04X)' + NL + '', addr, decodeCmd(data, var_, $1000), data);
          AppendMessageICD(str);
         end;
        end
        else
         if (not (strcmp(command, 'print ee'))) or (not (strcmp(command, 'p ee'))) then
         begin
          str[0] := 0;
          t[8] := 0;
          if running then
           Halt_();
          ReadDataMemN(0, 256, data);
          sprintf(str, 'EEPROM:' + NL + '');
          for i := 0 to ($100) - 1 do
          begin
           if ((i) mod (8)) = (0) then
           begin
            sprintf(s, '' + NL + '0x%02X: ', i);
            strcat(str, s);
           end;
           sprintf(s, '%02X ', data[i]);
           strcat(str, s);
           t[(i) and ($7)] := IfThen(isprint(data[i]), data[i], #46);
           if ((i) mod (8)) = (7) then
           begin
            g := g_locale_to_utf8(t, -(1), NULL, NULL, NULL);
            if g then
             strcat(str, g);
            g_free(g);
           end;
          end;
          strcat(str, NL);
          AppendMessageICD(str);
         end
         else
          if ((sscanf(command, 'print ee %x', @(addr))) = (1)) or ((sscanf(command, 'p ee %x', @(addr))) = (1)) then
          begin
           addr := addr and $FF;
           if running then
            Halt_();
           data := ReadDataMem(addr);
           sprintf(str, 'eeprom memory at 0x%02X=0x%02X (%c)' + NL + '', addr, data, IfThen(isprint(data), data, #46));
           AppendMessageICD(str);
          end
          else
           if ((sscanf(command, 'print bank %x', @(bank))) = (1)) or ((sscanf(command, 'p bank %x', @(bank))) = (1)) then
           begin
            str[0] := 0;
            bank := bank and $1FF;
            if (bank) > (3) then
             bank := bank div $80;
            if running then
             Halt_();
            ShowBank(bank, str);
            AppendMessageICD(str);
           end
           else
            if ((sscanf(command, 'print 0x%x', @(print_addr))) = (1)) or ((sscanf(command, 'p 0x%x', @(print_addr))) = (1)) then
            begin
             print_addr := print_addr and $1FF;
             if running then
              Halt_();
             sprintf(str, '[0x%03X]=0x%02X' + NL + '', print_addr, ReadRegister(print_addr));
             AppendMessageICD(str);
            end
            else
             if ((sscanf(command, 'print %s', var_)) = (1)) or ((sscanf(command, 'p %s', var_)) = (1)) then
             begin
              str[0] := 0;
              if running then
               Halt_();
              if (not (strcmp('W', var_))) or (not (strcmp('w', var_))) then
               sprintf(str, 'W = 0x%02X' + NL + '', ReadRegister($6B))
              else
               if not (strcmp('STATUS', var_)) then
                sprintf(str, '0x003: STATUS = 0x%02X' + NL + '', ReadRegister($6C))
               else
                if not (strcmp('FSR', var_)) then
                 sprintf(str, '0x004: FSR = 0x%02X' + NL + '', ReadRegister($6E))
                else
                 if not (strcmp('PCLATH', var_)) then
                  sprintf(str, '0x00A: PCLATH = 0x%02X' + NL + '', ReadRegister($6D))
                 else
                 begin
                  i := 0;
                  while ((i) < (nsym)) and (strcmp(var_, sym[i].name_)) do
                  begin
                   Inc(i);
                  end;
                  if (i) < (nsym) then
                  begin
                   sprintf(str, '0x%03X: %s = 0x%02X' + NL + '', sym[i].value, sym[i].name_, ReadRegister(sym[i].value));
                  end
                  else
                  begin
                   for i := 0 to ($200) - 1 do
                   begin
                    if (variables[i].name_) and (not (strcmp(var_, variables[i].name_))) then
                    begin
                     sprintf(str, '0x%03X: %s = 0x%02X' + NL + '', i, variables[i].name_, ReadRegister(i));
                     i := $200;
                    end;
                   end;
                  end;
                 end;
              AppendMessageICD(str);
             end;
       end
       else
        if (not (strcmp(command, 'r'))) or (not (strcmp(command, 'run'))) then
        begin
         icdRun(NULL, NULL);
        end
        else
         if (((not (strcmp(command, 's'))) or (not (strcmp(command, 'step')))) or (strstr(command, 'step'))) or (strstr(command, 's ')) then
         begin
          n := 1;
          sscanf(command, 'step %d', @(n));
          sscanf(command, 's %d', @(n));
          if running then
           Halt_();
          for i := 0 to (n) - 1 do
          begin
           step();
          end;
          if (n) > (1) then
           sprintf(str, 'step %d' + NL + '', n)
          else
           str[0] := 0;
          ShowContext();
          AppendMessageICD(str);
         end
         else
          if (((not (strcmp(command, 'ss'))) or (not (strcmp(command, 'step over')))) or (strstr(command, 'step over '))) or (strstr(command, 'ss ')) then
          begin
           n := 1;
           sscanf(command, 'step over %d', @(n));
           sscanf(command, 'ss %d', @(n));
           for i := 0 to (n) - 1 do
           begin
            icdStepOver(NULL, NULL);
           end;
           if (n) > (1) then
            sprintf(str, 'step over %d' + NL + '', n);
           AppendMessageICD(str);
          end
          else
           if (not (strcmp(command, 'ver'))) or (not (strcmp(command, 'version'))) then
           begin
            if running then
             Halt_();
            sprintf(str, 'debugger version: %.1f' + NL + '', (version()) div (10.0));
            AppendMessageICD(str);
           end
           else
            if (strstr(command, 'watch ')) or (strstr(command, 'w ')) then
            begin
             if (sscanf(command, 'watch 0x%x', @(var_addr))) or (sscanf(command, 'w 0x%x', @(var_addr))) then
             begin
              sprintf(var_, '[0x%X]', var_addr);
              s.name_ := strdup(var_);
              s.value := var_addr;
              addWatch(s);
              if not (running) then
               ShowContext();
             end
             else
              if (sscanf(command, 'watch %s', var_)) or (sscanf(command, 'w %s', var_)) then
              begin
               i := 0;
               while ((i) < (nsym)) and (strcmp(var_, sym[i].name_)) do
               begin
                Inc(i);
               end;
               if (i) < (nsym) then
               begin
                addWatch(sym[i]);
                if not (running) then
                 ShowContext();
               end
               else
               begin
                for i := 0 to ($200) - 1 do
                begin
                 if (variables[i].name_) and (not (strcmp(var_, variables[i].name_))) then
                 begin
                  s.name_ := variables[i].name_;
                  s.value := i;
                  addWatch(s);
                  if not (running) then
                   ShowContext();
                  i := $200;
                 end;
                end;
               end;
              end;
            end
            else
            begin
             addr := -(1);
             if (p := strchr(command, #61)) then
             begin
              p^ := 0;
              if (sscanf(command, '[%x]', @(addr))) and (sscanf((p) + (1), '%x', @(data))) then
              begin
               if running then
                Halt_();
               WriteRegister(addr, data);
               ShowContext();
               sprintf(str, '[0x%x]=0x%02X' + NL + '', addr, data);
               AppendMessageICD(str);
              end
              else
               if (sscanf(command, '%s', var_)) and (sscanf((p) + (1), '%x', @(data))) then
               begin
                i := 0;
                while ((i) < (nsym)) and (strcmp(var_, sym[i].name_)) do
                begin
                 Inc(i);
                end;
                if ((i) < (nsym)) and ((sym[i].value) < ($400)) then
                begin
                 addr := sym[i].value;
                end
                else
                begin
                 for i := 0 to ($200) - 1 do
                 begin
                  if (variables[i].name_) and (not (strcmp(var_, variables[i].name_))) then
                  begin
                   addr := i;
                   i := $200;
                  end;
                 end;
                end;
                if (addr) <> (-(1)) then
                begin
                 if running then
                  Halt_();
                 WriteRegister(addr, data);
                 ShowContext();
                 sprintf(str, '%s=0x%02X' + NL + '', var_, data);
                 AppendMessageICD(str);
                end;
               end;
             end
             else
              Exit(0);
            end;
  Exit(1);
end;

function removeWatch(name_: PChar): Integer;
var
  i: Integer;
begin
  i := 0;
  while ((i) < (nwatch)) and (strcmp(watch[i].name_, name_)) do
  begin
   Inc(i);
  end;
  if (i) < (nwatch) then
  begin
   while (i) < ((nwatch) - (1)) do
   begin
    watch[i].name_ := watch[(i) + (1)].name_;
    watch[i].value := watch[(i) + (1)].value;
    Inc(i);
   end;
   Dec(nwatch);
   watch := realloc(watch, (nwatch) * (SizeOf(struct symbol)));
   Exit(1);
  end;
  Exit(0);
end;

function source_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  x: Integer;
  y: Integer;
  i: Integer;
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  itx: TGtkTextIter;
  c: Char;
  selection: PChar;
  line: Integer;
begin
  if (GTK_IS_TEXT_VIEW(widget)) and ((event^.type_) = (GDK_2BUTTON_PRESS)) then
  begin
   gtk_text_view_window_to_buffer_coords(widget, GTK_TEXT_WINDOW_WIDGET, event^.x, event^.y, @(x), @(y));
   gtk_text_view_get_iter_at_location(widget, @(iter), x, y);
   iter2 := iter;
   itx := iter2;
   c := gtk_text_iter_get_char(@(itx));
   while (isalnum(c)) or ((c) = (#95)) do
   begin
    gtk_text_iter_forward_char(@(itx));
    c := gtk_text_iter_get_char(@(itx));
    iter2 := itx;
   end;
   itx := iter;
   c := gtk_text_iter_get_char(@(itx));
   while (isalnum(c)) or ((c) = (#95)) do
   begin
    gtk_text_iter_backward_char(@(itx));
    c := gtk_text_iter_get_char(@(itx));
    iter := itx;
   end;
   gtk_text_iter_forward_char(@(iter));
   selection := gtk_text_buffer_get_text(sourceBuf, @(iter), @(iter2), FALSE_);
   i := 0;
   while ((i) < (nsym)) and (strcmp(selection, sym[i].name_)) do
   begin
    Inc(i);
   end;
   if (i) < (nsym) then
   begin
    addWatch(sym[i]);
    ShowContext();
   end
   else
   begin
    line := (gtk_text_iter_get_line(@(iter))) + (1);
    for i := 0 to ($2200) - 1 do
    begin
     if (source_info[i].src_line) = (line) then
     begin
      break_addr := i;
      sprintf(str, 'break at address 0x%x' + NL + '', i);
      AppendMessageICD(str);
      SourceRemoveHilightLine(sourceHilight);
      SourceHilightLine(line);
      sourceHilight := line;
      Break;
     end;
    end;
   end;
  end;
  Exit(FALSE_);
end;

function icdStatus_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  x: Integer;
  y: Integer;
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  itx: TGtkTextIter;
  c: Char;
  selection: PChar;
begin
  if (GTK_IS_TEXT_VIEW(widget)) and ((event^.type_) = (GDK_2BUTTON_PRESS)) then
  begin
   gtk_text_view_window_to_buffer_coords(widget, GTK_TEXT_WINDOW_WIDGET, event^.x, event^.y, @(x), @(y));
   gtk_text_view_get_iter_at_location(widget, @(iter), x, y);
   iter2 := iter;
   itx := iter2;
   c := gtk_text_iter_get_char(@(itx));
   while (isalnum(c)) or ((c) = (#95)) do
   begin
    gtk_text_iter_forward_char(@(itx));
    c := gtk_text_iter_get_char(@(itx));
    iter2 := itx;
   end;
   itx := iter;
   c := gtk_text_iter_get_char(@(itx));
   while (isalnum(c)) or ((c) = (#95)) do
   begin
    gtk_text_iter_backward_char(@(itx));
    c := gtk_text_iter_get_char(@(itx));
    iter := itx;
   end;
   gtk_text_iter_forward_char(@(iter));
   selection := gtk_text_buffer_get_text(statusBuf, @(iter), @(iter2), FALSE_);
   if removeWatch(selection) then
    ShowContext();
  end;
  Exit(FALSE_);
end;

function icdCommand_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  s: array[0..64-1] of Char;
begin
  if ((event^.type_) = (GDK_KEY_PRESS)) and ((event^.keyval) = ($FF0D)) then
  begin
   strncpy(s, gtk_entry_get_text(GTK_ENTRY(icdCommand)), 63);
   if not (strlen(s)) then
   begin
    strcpy(s, lastCmd);
    gtk_entry_set_text(GTK_ENTRY(icdCommand), s);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    msDelay(60);
   end
   else
    strcpy(lastCmd, s);
   if executeCommand(s) then
    gtk_entry_set_text(GTK_ENTRY(icdCommand), '');
  end;
  Exit(FALSE_);
end;

function icd_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  // (no local variables detected)
begin
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
  if (event^.type_) = (GDK_KEY_PRESS) then
  begin
   case event^.keyval of
    $FFBE:
    begin
     ICDHelp(NULL, NULL);
    end;
    $FFC2:
    begin
     icdHalt(NULL, NULL);
    end;
    $FFC4:
    begin
     icdStep(NULL, NULL);
    end;
    $FFC5:
    begin
     icdStepOver(NULL, NULL);
    end;
    $FFC6:
    begin
     icdRun(NULL, NULL);
    end;
   end;
  end;
  Exit(FALSE_);
end;

end.

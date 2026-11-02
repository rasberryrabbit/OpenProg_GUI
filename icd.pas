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
  mainform;

const
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

var
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
  sourceHilight: Integer;
  lastCmd: array[0..64-1] of Char;
  UseCoff: Integer;
  source_info: array[0..LMAX-1] of Tstruct src_i;
  nsym: Integer;
  Slabel: array[0..LMAX-1] of PChar;
  Sulabel: array[0..ULMAX-1] of PChar;
  nwatch: Integer;
  coff_data: array[0..DATA_MAX-1] of Word;
  ver: Integer;
  reset: Integer;
  freeze: Integer;
  icdConnected: Integer;
  running: Integer;
  ins: array[0..32-1] of Char;
  reg: array[0..32-1] of Char;

// --- function declarations ---
procedure ShowContext(tck: T);



















struct var{	char name;	int display;} variables[0x200];




void startICD(int);
function isRunning: Integer;
procedure cont(break_addr: Integer; freeze: Integer);
procedure step;
procedure run;
function version: Integer;
procedure Halt_;
function ReadRegister(addr: Integer): Integer;
function ReadRegisterN(addr: Integer; n: Integer; buf: ^Integer): Integer;
procedure WriteRegister(addr: Integer; data: Integer);
function ReadProgMem(addr: Integer): Integer;
function ReadProgMemN(addr: Integer; n: Integer; buf: ^Integer): Integer;
function ReadDataMem(addr: Integer): Integer;
function ReadDataMemN(addr: Integer; n: Integer; buf: PByte): Integer;
function getVar(addr: Integer; var_: PChar): PChar;
procedure AppendMessageICD(msg: PChar);
procedure scrollToLine(line: Integer);
procedure SourceHilightLine(line: Integer);
procedure SourceRemoveHilightLine(line: Integer);
function loadSource(f: ^TextFile): Integer;
procedure loadCoff(widget: ^TControl; window: ^TControl);
procedure initVar;
procedure ICDHelp(widget: ^TControl; window: ^TControl);
procedure icdCheck(widget: ^TControl; window: ^TControl);
procedure icdRun(widget: ^TControl; window: ^TControl);
procedure icdHalt(widget: ^TControl; window: ^TControl);
procedure icdStep(widget: ^TControl; window: ^TControl);
procedure icdStepOver(widget: ^TControl; window: ^TControl);
procedure icdStop(widget: ^TControl; window: ^TControl);
procedure icdRefresh(widget: ^TControl; window: ^TControl);
procedure ShowBank(bank: Integer; status: PChar);
procedure ShowContext;
function addWatch(s: Tstruct symbol): Integer;
function executeCommand(command: PChar): Integer;
function removeWatch(name_: PChar): Integer;
function source_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
function icdStatus_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
function icdCommand_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;

implementation

procedure ShowContext(tck: T);



















struct var{	char name;	int display;} variables[0x200];




void startICD(int);
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := PROG_RST;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := tck;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000 and $ff;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(3);
  if (saveLog) <> 0 then
  begin
   fprintf(logfile, 'startICD()' + LineEnding + '');
  end;
end;

function isRunning: Integer;
var
  z: Integer;
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := READ_PINS;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(2);
  if (saveLog) <> 0 then
  begin
   // return value of fprintf() ignored
   fprintf(logfile, 'isRunning()' + LineEnding + '');
  end;
  z := 0;
  while (z<DIMBUF-1) and (bufferI[z]<>READ_PINS) do
  begin
   Inc(z);
  end;
  if (bufferI[z+1] and 1) <> 0 then
   running := 0
  else
   running := 1;
  Exit(running);
end;

procedure cont(break_addr: Integer; freeze: Integer);
var
  j: Integer;
begin
  j := 0;
  break_addr := break_addr and $1FFF;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := IfThen((break_addr shr 8)+(freeze, $40, 0));
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $8E;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := break_addr and $FF;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $8F;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := GO;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1+5*Tcom);
  if (saveLog) <> 0 then
  begin
   fprintf(logfile, 'continue()' + LineEnding + '');
  end;
  running := 1;
end;

procedure step;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := STEP;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1+Tcom);
  if (saveLog) <> 0 then
  begin
   fprintf(logfile, 'step()' + LineEnding + '');
  end;
end;

procedure run;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  if (saveLog) <> 0 then
  begin
   fprintf(logfile, 'run()' + LineEnding + '');
  end;
  running := 1;
end;

function version: Integer;
var
  j: Integer;
  z: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := VER;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(1+2*Tcom);
  if (saveLog) <> 0 then
  begin
   // return value of fprintf() ignored
   fprintf(logfile, 'version()' + LineEnding + '');
  end;
  z := 0;
  while (z<DIMBUF-2) and (bufferI[z]<>RX16) do
  begin
   Inc(z);
  end;
  Exit(bufferI[z+3]);
end;

procedure Halt_;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $6;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  if (saveLog) <> 0 then
  begin
   fprintf(logfile, 'halt()' + LineEnding + '');
  end;
  running := 0;
end;

function ReadRegister(addr: Integer): Integer;
var
  j: Integer;
  z: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := (addr shr 8) and $FF;
  bufferU[Inc(j)] := addr and $FF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(1+3*Tcom);
  if (saveLog) <> 0 then
  begin
   // return value of fprintf() ignored
   fprintf(logfile, 'ReadRegister(0x%X)' + LineEnding + '', addr);
  end;
  z := 0;
  while (z<DIMBUF-2) and (bufferI[z]<>RX16) do
  begin
   Inc(z);
  end;
  Exit(bufferI[z+3]);
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
  while i<n do
  begin
   w := IfThen(i+(DIMBUF-9)/2<n, (DIMBUF-9)/2, n-i);
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := $2;
   bufferU[Inc(j)] := RREG;
   bufferU[Inc(j)] := w;
   bufferU[Inc(j)] := (addr+i) shr 8;
   bufferU[Inc(j)] := (addr+i) and $FF;
   bufferU[Inc(j)] := RX16;
   bufferU[Inc(j)] := w;
   bufferU[Inc(j)] := FLUSH;
   while j<DIMBUF do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   // return value of PacketIO() ignored
   PacketIO(1+(w+2)*Tcom);
   if (saveLog) <> 0 then
   begin
    // return value of fprintf() ignored
    fprintf(logfile, 'ReadRegisterN(0x%X,%d)' + LineEnding + '', addr, n);
   end;
   z := 0;
   while (z<DIMBUF-2) and (bufferI[z]<>RX16) do
   begin
    Inc(z);
   end;
   for j := 0 to (w) - 1 do
   begin
    buf[i+j] := bufferI[z+3+j*2];
   end;
   j := 0;
   Inc(i, w);
  end;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(2);
  Exit(IfThen(i=n, 0, -1));
end;

procedure WriteRegister(addr: Integer; data: Integer);
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data and $FF;
  bufferU[Inc(j)] := (addr shr 8) and $FF;
  bufferU[Inc(j)] := addr and $FF;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1+2*Tcom);
  if (saveLog) <> 0 then
  begin
   fprintf(logfile, 'WriteRegister(0x%X,0x%X)' + LineEnding + '', addr, data);
  end;
end;

function ReadProgMem(addr: Integer): Integer;
var
  addr_temp: Integer;
  data_temp: Integer;
  eecon_temp: Integer;
  data: Integer;
begin
  addr_temp := (ReadRegister(EEADRH) shl 8)+ReadRegister(EEADR);
  data_temp := (ReadRegister(EEDATH) shl 8)+ReadRegister(EEDATA);
  eecon_temp := ReadRegister(EECON1);
  // return value of WriteRegister() ignored
  WriteRegister(EEADRH, addr shr 8);
  // return value of WriteRegister() ignored
  WriteRegister(EEADR, addr and $FF);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp or $80);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp or $81);
  data := (ReadRegister(EEDATH) shl 8)+ReadRegister(EEDATA);
  // return value of WriteRegister() ignored
  WriteRegister(EEADRH, addr_temp shl 8);
  // return value of WriteRegister() ignored
  WriteRegister(EEADR, addr_temp and $FF);
  // return value of WriteRegister() ignored
  WriteRegister(EEDATH, data_temp shl 8);
  // return value of WriteRegister() ignored
  WriteRegister(EEDATA, data_temp and $FF);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp);
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
  if (saveLog) <> 0 then
   // return value of fprintf() ignored
   fprintf(logfile, 'ReadProgMemN(0x%X,%d)' + LineEnding + '', addr, n);
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := (EEDATA shr 8) and $FF;
  bufferU[Inc(j)] := EEDATA and $FF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
  bufferU[Inc(j)] := EECON1 and $FF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
  bufferU[Inc(j)] := EECON1 and $FF;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(1+13*Tcom);
  j := 0;
  z := 0;
  while (z<DIMBUF-5) and (bufferI[z]<>RX16) do
  begin
   Inc(z);
  end;
  data_temp := bufferI[z+3]+(bufferI[z+7] shl 8);
  addr_temp := bufferI[z+5]+(bufferI[z+9] shl 8);
  Inc(z, 10);
  while (z<DIMBUF-3) and (bufferI[z]<>RX16) do
  begin
   Inc(z);
  end;
  eecon_temp := bufferI[z+3];
  k := 0 ; w := 0;
  for i := 0 to (n) - 1 do
  begin
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := (addr+i) and $FF;
   bufferU[Inc(j)] := (EEADR shr 8) and $FF;
   bufferU[Inc(j)] := EEADR and $FF;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := ((addr+i) shr 8) and $FF;
   bufferU[Inc(j)] := (EEADRH shr 8) and $FF;
   bufferU[Inc(j)] := EEADRH and $FF;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
   bufferU[Inc(j)] := EECON1 and $FF;
   bufferU[Inc(j)] := RREG;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := (EEDATA shr 8) and $FF;
   bufferU[Inc(j)] := EEDATA and $FF;
   bufferU[Inc(j)] := RX16;
   bufferU[Inc(j)] := 3;
   Inc(w);
   if (j>DIMBUF-21) or (i=n-1) then
   begin
    bufferU[Inc(j)] := FLUSH;
    while j<DIMBUF do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    // return value of PacketIO() ignored
    PacketIO(2+13*Tcom*w);
    j := 0;
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z]=RX16 then
     begin
      buf[Inc(k)] := bufferI[z+3]+(bufferI[z+7] shl 8);
      Inc(z, 8);
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := 10;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := eecon_temp;
  bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
  bufferU[Inc(j)] := EECON1 and $FF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data_temp and $FF;
  bufferU[Inc(j)] := (EEDATA shr 8) and $FF;
  bufferU[Inc(j)] := EEDATA and $FF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data_temp shr 8;
  bufferU[Inc(j)] := (EEDATH shr 8) and $FF;
  bufferU[Inc(j)] := EEDATH and $FF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := addr_temp and $FF;
  bufferU[Inc(j)] := (EEADR shr 8) and $FF;
  bufferU[Inc(j)] := EEADR and $FF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := addr_temp shr 8;
  bufferU[Inc(j)] := (EEADRH shr 8) and $FF;
  bufferU[Inc(j)] := EEADRH and $FF;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(1+10*Tcom);
  Exit(i);
end;

function ReadDataMem(addr: Integer): Integer;
var
  addr_temp: Integer;
  data_temp: Integer;
  eecon_temp: Integer;
  data: Integer;
begin
  addr_temp := ReadRegister(EEADR);
  data_temp := ReadRegister(EEDATA);
  eecon_temp := ReadRegister(EECON1);
  // return value of WriteRegister() ignored
  WriteRegister(EEADR, addr);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp and $7F);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, (eecon_temp and $7F) or $1);
  data := ReadRegister(EEDATA);
  // return value of WriteRegister() ignored
  WriteRegister(EEADR, addr_temp);
  // return value of WriteRegister() ignored
  WriteRegister(EEDATA, data_temp);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp);
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
  if (saveLog) <> 0 then
   // return value of fprintf() ignored
   fprintf(logfile, 'ReadDataMemN(0x%X,%d)' + LineEnding + '', addr, n);
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := (EEDATA shr 8) and $FF;
  bufferU[Inc(j)] := EEDATA and $FF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
  bufferU[Inc(j)] := EECON1 and $FF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
  bufferU[Inc(j)] := EECON1 and $FF;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(1+13*Tcom);
  j := 0;
  z := 0;
  while (z<DIMBUF-5) and (bufferI[z]<>RX16) do
  begin
   Inc(z);
  end;
  data_temp := bufferI[z+3];
  addr_temp := bufferI[z+5];
  Inc(z, 6);
  while (z<DIMBUF-3) and (bufferI[z]<>RX16) do
  begin
   Inc(z);
  end;
  eecon_temp := bufferI[z+3];
  k := 0 ; w := 0;
  for i := 0 to (n) - 1 do
  begin
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := (addr+i) and $FF;
   bufferU[Inc(j)] := (EEADR shr 8) and $FF;
   bufferU[Inc(j)] := EEADR and $FF;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
   bufferU[Inc(j)] := EECON1 and $FF;
   bufferU[Inc(j)] := RREG;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (EEDATA shr 8) and $FF;
   bufferU[Inc(j)] := EEDATA and $FF;
   bufferU[Inc(j)] := RX16;
   bufferU[Inc(j)] := 1;
   Inc(w);
   if (j>DIMBUF-17) or (i=n-1) then
   begin
    bufferU[Inc(j)] := FLUSH;
    while j<DIMBUF do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    // return value of PacketIO() ignored
    PacketIO(2+10*Tcom*w);
    j := 0;
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z]=RX16 then
     begin
      buf[Inc(k)] := bufferI[z+3];
      Inc(z, 4);
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := 6;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := eecon_temp;
  bufferU[Inc(j)] := (EECON1 shr 8) and $FF;
  bufferU[Inc(j)] := EECON1 and $FF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data_temp and $FF;
  bufferU[Inc(j)] := (EEDATA shr 8) and $FF;
  bufferU[Inc(j)] := EEDATA and $FF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := addr_temp and $FF;
  bufferU[Inc(j)] := (EEADR shr 8) and $FF;
  bufferU[Inc(j)] := EEADR and $FF;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(1+10*Tcom);
  Exit(i);
end;

function getVar(addr: Integer; var_: PChar): PChar;
var
  // (no local variables detected)
begin
  addr := addr and $1FF;
  if (variables[addr].name) <> 0 then
   // return value of strcpy() ignored
   strcpy(var, variables[addr].name)
  else
   // return value of sprintf() ignored
   sprintf(var, '0x%03X', addr);
  Exit(var);
end;

procedure AppendMessageICD(msg: PChar);
var
  iter: TGtkTextIter;
begin
  statusBuf.SelEnd := Length(statusBuf.Text);
  statusBuf.SelText := @( iter );
  statusBuf.SelStart := 0;
  GTK_TEXT_VIEW(statusTxt).SelStart := Length(GTK_TEXT_VIEW(statusTxt).Text);
  while (Application.ProcessMessages; False) <> 0 do
  begin
  end;
end;

procedure scrollToLine(line: Integer);
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
begin
  sourceBuf.SelEnd := Length(sourceBuf.Text);
  if line>0 then
  begin
   gtk_text_iter_set_line(@( iter ), line-1);
   iter2 := iter;
   gtk_text_iter_forward_char(@( iter2 ));
   gtk_text_iter_forward_to_line_end(@( iter2 ));
  end
  else
  begin
   gtk_text_buffer_get_selection_bounds(sourceBuf, @( iter ), @( iter2 ));
   iter2 := iter;
  end;
  gtk_text_buffer_select_range(sourceBuf, @( iter ), @( iter2 ));
  while (Application.ProcessMessages; False) <> 0 do
  begin
  end;
  GTK_TEXT_VIEW(sourceTxt).SelStart := Length(GTK_TEXT_VIEW(sourceTxt).Text);
end;

procedure SourceHilightLine(line: Integer);
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  tag: ^TGtkTextTag;
begin
  if line>0 then
  begin
   tag := gtk_text_tag_table_lookup(gtk_text_buffer_get_tag_table(sourceBuf), 'break_text');
   if  not tag then
    tag := gtk_text_buffer_create_tag(sourceBuf, 'break_text', 'background', 'red', nil);
   sourceBuf.SelEnd := Length(sourceBuf.Text);
   gtk_text_iter_set_line(@( iter ), line-1);
   iter2 := iter;
   gtk_text_iter_forward_char(@( iter2 ));
   gtk_text_iter_forward_to_line_end(@( iter2 ));
   gtk_text_buffer_apply_tag(sourceBuf, tag, @( iter ), @( iter2 ));
  end;
  while (Application.ProcessMessages; False) <> 0 do
  begin
  end;
end;

procedure SourceRemoveHilightLine(line: Integer);
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
begin
  if line>0 then
  begin
   sourceBuf.SelEnd := Length(sourceBuf.Text);
   gtk_text_iter_set_line(@( iter ), line-1);
   iter2 := iter;
   gtk_text_iter_forward_char(@( iter2 ));
   gtk_text_iter_forward_to_line_end(@( iter2 ));
   gtk_text_buffer_remove_tag_by_name(sourceBuf, 'break_text', @( iter ), @( iter2 ));
  end;
  while (Application.ProcessMessages; False) <> 0 do
  begin
  end;
end;

function loadSource(f: ^TextFile): Integer;
var
  size: Integer;
  tmp: PChar;
  g: PChar;
begin
  if  not f then
   Exit(0);
  Seek(f, 0);
  size := FilePos(f);
  Seek(f, 0);
  tmp := malloc(size+1);
  size := fread(tmp, 1, size, f);
  tmp[size] := 0;
  g := g_locale_to_utf8(tmp, -1, nil, nil, nil);
  sourceBuf.Lines.Text := g;
  FreeMem(tmp);
  // return value of g_free() ignored
  g_free(g);
  Exit(1);
end;

procedure loadCoff(widget: ^TControl; window: ^TControl);
var
  dialog: TGtkFileChooser;
  filename: Char;
begin
  dialog := gtk_file_chooser_dialog_new(strings[I_LOAD_COFF], GTK_WINDOW(window), GTK_FILE_CHOOSER_ACTION_OPEN, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_OPEN], GTK_RESPONSE_ACCEPT, nil);
  if (cur_path) <> 0 then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  if gtk_dialog_run (GTK_DIALOG (dialog)) = GTK_RESPONSE_ACCEPT then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if (cur_path) <> 0 then
    FreeMem(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   UseCoff := analyzeCOFF(filename, Slabel, Sulabel, source_info, @( s_files ), coff_data, @( sym ), @( nsym ));
   g_free(filename);
   if source_info[0].src_file<>-1 then
   begin
    if currentSource=source_info[0].src_file then
    begin
     scrollToLine(source_info[0].src_line);
    end
    else if loadSource(s_files[source_info[0].src_file].ptr) then
    begin
     scrollToLine(source_info[0].src_line);
     currentSource := source_info[0].src_file;
    end;
   end;
  end;
  GTK_WIDGET(dialog).Free;
end;

procedure initVar;
var
  i: Integer;
begin
  for i := 0 to ($200) - 1 do
  begin
   variables[i].name := 0;
   variables[i].display := 0;
  end;
  variables[1].name := 'TMR0';
  variables[2].name := 'PCL';
  variables[3].name := 'STATUS';
  variables[4].name := 'FSR';
  variables[5].name := 'PORTA';
  variables[6].name := 'PORTB';
  variables[7].name := 'PORTC';
  variables[8].name := 'PORTD';
  variables[9].name := 'PORTE';
  variables[10].name := 'PCLATH';
  variables[11].name := 'INTCON';
  variables[12].name := 'PIR1';
  variables[13].name := 'PIR2';
  variables[14].name := 'TMR1L';
  variables[15].name := 'TMR1H';
  variables[16].name := 'T1CON';
  variables[17].name := 'TMR2';
  variables[18].name := 'T2CON';
  variables[19].name := 'SSPBUF';
  variables[20].name := 'SSPCON';
  variables[21].name := 'CCPR1L';
  variables[22].name := 'CCPR1H';
  variables[23].name := 'CCP1CON';
  variables[24].name := 'RCSTA';
  variables[25].name := 'TXREG';
  variables[26].name := 'RCREG';
  variables[27].name := 'CCPR2L';
  variables[28].name := 'CCPR2H';
  variables[29].name := 'CCP2CON';
  variables[30].name := 'ADRESH';
  variables[31].name := 'ADCON0';
  variables[$6B].name := 'DEBUG_VAR1';
  variables[$6C].name := 'DEBUG_VAR2';
  variables[$6D].name := 'DEBUG_VAR3';
  variables[$6E].name := 'DEBUG_VAR4';
  variables[$6F].name := 'DEBUG_VAR5';
  variables[$70].name := 'DEBUG_VAR6';
  variables[$71].name := 'DEBUG_VAR7';
  variables[$72].name := 'DEBUG_VAR8';
  variables[$80].name := 'INDF';
  variables[$81].name := 'OPTION_REG';
  variables[$82].name := 'PCL';
  variables[$83].name := 'STATUS';
  variables[$84].name := 'FSR';
  variables[$85].name := 'TRISA';
  variables[$86].name := 'TRISB';
  variables[$87].name := 'TRISC';
  variables[$88].name := 'TRISD';
  variables[$89].name := 'TRISE';
  variables[$8A].name := 'PCLATH';
  variables[$8B].name := 'INTCON';
  variables[$8C].name := 'PIE1';
  variables[$8D].name := 'PIE2';
  variables[$8E].name := 'PCON';
  variables[$91].name := 'SSPCON2';
  variables[$92].name := 'PR2';
  variables[$93].name := 'SSPADD';
  variables[$94].name := 'SSPSTAT';
  variables[$98].name := 'TXSTA';
  variables[$99].name := 'SPBRG';
  variables[$9E].name := 'ADRESL';
  variables[$9F].name := 'ADCON1';
  variables[$100].name := 'INDF';
  variables[$101].name := 'TMR0';
  variables[$102].name := 'PCL';
  variables[$103].name := 'STATUS';
  variables[$104].name := 'FSR';
  variables[$106].name := 'PORTB';
  variables[$10A].name := 'PCLATH';
  variables[$10B].name := 'INTCON';
  variables[$10C].name := 'EEDATA';
  variables[$10D].name := 'EEADR';
  variables[$10E].name := 'EEDATH';
  variables[$10F].name := 'EEADRH';
  variables[$180].name := 'INDF';
  variables[$181].name := 'OPTION_REG';
  variables[$182].name := 'PCL';
  variables[$183].name := 'STATUS';
  variables[$184].name := 'FSR';
  variables[$186].name := 'TRISB';
  variables[$18A].name := 'PCLATH';
  variables[$18B].name := 'INTCON';
  variables[$18C].name := 'EECON1';
  variables[$18D].name := 'EECON2';
end;

procedure ICDHelp(widget: ^TControl; window: ^TControl);
var
  dialog: ^TControl;
begin
  dialog := gtk_message_dialog_new(GTK_WINDOW(window), GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_INFO, GTK_BUTTONS_CLOSE, strings[I_ICD_HELP_TXT]);
  // g_signal_connect_swapped() -> no-op in LCL
  GTK_WINDOW(dialog).Caption := strings[I_ICD_HELP];
  dialog.Visible := True;
end;

procedure icdCheck(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected<>1 then
   Exit;
  if  not isRunning() then
  begin
   g_source_remove(icdTimer);
   ShowContext();
  end;
end;

procedure icdRun(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected<>1 then
   Exit;
  if  not icdConnected then
  begin
   saveLog := GTK_TOGGLE_BUTTON(b_log).Checked;
   if (saveLog) <> 0 then
   begin
    OpenLogFile();
    fprintf(logfile, 'ICD start' + LineEnding + '');
   end;
   startICD(Tck);
   run();
   icdConnected := 1;
   icdTimer := Application.ProcessMessages;
   PrintMessageICD('running');
  end
  else if  not running then
  begin
   cont(break_addr, freeze);
   icdTimer := Application.ProcessMessages;
   PrintMessageICD('running');
  end;
end;

procedure icdHalt(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected<>1 then
   Exit;
  if (running) <> 0 then
  begin
   g_source_remove(icdTimer);
   Halt();
   ShowContext();
  end;
end;

procedure icdStep(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected<>1 then
   Exit;
  if (running) <> 0 then
  begin
   g_source_remove(icdTimer);
   Halt();
  end;
  step();
  Inc(addrDebug);
  ShowContext();
end;

procedure icdStepOver(widget: ^TControl; window: ^TControl);
var
  addr: Integer;
  data: Integer;
begin
  if DeviceDetected<>1 then
   Exit;
  if (running) <> 0 then
  begin
   g_source_remove(icdTimer);
   Halt();
  end;
  addr := ((ReadRegister($18E) and $1F) shl 8)+ReadRegister($18F);
  data := ReadProgMem(addr);
  if (data shr 11)=4 then
  begin
   cont(addr+1, freeze);
   icdTimer := Application.ProcessMessages;
  end
  else
  begin
   step();
   Inc(addrDebug);
   ShowContext();
  end;
end;

procedure icdStop(widget: ^TControl; window: ^TControl);
var
  j: Integer;
begin
  if DeviceDetected<>1 then
   Exit;
  if (running) <> 0 then
  begin
   g_source_remove(icdTimer);
   Halt();
  end;
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  while j<DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(3);
  if (saveLog) <> 0 then
   WriteLogIO();
  icdConnected := 0;
  PrintMessageICD('stopped');
  scrollToLine(source_info[0].src_line);
end;

procedure icdRefresh(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected<>1 then
   Exit;
  if  not running then
  begin
   ShowContext();
  end;
end;

procedure ShowBank(bank: Integer; status: PChar);
var
  b: array[0..128-1] of Integer;
  temp: array[0..128-1] of Char;
  i: Integer;
begin
  if bank>3 then
   bank := 3;
  if bank<0 then
   bank := 0;
  sprintf(temp, 'bank %d:', bank);
  strcat(status, temp);
  ReadRegisterN(bank*$80, 128, b);
  for i := 0 to (128) - 1 do
  begin
   if i mod 16=0 then
   begin
    sprintf(temp, '' + LineEnding + '0x%03X:', i+bank*$80);
    strcat(status, temp);
   end;
   sprintf(temp, '%02X', b[i]);
   strcat(status, temp);
  end;
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
  tmp: array[0..64*NLINES-1] of Char;
  t2: array[0..64-1] of Char;
  progmem: array[0..NLINES-1] of Integer;
  data: array[0..256-1] of Byte;
  s: array[0..64-1] of Char;
  t: array[0..9-1] of Char;
  g: Char;
begin
  cmd[0] := #0;
  status[0] := #0;
  addr := ((ReadRegister($18E) and $1F) shl 8)+ReadRegister($18F);
  data := ReadProgMem(addr);
  s := ReadRegister(status_temp);
  s := (s shr 4)+((s shl 4) and $F0);
  addr := addrDebug;
  s := statusDebug;
  if (UseCoff) <> 0 then
   data := coff_data[addr];
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuPC)) then
  begin
   sprintf(temp, '%s: %s (0x%04X) ' + LineEnding + 'PC=0x%04X' + LineEnding + '', strings[S_NextIns], decodeCmd(data, cmd, (s and $60) shl 2), data, addr);
   strcat(status, temp);
  end;
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuSTAT)) then
  begin
   sprintf(temp, IfThen("STATUS=0x mod 02X (",s); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $80, 'IRP', IfThen("   "); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $40, 'RP1', IfThen("   "); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $20, 'RP0', IfThen("   "); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $10, 'TO', IfThen("  "); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $8, 'PD', IfThen("  "); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $4, 'Z', IfThen(" "); 		strcat(status,temp); 		sprintf(temp," mod s ",s and $2, 'DC', '  "); 		strcat(status,temp); 		sprintf(temp,"%s)' + LineEnding + ''))))))), IfThen(s and $1, 'C', ' '));
   strcat(status, temp);
   sprintf(temp, 'W=0x%02X PCLATH=0x%02X FSR=0x%02X' + LineEnding + '', ReadRegister(w_temp), ReadRegister(pclath_temp), ReadRegister(fsr_temp));
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
  if (UseCoff) <> 0 then
  begin
   if data<>coff_data[addr] then
   begin
    sprintf(temp, 'code at address 0x%04X (0x%04X) is different than what specified in coff file (0x%04X)' + LineEnding + '', addr, data, coff_data[addr]);
    strcat(status, temp);
    rawsource := 1;
   end
   else
   begin
    if source_info[addr].src_file<>-1 then
    begin
     if currentSource=source_info[addr].src_file then
      scrollToLine(source_info[addr].src_line)
     else if loadSource(s_files[source_info[addr].src_file].ptr) then
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
  if (not UseCoff) or (rawsource=1) then
  begin
   line_pc := 0;
   tmp[0] := 0;
   addr0 := IfThen(addr-LINES_BEFORE<0, 0, addr-LINES_BEFORE);
   addr1 := IfThen(addr+LINES_AFTER>$1FFF, $1FFF, addr+LINES_AFTER);
   ReadProgMemN(addr0, addr1-addr0, progmem);
   for i := addr0 to (addr1) - 1 do
   begin
    sprintf(t2, '0x%04X: %s (0x%04X)' + LineEnding + '', i, decodeCmd(progmem[i-addr0], cmd, (s and $60) shl 2), progmem[i-addr0]);
    strcat(tmp, t2);
    if i=addr then
     line_pc := i;
   end;
   currentSource := -1;
   scrollToLine(line_pc-addr0+1);
  end;
  for i := 0 to (nwatch) - 1 do
  begin
   sprintf(temp, '%s=0x%02X' + LineEnding + '', watch[i].name, ReadRegister(watch[i].value));
   strcat(status, temp);
  end;
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuEE)) then
  begin
   str[0] := 0;
   t[8] := 0;
   ReadDataMemN(0, 256, data);
   strcat(str, 'EEPROM:' + LineEnding + '');
   for i := 0 to ($100) - 1 do
   begin
    if i mod 8=0 then
    begin
     sprintf(s, '' + LineEnding + '0x%02X: ', i);
     strcat(str, s);
    end;
    sprintf(s, '%02X ', data[i]);
    strcat(str, s);
    t[i and $7] := IfThen(isprint(data[i]), data[i], #46);
    if i mod 8=7 then
    begin
     g := g_locale_to_utf8(t, -1, nil, nil, nil);
     if (g) <> 0 then
      strcat(str, g);
     g_free(g);
    end;
   end;
  end;
end;

function addWatch(s: Tstruct symbol): Integer;
var
  i: Integer;
begin
  i := 0;
  while (i<nwatch) and (AnsiCompareStr(watch[i].name, s.name)) do
  begin
   Inc(i);
  end;
  if i<nwatch then
  begin
   while i<nwatch-1 do
   begin
    watch[i].name := watch[i+1].name;
    watch[i].value := watch[i+1].value;
    Inc(i);
   end;
   watch := realloc(watch, nwatch*sizeof(struct symbol));
  end
  else
  begin
   Inc(nwatch);
   watch := realloc(watch, nwatch*sizeof(struct symbol));
   watch[nwatch-1].name := s.name;
   watch[nwatch-1].value := s.value;
   Exit(1);
  end;
  Exit(0);
end;

function executeCommand(command: PChar): Integer;
var
  option: array[0..32-1] of Char;
  addr: Integer;
  i: Integer;
  tmp: array[0..32*LISTLINES-1] of Char;
  t2: array[0..32-1] of Char;
  cmd: array[0..32-1] of Char;
  progmem: array[0..LISTLINES-1] of Integer;
  bank: Integer;
  i: Integer;
  addr: Integer;
  data: Integer;
  var_: array[0..128-1] of Char;
  addr: Integer;
  data: array[0..256-1] of Byte;
  s: array[0..64-1] of Char;
  t: array[0..9-1] of Char;
  g: Char;
  i: Integer;
  n: Integer;
  i: Integer;
  n: Integer;
  i: Integer;
  var_addr: Integer;
  var_: array[0..64-1] of Char;
  s: Tstruct symbol;
  s: Tstruct symbol;
  var_: array[0..64-1] of Char;
  p: Char;
  data: Integer;
  i: Integer;
  addr: Integer;
begin
  if Pos(command, command) then
  begin
   if sscanf(command,"break  mod x", and break_addr)=1 then
   begin
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    break_addr := break_addr and $1FFF;
    // return value of sprintf() ignored
    sprintf(str, 'break at address 0x%04X' + LineEnding + '', break_addr);
    // return value of AppendMessageICD() ignored
    AppendMessageICD(str);
    // return value of SourceRemoveHilightLine() ignored
    SourceRemoveHilightLine(sourceHilight);
    // return value of SourceHilightLine() ignored
    SourceHilightLine(source_info[break_addr].src_line);
    sourceHilight := source_info[break_addr].src_line;
   end;
  end;
  if Pos(command, command) then
  begin
   // return value of PrintMessageICD() ignored
   PrintMessageICD('');
  end
  else if Pos(command, command) then
  begin
   if sscanf(command,"freeze  mod s",option)=1 then
   begin
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    if  not strcmp(option,"on") then
     freeze := 1;
    if  not strcmp(option,"off") then
     freeze := 0;
    // return value of WriteRegister() ignored
    WriteRegister($18E, IfThen((break_addr shr 8)+(freeze, $40, 0)));
   end;
   // return value of sprintf() ignored
   sprintf(str, 'peripheral freeze is %s' + LineEnding + '', IfThen(freeze, 'on', 'off'));
   // return value of AppendMessageICD() ignored
   AppendMessageICD(str);
  end
  else if (not strcmp(command,"h")) or (not strcmp(command,"halt")) then
  begin
   // return value of icdHalt() ignored
   icdHalt(nil, nil);
  end
  else if  not strcmp(command,"help") then
  begin
   // return value of ICDHelp() ignored
   ICDHelp(nil, nil);
  end
  else if Pos(command, command) then
  begin
   cmd[0] := #0;
   tmp[0] := 0;
   if sscanf(command,"list  mod x", and addr)=1 then
   begin
    addr := addr and $1FFF;
    // return value of ReadProgMemN() ignored
    ReadProgMemN(addr, LISTLINES, progmem);
    for i := 0 to (LISTLINES) - 1 do
    begin
     // return value of sprintf() ignored
     sprintf(t2, '0x%04X: %s (0x%04X)' + LineEnding + '', i+addr, decodeCmd(progmem[i], cmd, 0), progmem[i]);
     // return value of strcat() ignored
     strcat(tmp, t2);
    end;
   end;
  end
  else if Pos(command, command) then
  begin
   if Pos(command, command) then
   begin
    if (sscanf(command,"print p  mod x", and addr)=1) or (sscanf(command,"p p  mod x", and addr)=1) then
    begin
     addr := addr and $1FFF;
     if (running) <> 0 then
      // return value of Halt() ignored
      Halt();
     data := ReadProgMem(addr);
     // return value of sprintf() ignored
     sprintf(str, '0x%04X: %s (0x%04X)' + LineEnding + '', addr, decodeCmd(data, var, $1000), data);
     // return value of AppendMessageICD() ignored
     AppendMessageICD(str);
    end;
   end
   else if (not strcmp(command,"print ee")) or (not strcmp(command,"p ee")) then
   begin
    str[0] := 0;
    t[8] := 0;
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    // return value of ReadDataMemN() ignored
    ReadDataMemN(0, 256, data);
    // return value of sprintf() ignored
    sprintf(str, 'EEPROM:' + LineEnding + '');
    for i := 0 to ($100) - 1 do
    begin
     if i mod 8=0 then
     begin
      // return value of sprintf() ignored
      sprintf(s, '' + LineEnding + '0x%02X: ', i);
      // return value of strcat() ignored
      strcat(str, s);
     end;
     // return value of sprintf() ignored
     sprintf(s, '%02X ', data[i]);
     // return value of strcat() ignored
     strcat(str, s);
     t[i and $7] := IfThen(isprint(data[i]), data[i], #46);
     if i mod 8=7 then
     begin
      g := g_locale_to_utf8(t, -1, nil, nil, nil);
      if (g) <> 0 then
       // return value of strcat() ignored
       strcat(str, g);
      // return value of g_free() ignored
      g_free(g);
     end;
    end;
    // return value of AppendMessageICD() ignored
    AppendMessageICD(str);
   end
   else if (sscanf(command,"print ee  mod x", and addr)=1) or (sscanf(command,"p ee  mod x", and addr)=1) then
   begin
    addr := addr and $FF;
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    data := ReadDataMem(addr);
    // return value of sprintf() ignored
    sprintf(str, 'eeprom memory at 0x%02X=0x%02X (%c)' + LineEnding + '', addr, data, IfThen(isprint(data), data, #46));
    // return value of AppendMessageICD() ignored
    AppendMessageICD(str);
   end
   else if (sscanf(command,"print bank  mod x", and bank)=1) or (sscanf(command,"p bank  mod x", and bank)=1) then
   begin
    str[0] := 0;
    bank := bank and $1FF;
    if bank>3 then
     bank := bank / $80;
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    // return value of ShowBank() ignored
    ShowBank(bank, str);
    // return value of AppendMessageICD() ignored
    AppendMessageICD(str);
   end
   else if (sscanf(command,"print 0x mod x", and print_addr)=1) or (sscanf(command,"p 0x mod x", and print_addr)=1) then
   begin
    print_addr := print_addr and $1FF;
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    // return value of sprintf() ignored
    sprintf(str, '[0x%03X]=0x%02X' + LineEnding + '', print_addr, ReadRegister(print_addr));
    // return value of AppendMessageICD() ignored
    AppendMessageICD(str);
   end
   else if (sscanf(command,"print  mod s",var)=1) or (sscanf(command,"p  mod s",var)=1) then
   begin
    str[0] := 0;
    if (running) <> 0 then
     // return value of Halt() ignored
     Halt();
    if (not strcmp("W",var)) or (not strcmp("w",var)) then
     // return value of sprintf() ignored
     sprintf(str, 'W = 0x%02X' + LineEnding + '', ReadRegister(w_temp))
    else if  not strcmp("STATUS",var) then
     // return value of sprintf() ignored
     sprintf(str, '0x003: STATUS = 0x%02X' + LineEnding + '', ReadRegister(status_temp))
    else if  not strcmp("FSR",var) then
     // return value of sprintf() ignored
     sprintf(str, '0x004: FSR = 0x%02X' + LineEnding + '', ReadRegister(fsr_temp))
    else if  not strcmp("PCLATH",var) then
     // return value of sprintf() ignored
     sprintf(str, '0x00A: PCLATH = 0x%02X' + LineEnding + '', ReadRegister(pclath_temp))
    else
    begin
     i := 0;
     while (i<nsym) and (AnsiCompareStr(var, sym[i].name)) do
     begin
      Inc(i);
     end;
     if i<nsym then
     begin
      // return value of sprintf() ignored
      sprintf(str, '0x%03X: %s = 0x%02X' + LineEnding + '', sym[i].value, sym[i].name, ReadRegister(sym[i].value));
     end
     else
     begin
      for i := 0 to ($200) - 1 do
      begin
       if (variables[i].name) and (not strcmp(var,variables[i].name)) then
       begin
        // return value of sprintf() ignored
        sprintf(str, '0x%03X: %s = 0x%02X' + LineEnding + '', i, variables[i].name, ReadRegister(i));
        i := $200;
       end;
      end;
     end;
    end;
    // return value of AppendMessageICD() ignored
    AppendMessageICD(str);
   end;
  end
  else if (not strcmp(command,"r")) or (not strcmp(command,"run")) then
  begin
   // return value of icdRun() ignored
   icdRun(nil, nil);
  end
  else if (not strcmp(command,"s")) or (not strcmp(command,"step")) or (Pos(command, command)) or (Pos(command, command)) then
  begin
   n := 1;
   // return value of sscanf() ignored
   sscanf(command, 'step %d', @( n ));
   // return value of sscanf() ignored
   sscanf(command, 's %d', @( n ));
   Inc(addrDebug, n);
   if (running) <> 0 then
    // return value of Halt() ignored
    Halt();
   for i := 0 to (n) - 1 do
   begin
    // return value of step() ignored
    step();
   end;
   if n>1 then
    // return value of sprintf() ignored
    sprintf(str, 'step %d' + LineEnding + '', n)
   else
    str[0] := 0;
   // return value of ShowContext() ignored
   ShowContext();
   // return value of AppendMessageICD() ignored
   AppendMessageICD(str);
  end
  else if (not strcmp(command,"ss")) or (not strcmp(command,"step over")) or (Pos(command, command)) or (Pos(command, command)) then
  begin
   n := 1;
   // return value of sscanf() ignored
   sscanf(command, 'step over %d', @( n ));
   // return value of sscanf() ignored
   sscanf(command, 'ss %d', @( n ));
   Inc(addrDebug, n);
   for i := 0 to (n) - 1 do
   begin
    // return value of icdStepOver() ignored
    icdStepOver(nil, nil);
   end;
   if n>1 then
    // return value of sprintf() ignored
    sprintf(str, 'step over %d' + LineEnding + '', n);
   // return value of AppendMessageICD() ignored
   AppendMessageICD(str);
  end
  else if (not strcmp(command,"ver")) or (not strcmp(command,"version")) then
  begin
   if (running) <> 0 then
    // return value of Halt() ignored
    Halt();
   // return value of sprintf() ignored
   sprintf(str, 'debugger version: %.1f' + LineEnding + '', version()/10.0);
   // return value of AppendMessageICD() ignored
   AppendMessageICD(str);
  end
  else if Pos(command, command) then
  begin
   if sscanf(command, 'watch 0x%x', @( var_addr ) ) or sscanf(command, 'w 0x%x', @( var_addr )) then
   begin
    // return value of sprintf() ignored
    sprintf(var, '[0x%X]', var_addr);
    s.name := strdup(var);
    s.value := var_addr;
    // return value of addWatch() ignored
    addWatch(s);
    if  not running then
     // return value of ShowContext() ignored
     ShowContext();
   end
   else if sscanf(command, 'watch %s', var) or sscanf(command, 'w %s', var) then
   begin
    i := 0;
    while (i<nsym) and (AnsiCompareStr(var, sym[i].name)) do
    begin
     Inc(i);
    end;
    if i<nsym then
    begin
     // return value of addWatch() ignored
     addWatch(sym[i]);
     if  not running then
      // return value of ShowContext() ignored
      ShowContext();
    end
    else
    begin
     for i := 0 to ($200) - 1 do
     begin
      if (variables[i].name) and (not strcmp(var,variables[i].name)) then
      begin
       s.name := variables[i].name;
       s.value := i;
       // return value of addWatch() ignored
       addWatch(s);
       if  not running then
        // return value of ShowContext() ignored
        ShowContext();
       i := $200;
      end;
     end;
    end;
   end;
  end
  else
  begin
   addr := -1;
   if (p=strchr(command,'=')) <> 0 then
   begin
    (p^) := 0;
    if sscanf(command, '[%x]', @( addr ) ) and sscanf(p+1, '%x', @( data )) then
    begin
     if (running) <> 0 then
      // return value of Halt() ignored
      Halt();
     // return value of WriteRegister() ignored
     WriteRegister(addr, data);
     // return value of ShowContext() ignored
     ShowContext();
     // return value of sprintf() ignored
     sprintf(str, '[0x%x]=0x%02X' + LineEnding + '', addr, data);
     // return value of AppendMessageICD() ignored
     AppendMessageICD(str);
    end
    else if sscanf(command, '%s', var) and sscanf(p+1, '%x', @( data )) then
    begin
     i := 0;
     while (i<nsym) and (AnsiCompareStr(var, sym[i].name)) do
     begin
      Inc(i);
     end;
     if (i<nsym) and (sym[i].value<$400) then
     begin
      addr := sym[i].value;
     end
     else
     begin
      for i := 0 to ($200) - 1 do
      begin
       if (variables[i].name) and (not strcmp(var,variables[i].name)) then
       begin
        addr := i;
        i := $200;
       end;
      end;
     end;
     if addr<>-1 then
     begin
      if (running) <> 0 then
       // return value of Halt() ignored
       Halt();
      // return value of WriteRegister() ignored
      WriteRegister(addr, data);
      // return value of ShowContext() ignored
      ShowContext();
      // return value of sprintf() ignored
      sprintf(str, '%s=0x%02X' + LineEnding + '', var, data);
      // return value of AppendMessageICD() ignored
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
  while (i<nwatch) and (AnsiCompareStr(watch[i].name, name)) do
  begin
   Inc(i);
  end;
  if i<nwatch then
  begin
   while i<nwatch-1 do
   begin
    watch[i].name := watch[i+1].name;
    watch[i].value := watch[i+1].value;
    Inc(i);
   end;
   watch := realloc(watch, nwatch*sizeof(struct symbol));
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
  if (GTK_IS_TEXT_VIEW(widget)) and (event^.type=GDK_2BUTTON_PRESS) then
  begin
   // return value of gtk_text_view_window_to_buffer_coords() ignored
   gtk_text_view_window_to_buffer_coords(GTK_TEXT_VIEW(widget), GTK_TEXT_WINDOW_WIDGET, event^.x, event^.y, @( x ), @( y ));
   // return value of gtk_text_view_get_iter_at_location() ignored
   gtk_text_view_get_iter_at_location(GTK_TEXT_VIEW(widget), @( iter ), x, y);
   iter2 := iter;
   c := gtk_text_iter_get_char(@( itx ));
   while (isalnum(c)) or (c='_') do
   begin
    // return value of gtk_text_iter_forward_char() ignored
    gtk_text_iter_forward_char(@( itx ));
    c := gtk_text_iter_get_char(@( itx ));
    iter2 := itx;
   end;
   c := gtk_text_iter_get_char(@( itx ));
   while (isalnum(c)) or (c='_') do
   begin
    // return value of gtk_text_iter_backward_char() ignored
    gtk_text_iter_backward_char(@( itx ));
    c := gtk_text_iter_get_char(@( itx ));
    iter := itx;
   end;
   selection := sourceBuf.Lines.Text;
   i := 0;
   while (i<nsym) and (AnsiCompareStr(selection, sym[i].name)) do
   begin
    Inc(i);
   end;
   if i<nsym then
   begin
    // return value of addWatch() ignored
    addWatch(sym[i]);
    // return value of ShowContext() ignored
    ShowContext();
   end
   else
   begin
    line := gtk_text_iter_get_line( and iter)+1;
    for i := 0 to (LMAX) - 1 do
    begin
     if source_info[i].src_line=line then
     begin
      break_addr := i;
      // return value of sprintf() ignored
      sprintf(str, 'break at address 0x%x' + LineEnding + '', i);
      // return value of AppendMessageICD() ignored
      AppendMessageICD(str);
      // return value of SourceRemoveHilightLine() ignored
      SourceRemoveHilightLine(sourceHilight);
      // return value of SourceHilightLine() ignored
      SourceHilightLine(line);
      sourceHilight := line;
      Break;
     end;
    end;
    if source_info[i].src_line=line then
    begin
     break_addr := i;
     // return value of sprintf() ignored
     sprintf(str, 'break at address 0x%x' + LineEnding + '', i);
     // return value of AppendMessageICD() ignored
     AppendMessageICD(str);
     // return value of SourceRemoveHilightLine() ignored
     SourceRemoveHilightLine(sourceHilight);
     // return value of SourceHilightLine() ignored
     SourceHilightLine(line);
     sourceHilight := line;
     Break;
    end;
   end;
  end;
  Exit(False);
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
  if (GTK_IS_TEXT_VIEW(widget)) and (event^.type=GDK_2BUTTON_PRESS) then
  begin
   // return value of gtk_text_view_window_to_buffer_coords() ignored
   gtk_text_view_window_to_buffer_coords(GTK_TEXT_VIEW(widget), GTK_TEXT_WINDOW_WIDGET, event^.x, event^.y, @( x ), @( y ));
   // return value of gtk_text_view_get_iter_at_location() ignored
   gtk_text_view_get_iter_at_location(GTK_TEXT_VIEW(widget), @( iter ), x, y);
   iter2 := iter;
   c := gtk_text_iter_get_char(@( itx ));
   while (isalnum(c)) or (c='_') do
   begin
    // return value of gtk_text_iter_forward_char() ignored
    gtk_text_iter_forward_char(@( itx ));
    c := gtk_text_iter_get_char(@( itx ));
    iter2 := itx;
   end;
   c := gtk_text_iter_get_char(@( itx ));
   while (isalnum(c)) or (c='_') do
   begin
    // return value of gtk_text_iter_backward_char() ignored
    gtk_text_iter_backward_char(@( itx ));
    c := gtk_text_iter_get_char(@( itx ));
    iter := itx;
   end;
   selection := statusBuf.Lines.Text;
   if removeWatch(selection) then
    // return value of ShowContext() ignored
    ShowContext();
  end;
  Exit(False);
end;

function icdCommand_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  s: array[0..64-1] of Char;
begin
  if (event^.type=GDK_KEY_PRESS) and (((GdkEventKey*)event)^.keyval=$FF0D) then
  begin
   // return value of strncpy() ignored
   strncpy(s, GTK_ENTRY(icdCommand).Text, 63);
   if  not strlen(s) then
   begin
    // return value of strcpy() ignored
    strcpy(s, lastCmd);
    GTK_ENTRY(icdCommand).Text := s;
    while (Application.ProcessMessages; False) <> 0 do
    begin
    end;
    // return value of msDelay() ignored
    msDelay(60);
   end
   else
    // return value of strcpy() ignored
    strcpy(lastCmd, s);
   if executeCommand(s) then
    GTK_ENTRY(icdCommand).Text := '';
  end;
  Exit(False);
end;

end.

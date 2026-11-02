unit icd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common,
  coff;

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

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  saveLog: Textern int;
  Tcom: Textern double;
  running: Textern int;
  DeviceDetected: Textern int;
  b_log: ^Textern GtkWidget;
  cur_path: ^Textern char;
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
procedure Halt;
function ReadRegister(addr: Integer): Integer;
function ReadRegisterN(addr: Integer; n: Integer; buf: ^Integer): Integer;
procedure WriteRegister(addr: Integer; data: Integer);
function ReadProgMem(addr: Integer): Integer;
function ReadProgMemN(addr: Integer; n: Integer; buf: ^Integer): Integer;
function ReadDataMem(addr: Integer): Integer;
function ReadDataMemN(addr: Integer; n: Integer; buf: PByte): Integer;
function getVar(addr: Integer; var: PChar): PChar;
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
function removeWatch(name: PChar): Integer;
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
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(3);
  if saveLog then
  begin
   fprintf(logfile, 'startICD()' + LineEnding + '');
  end;
end;

function isRunning: Integer;
var
  z: Integer;
  j: Integer;
  running: Telse;
begin
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := READ_PINS;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(2);
  if saveLog then
  begin
   // return value of fprintf() ignored
   fprintf(logfile, 'isRunning()' + LineEnding + '');
  end;
  if bufferI[z+1]&1 then
   running := 0;
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
  bufferU[Inc(j)] := break_addr&0xFF;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $8F;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := GO;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1+5*Tcom);
  if saveLog then
  begin
   fprintf(logfile, 'continue()' + LineEnding + '');
  end;
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
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1+Tcom);
  if saveLog then
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
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, 'run()' + LineEnding + '');
  end;
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
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(1+2*Tcom);
  if saveLog then
  begin
   // return value of fprintf() ignored
   fprintf(logfile, 'version()' + LineEnding + '');
  end;
  Exit(bufferI[z+3]);
end;

procedure Halt;
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $6;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, 'halt()' + LineEnding + '');
  end;
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
  bufferU[Inc(j)] := (addr shr 8)&0xFF;
  bufferU[Inc(j)] := addr&0xFF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(1+3*Tcom);
  if saveLog then
  begin
   // return value of fprintf() ignored
   fprintf(logfile, 'ReadRegister(0x%X)' + LineEnding + '', addr);
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
  for i := 0 to (n) - 1 do
  begin
   w := IfThen(i+(DIMBUF-9)/2<n, (DIMBUF-9)/2, n-i);
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := $2;
   bufferU[Inc(j)] := RREG;
   bufferU[Inc(j)] := w;
   bufferU[Inc(j)] := (addr+i) shr 8;
   bufferU[Inc(j)] := (addr+i)&0xFF;
   bufferU[Inc(j)] := RX16;
   bufferU[Inc(j)] := w;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   // return value of PacketIO() ignored
   PacketIO(1+(w+2)*Tcom);
   if saveLog then
   begin
    // return value of fprintf() ignored
    fprintf(logfile, 'ReadRegisterN(0x%X,%d)' + LineEnding + '', addr, n);
   end;
   for j := 0 to (w) - 1 do
   begin
   end;
   j := 0;
   i := i + w;
  end;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(2);
  Exit(IfThen(i = n, 0, -1));
end;

procedure WriteRegister(addr: Integer; data: Integer);
var
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data&0xFF;
  bufferU[Inc(j)] := (addr shr 8)&0xFF;
  bufferU[Inc(j)] := addr&0xFF;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1+2*Tcom);
  if saveLog then
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
  WriteRegister(EEADR, addr&0xFF);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp|0x80);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, eecon_temp|0x81);
  data := (ReadRegister(EEDATH) shl 8)+ReadRegister(EEDATA);
  // return value of WriteRegister() ignored
  WriteRegister(EEADRH, addr_temp shl 8);
  // return value of WriteRegister() ignored
  WriteRegister(EEADR, addr_temp&0xFF);
  // return value of WriteRegister() ignored
  WriteRegister(EEDATH, data_temp shl 8);
  // return value of WriteRegister() ignored
  WriteRegister(EEDATA, data_temp&0xFF);
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
  if saveLog then
   // return value of fprintf() ignored
   fprintf(logfile, 'ReadProgMemN(0x%X,%d)' + LineEnding + '', addr, n);
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := (EEDATA shr 8)&0xFF;
  bufferU[Inc(j)] := EEDATA&0xFF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
  bufferU[Inc(j)] := EECON1&0xFF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
  bufferU[Inc(j)] := EECON1&0xFF;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(1+13*Tcom);
  j := 0;
  for z := 0 to (DIMBUF-5 and bufferI[z] not =RX16) - 1 do
  begin
  end;
  data_temp := bufferI[z+3]+(bufferI[z+7] shl 8);
  addr_temp := bufferI[z+5]+(bufferI[z+9] shl 8);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=10;z<DIMBUF-3&&bufferI[z]!=RX16;z++) *)
  // init: z+=10
  while z<DIMBUF-3 and bufferI[z] not =RX16 do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  eecon_temp := bufferI[z+3];
  w := k=0;
  for i := 0 to (n) - 1 do
  begin
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := (addr+i)&0xFF;
   bufferU[Inc(j)] := (EEADR shr 8)&0xFF;
   bufferU[Inc(j)] := EEADR&0xFF;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := ((addr+i) shr 8)&0xFF;
   bufferU[Inc(j)] := (EEADRH shr 8)&0xFF;
   bufferU[Inc(j)] := EEADRH&0xFF;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
   bufferU[Inc(j)] := EECON1&0xFF;
   bufferU[Inc(j)] := RREG;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := (EEDATA shr 8)&0xFF;
   bufferU[Inc(j)] := EEDATA&0xFF;
   bufferU[Inc(j)] := RX16;
   bufferU[Inc(j)] := 3;
   (* TODO gtk2laz: unrecognised statement: w++ *)
   if j>DIMBUF-21 or i = n-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    // return value of PacketIO() ignored
    PacketIO(2+13*Tcom*w);
    j := 0;
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = RX16 then
     begin
      buf[Inc(k)] := bufferI[z+3]+(bufferI[z+7] shl 8);
      z := z + 8;
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := 10;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := eecon_temp;
  bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
  bufferU[Inc(j)] := EECON1&0xFF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data_temp&0xFF;
  bufferU[Inc(j)] := (EEDATA shr 8)&0xFF;
  bufferU[Inc(j)] := EEDATA&0xFF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data_temp shr 8;
  bufferU[Inc(j)] := (EEDATH shr 8)&0xFF;
  bufferU[Inc(j)] := EEDATH&0xFF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := addr_temp&0xFF;
  bufferU[Inc(j)] := (EEADR shr 8)&0xFF;
  bufferU[Inc(j)] := EEADR&0xFF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := addr_temp shr 8;
  bufferU[Inc(j)] := (EEADRH shr 8)&0xFF;
  bufferU[Inc(j)] := EEADRH&0xFF;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
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
  WriteRegister(EECON1, eecon_temp&0x7F);
  // return value of WriteRegister() ignored
  WriteRegister(EECON1, (eecon_temp&0x7F)|0x1);
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
  if saveLog then
   // return value of fprintf() ignored
   fprintf(logfile, 'ReadDataMemN(0x%X,%d)' + LineEnding + '', addr, n);
  j := 0;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := (EEDATA shr 8)&0xFF;
  bufferU[Inc(j)] := EEDATA&0xFF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := RREG;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
  bufferU[Inc(j)] := EECON1&0xFF;
  bufferU[Inc(j)] := RX16;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
  bufferU[Inc(j)] := EECON1&0xFF;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(1+13*Tcom);
  j := 0;
  for z := 0 to (DIMBUF-5 and bufferI[z] not =RX16) - 1 do
  begin
  end;
  data_temp := bufferI[z+3];
  addr_temp := bufferI[z+5];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=6;z<DIMBUF-3&&bufferI[z]!=RX16;z++) *)
  // init: z+=6
  while z<DIMBUF-3 and bufferI[z] not =RX16 do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  eecon_temp := bufferI[z+3];
  w := k=0;
  for i := 0 to (n) - 1 do
  begin
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := (addr+i)&0xFF;
   bufferU[Inc(j)] := (EEADR shr 8)&0xFF;
   bufferU[Inc(j)] := EEADR&0xFF;
   bufferU[Inc(j)] := WREG;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
   bufferU[Inc(j)] := EECON1&0xFF;
   bufferU[Inc(j)] := RREG;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (EEDATA shr 8)&0xFF;
   bufferU[Inc(j)] := EEDATA&0xFF;
   bufferU[Inc(j)] := RX16;
   bufferU[Inc(j)] := 1;
   (* TODO gtk2laz: unrecognised statement: w++ *)
   if j>DIMBUF-17 or i = n-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    // return value of PacketIO() ignored
    PacketIO(2+10*Tcom*w);
    j := 0;
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = RX16 then
     begin
      buf[Inc(k)] := bufferI[z+3];
      z := z + 4;
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := 6;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := eecon_temp;
  bufferU[Inc(j)] := (EECON1 shr 8)&0xFF;
  bufferU[Inc(j)] := EECON1&0xFF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := data_temp&0xFF;
  bufferU[Inc(j)] := (EEDATA shr 8)&0xFF;
  bufferU[Inc(j)] := EEDATA&0xFF;
  bufferU[Inc(j)] := WREG;
  bufferU[Inc(j)] := addr_temp&0xFF;
  bufferU[Inc(j)] := (EEADR shr 8)&0xFF;
  bufferU[Inc(j)] := EEADR&0xFF;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(1+10*Tcom);
  Exit(i);
end;

function getVar(addr: Integer; var: PChar): PChar;
var
  sprintf(var,"0x%03X",addr): Telse;
begin
  addr := addr and $1FF;
  if variables[addr].name then
   // return value of strcpy() ignored
   strcpy(var, variables[addr].name);
  Exit(var);
end;

procedure AppendMessageICD(msg: PChar);
var
  iter: TGtkTextIter;
  (gtk_events_pending ()) gtk_main_iteration(): Twhile;
begin
  statusBuf.SelEnd := Length(statusBuf.Text);
  statusBuf.SelText := &iter;
  statusBuf.SelStart := 0;
  GTK_TEXT_VIEW(statusTxt).SelStart := Length(GTK_TEXT_VIEW(statusTxt).Text);
end;

procedure scrollToLine(line: Integer);
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  (gtk_events_pending ()) gtk_main_iteration(): Twhile;
begin
  sourceBuf.SelEnd := Length(sourceBuf.Text);
  if line>0 then
  begin
   gtk_text_iter_set_line(&iter, line-1);
   iter2 := iter;
   gtk_text_iter_forward_char(&iter2);
   gtk_text_iter_forward_to_line_end(&iter2);
  end
  else
  begin
   gtk_text_buffer_get_selection_bounds(sourceBuf, &iter, &iter2);
   iter2 := iter;
  end;
  GTK_TEXT_VIEW(sourceTxt).SelStart := Length(GTK_TEXT_VIEW(sourceTxt).Text);
end;

procedure SourceHilightLine(line: Integer);
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  tag: ^TGtkTextTag;
  (sourceBuf,tag,&iter,&iter2): Tgtk_text_buffer_apply_tag;
begin
  if line>0 then
  begin
   tag := gtk_text_tag_table_lookup(gtk_text_buffer_get_tag_table(sourceBuf), 'break_text');
   if  not tag then
    tag := gtk_text_buffer_create_tag(sourceBuf, 'break_text', 'background', 'red', nil);
   sourceBuf.SelEnd := Length(sourceBuf.Text);
   gtk_text_iter_set_line(&iter, line-1);
   iter2 := iter;
   gtk_text_iter_forward_char(&iter2);
   gtk_text_iter_forward_to_line_end(&iter2);
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
   gtk_text_iter_set_line(&iter, line-1);
   iter2 := iter;
   gtk_text_iter_forward_char(&iter2);
   gtk_text_iter_forward_to_line_end(&iter2);
   gtk_text_buffer_remove_tag_by_name(sourceBuf, 'break_text', &iter, &iter2);
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
  = (GtkFileChooser*) gtk_file_chooser_dialog_new (strings[I_LOAD_COFF],  						GTK_WINDOW(window), 						GTK_FILE_CHOOSER_ACTION_OPEN, 						strings[I_CANCEL], GTK_RESPONSE_CANCEL, 						strings[I_OPEN], GTK_RESPONSE_ACCEPT, 						NULL): Tdialog;
  filename: Char;
  = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog)): Tfilename;
  = gtk_file_chooser_get_current_folder(dialog): Tcur_path;
  (filename): Tg_free;
begin
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  if gtk_dialog_run (GTK_DIALOG (dialog))  =  GTK_RESPONSE_ACCEPT then
  begin
   if cur_path then
    FreeMem(cur_path);
   UseCoff := analyzeCOFF(filename, Slabel, Sulabel, source_info, &s_files, coff_data, &sym, &nsym);
   if source_info[0].src_file not =-1 then
   begin
    if currentSource = source_info[0].src_file then
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
  variables[0x6B].name := 'DEBUG_VAR1';
  variables[0x6C].name := 'DEBUG_VAR2';
  variables[0x6D].name := 'DEBUG_VAR3';
  variables[0x6E].name := 'DEBUG_VAR4';
  variables[0x6F].name := 'DEBUG_VAR5';
  variables[0x70].name := 'DEBUG_VAR6';
  variables[0x71].name := 'DEBUG_VAR7';
  variables[0x72].name := 'DEBUG_VAR8';
  variables[0x80].name := 'INDF';
  variables[0x81].name := 'OPTION_REG';
  variables[0x82].name := 'PCL';
  variables[0x83].name := 'STATUS';
  variables[0x84].name := 'FSR';
  variables[0x85].name := 'TRISA';
  variables[0x86].name := 'TRISB';
  variables[0x87].name := 'TRISC';
  variables[0x88].name := 'TRISD';
  variables[0x89].name := 'TRISE';
  variables[0x8A].name := 'PCLATH';
  variables[0x8B].name := 'INTCON';
  variables[0x8C].name := 'PIE1';
  variables[0x8D].name := 'PIE2';
  variables[0x8E].name := 'PCON';
  variables[0x91].name := 'SSPCON2';
  variables[0x92].name := 'PR2';
  variables[0x93].name := 'SSPADD';
  variables[0x94].name := 'SSPSTAT';
  variables[0x98].name := 'TXSTA';
  variables[0x99].name := 'SPBRG';
  variables[0x9E].name := 'ADRESL';
  variables[0x9F].name := 'ADCON1';
  variables[0x100].name := 'INDF';
  variables[0x101].name := 'TMR0';
  variables[0x102].name := 'PCL';
  variables[0x103].name := 'STATUS';
  variables[0x104].name := 'FSR';
  variables[0x106].name := 'PORTB';
  variables[0x10A].name := 'PCLATH';
  variables[0x10B].name := 'INTCON';
  variables[0x10C].name := 'EEDATA';
  variables[0x10D].name := 'EEADR';
  variables[0x10E].name := 'EEDATH';
  variables[0x10F].name := 'EEADRH';
  variables[0x180].name := 'INDF';
  variables[0x181].name := 'OPTION_REG';
  variables[0x182].name := 'PCL';
  variables[0x183].name := 'STATUS';
  variables[0x184].name := 'FSR';
  variables[0x186].name := 'TRISB';
  variables[0x18A].name := 'PCLATH';
  variables[0x18B].name := 'INTCON';
  variables[0x18C].name := 'EECON1';
  variables[0x18D].name := 'EECON2';
end;

procedure ICDHelp(widget: ^TControl; window: ^TControl);
var
  dialog: ^TControl;
  (GTK_WINDOW(dialog), "response",G_CALLBACK (gtk_widget_destroy),dialog): Tg_signal_connect_swapped;
  (dialog): Tgtk_widget_show_all;
begin
  dialog := gtk_message_dialog_new(GTK_WINDOW(window), GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_INFO, GTK_BUTTONS_CLOSE, strings[I_ICD_HELP_TXT]);
  GTK_WINDOW(dialog).Caption := strings[I_ICD_HELP];
end;

procedure icdCheck(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected not =1 then
   Exit;
  if  not isRunning() then
  begin
   g_source_remove(icdTimer);
   ShowContext();
  end;
end;

procedure icdRun(widget: ^TControl; window: ^TControl);
var
  = (int) gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(b_log)): TsaveLog;
begin
  if DeviceDetected not =1 then
   Exit;
  if  not icdConnected then
  begin
   if saveLog then
   begin
    OpenLogFile();
    fprintf(logfile, 'ICD start' + LineEnding + '');
   end;
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
  if DeviceDetected not =1 then
   Exit;
  if running then
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
  if DeviceDetected not =1 then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt();
  end;
  (* TODO gtk2laz: unrecognised statement: addrDebug++ *)
  ShowContext();
end;

procedure icdStepOver(widget: ^TControl; window: ^TControl);
var
  addr: Integer;
  data: Integer;
begin
  if DeviceDetected not =1 then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt();
  end;
  data := ReadProgMem(addr);
  if (data shr 11) = 4 then
  begin
   cont(addr+1, freeze);
   icdTimer := Application.ProcessMessages;
  end
  else
  begin
   step();
   (* TODO gtk2laz: unrecognised statement: addrDebug++ *)
   ShowContext();
  end;
end;

procedure icdStop(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected not =1 then
   Exit;
  if running then
  begin
   g_source_remove(icdTimer);
   Halt();
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(3);
  if saveLog then
   WriteLogIO();
  icdConnected := 0;
  PrintMessageICD('stopped');
  scrollToLine(source_info[0].src_line);
end;

procedure icdRefresh(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected not =1 then
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
  ReadRegisterN(bank*0x80, 128, b);
  for i := 0 to (128) - 1 do
  begin
   if i%16 = 0 then
   begin
    sprintf(temp, '' + LineEnding + '0x%03X:', i+bank*0x80);
    strcat(status, temp);
   end;
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
  if(loadSource(s_files[source_info[addr].src_file].ptr)){ 					scrollToLine(source_info[addr].src_line); 					currentSource=source_info[addr].src_file; 				} 				else rawsource=1: Telse;
  data: array[0..256-1] of Byte;
  s: array[0..64-1] of Char;
  t: array[0..9-1] of Char;
  g: Char;
begin
  (* TODO gtk2laz: array initializer: cmd[32]=""; *)
  (* TODO gtk2laz: array initializer: status[4096]=""; *)
  addr := ((ReadRegister(0x18E)&0x1F) shl 8)+ReadRegister(0x18F);
  data := ReadProgMem(addr);
  s := ReadRegister(status_temp);
  s := (s shr 4)+((s shl 4)&0xF0);
  addr := addrDebug;
  s := statusDebug;
  if UseCoff then
   data := coff_data[addr];
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuPC)) then
  begin
   sprintf(temp, '%s: %s (0x%04X) ' + LineEnding + 'PC=0x%04X' + LineEnding + '', strings[S_NextIns], decodeCmd(data, cmd, (s&0x60) shl 2), data, addr);
   strcat(status, temp);
  end;
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank1)) then
   ShowBank(1, status);
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank2)) then
   ShowBank(2, status);
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuBank3)) then
   ShowBank(3, status);
  rawsource := 0;
  if UseCoff then
  begin
   if data not =coff_data[addr] then
   begin
    sprintf(temp, 'code at address 0x%04X (0x%04X) is different than what specified in coff file (0x%04X)' + LineEnding + '', addr, data, coff_data[addr]);
    strcat(status, temp);
    rawsource := 1;
   end
   else
   begin
    if source_info[addr].src_file not =-1 then
    begin
     if currentSource = source_info[addr].src_file then
      scrollToLine(source_info[addr].src_line);
    end
    else
     rawsource := 1;
   end;
  end;
  if gtk_check_menu_item_get_active(GTK_CHECK_MENU_ITEM(icdMenuEE)) then
  begin
   str[0] := 0;
   t[8] := 0;
   ReadDataMemN(0, 256, data);
   strcat(str, 'EEPROM:' + LineEnding + '');
   for i := 0 to ($100) - 1 do
   begin
    if i%8 = 0 then
    begin
     sprintf(s, '' + LineEnding + '0x%02X: ', i);
     strcat(str, s);
    end;
    strcat(str, s);
    t[i&0x7] := IfThen(isprint(data[i]), data[i], #46);
    if i%8 = 7 then
    begin
     g := g_locale_to_utf8(t, -1, nil, nil, nil);
     if g then
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
  for i := 0 to (nwatch and strcmp(watch[i].name,s.name)) - 1 do
  begin
  end;
  if i<nwatch then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;i<nwatch-1;i++){ 			watch[i].name=watch[i+1].name; 			watch[i].value=watch[i+1].value; 		} 		nwatch-- *)
   // init: 
   while i<nwatch-1 do
   begin
    watch[i].name := watch[i+1].name;
    watch[i].value := watch[i+1].value;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   watch := realloc(watch, nwatch*sizeof(struct symbol));
  end
  else
  begin
   (* TODO gtk2laz: unrecognised statement: nwatch++ *)
   watch := realloc(watch, nwatch*sizeof(struct symbol));
   watch[nwatch-1].name := s.name;
   watch[nwatch-1].value := s.value;
   Exit(1);
  end;
end;

function executeCommand(command: PChar): Integer;
var
  // (no local variables detected)
begin
  if Pos(command, command) then
  begin
   if sscanf(command,"break %x",&break_addr) = 1 then
   begin
    if running then
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
end;

function removeWatch(name: PChar): Integer;
var
  i: Integer;
begin
  for i := 0 to (nwatch and strcmp(watch[i].name,name)) - 1 do
  begin
  end;
  if i<nwatch then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;i<nwatch-1;i++){ 			watch[i].name=watch[i+1].name; 			watch[i].value=watch[i+1].value; 		} 		nwatch-- *)
   // init: 
   while i<nwatch-1 do
   begin
    watch[i].name := watch[i+1].name;
    watch[i].value := watch[i+1].value;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   watch := realloc(watch, nwatch*sizeof(struct symbol));
   Exit(1);
  end;
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
  if GTK_IS_TEXT_VIEW(widget) and event->type = GDK_2BUTTON_PRESS then
  begin
   // return value of gtk_text_view_window_to_buffer_coords() ignored
   gtk_text_view_window_to_buffer_coords(GTK_TEXT_VIEW(widget), GTK_TEXT_WINDOW_WIDGET, event->x, event->y, &x, &y);
   // return value of gtk_text_view_get_iter_at_location() ignored
   gtk_text_view_get_iter_at_location(GTK_TEXT_VIEW(widget), &iter, x, y);
   iter2 := iter;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(itx=iter2,c=gtk_text_iter_get_char(&itx);isalnum(c)||c=='_';iter2=itx){ 			gtk_text_iter_forward_char(&itx); 			c=gtk_text_iter_get_char(&itx); 		} 		for(itx=iter,c=gtk_text_iter_get_char(&itx);is *)
   // init: itx=iter2,c=gtk_text_iter_get_char(&itx)
   while isalnum(c) or c = '_' do
   begin
    // return value of gtk_text_iter_forward_char() ignored
    gtk_text_iter_forward_char(&itx);
    c := gtk_text_iter_get_char(&itx);
    iter2 := itx;
   end;
   selection := sourceBuf.Lines.Text;
   for i := 0 to (nsym and strcmp(selection,sym[i].name)) - 1 do
   begin
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
    line := gtk_text_iter_get_line(&iter)+1;
    for i := 0 to (LMAX) - 1 do
    begin
    end;
   end;
  end;
end;

function icdStatus_mouse_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  x: Integer;
  y: Integer;
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  itx: TGtkTextIter;
  (GTK_TEXT_VIEW(widget),&iter,x,y): Tgtk_text_view_get_iter_at_location;
  c: Char;
  selection: PChar;
begin
  if GTK_IS_TEXT_VIEW(widget) and event->type = GDK_2BUTTON_PRESS then
  begin
   // return value of gtk_text_view_window_to_buffer_coords() ignored
   gtk_text_view_window_to_buffer_coords(GTK_TEXT_VIEW(widget), GTK_TEXT_WINDOW_WIDGET, event->x, event->y, &x, &y);
   iter2 := iter;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(itx=iter2,c=gtk_text_iter_get_char(&itx);isalnum(c)||c=='_';iter2=itx){ 			gtk_text_iter_forward_char(&itx); 			c=gtk_text_iter_get_char(&itx); 		} 		for(itx=iter,c=gtk_text_iter_get_char(&itx);is *)
   // init: itx=iter2,c=gtk_text_iter_get_char(&itx)
   while isalnum(c) or c = '_' do
   begin
    // return value of gtk_text_iter_forward_char() ignored
    gtk_text_iter_forward_char(&itx);
    c := gtk_text_iter_get_char(&itx);
    iter2 := itx;
   end;
   selection := statusBuf.Lines.Text;
   if removeWatch(selection) then
    // return value of ShowContext() ignored
    ShowContext();
  end;
end;

function icdCommand_key_event(widget: ^TControl; event: ^TGdkEventButton; func_data: Pointer): Integer;
var
  s: array[0..64-1] of Char;
  (gtk_events_pending ()) gtk_main_iteration(): Twhile;
begin
  if event->type = GDK_KEY_PRESS and ((GdkEventKey*)event)->keyval = 0xFF0D then
  begin
   // return value of strncpy() ignored
   strncpy(s, GTK_ENTRY(icdCommand).Text, 63);
   if  not strlen(s) then
   begin
    // return value of strcpy() ignored
    strcpy(s, lastCmd);
    GTK_ENTRY(icdCommand).Text := s;
    // return value of msDelay() ignored
    msDelay(60);
   end
   else
    // return value of strcpy() ignored
    strcpy(lastCmd, s);
   if executeCommand(s) then
    GTK_ENTRY(icdCommand).Text := '';
  end;
end;

end.

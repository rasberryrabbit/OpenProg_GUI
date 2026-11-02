unit progp24;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  v: array[0..256-1] of Char;
  aux: Char;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  k: Integer;
  k2: Integer;
  z: Integer;
  char *memExec: Cardinal;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  High: Integer;
  stop: Cardinal;
  d: Integer;

// --- function declarations ---
procedure CheckData(a: Integer; b: Integer; addr: Integer; err: ^Integer);
procedure PIC24_ID(id: Integer);
procedure DisplayCODE24F(dim: Integer);
procedure Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer);
procedure Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double);
procedure Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double);

implementation

procedure CheckData(a: Integer; b: Integer; addr: Integer; err: ^Integer);
var
  str: TCString;
begin
  if a not =b then
  begin
   PrintMessage(strings[S_NL]);
   PrintMessage4(strings[S_CodeVError], addr, addr, a, b);
   (* TODO gtk2laz: unrecognised statement: (*err)++ *)
  end;
end;

procedure PIC24_ID(id: Integer);
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (sizeof(PIC24LIST)/sizeof(PIC24LIST[0])) - 1 do
  begin
   if id = PIC24LIST[i].id then
   begin
    strcpy(s, PIC24LIST[i].device);
    strcat(s, '\r' + LineEnding + '');
    PrintMessage(s);
    Exit;
   end;
  end;
end;

procedure DisplayCODE24F(dim: Integer);
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
  PrintMessage(aux): Telse;
begin
  (* TODO gtk2laz: array initializer: s[256]=""; *)
  (* TODO gtk2laz: array initializer: t[256]=""; *)
  aux := malloc((dim/COL+1)*2*(16+COL*9));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  for i := 0 to (dim and i<size) - 1 do
  begin
   valid := 0;
   for j := i to (i+COL*2 and j<dim) - 1 do
   begin
    d := (memCODE[j+3] shl 24)+(memCODE[j+2] shl 16)+(memCODE[j+1] shl 8)+memCODE[j];
    sprintf(t, '%08X ', d);
    strcat(s, t);
    if d not =0xffffffff then
     valid := 1;
    j := j + 4;
   end;
   i := i + COL*2;
  end;
  FreeMem(aux);
end;

procedure Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  UID: array[0..16-1] of Byte;
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
  PrintMessage(aux): Telse;
begin
  k := 0;
  z := 0;
  for i := 0 to (16) - 1 do
  begin
  end;
  if FWVersion<0x900 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.9.0');
   Exit;
  end;
  if dim>0x100000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  executiveArea := executiveArea * 2;
  if executiveArea then
   memExec := malloc(executiveArea);
  for i := 0 to (executiveArea) - 1 do
  begin
  end;
  size := dim;
  if memCODE then
   FreeMem(memCODE);
  memCODE := malloc(size);
  FillChar(memCODE, dim, $FF);
  StartHVReg(-1);
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 55000 shr 8;
  bufferU[Inc(j)] := 55000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(65);
  j := 0;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w0 := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z+=3
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w1 := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage2('DevID: 0x%04X\r' + LineEnding + 'DevRev: 0x%04X\r' + LineEnding + '', w0, w1);
  PIC24_ID(w0);
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := 0x20+((appIDaddr shr 12)&0xF);
  bufferU[Inc(j)] := (appIDaddr shr 4)&0xFF;
  bufferU[Inc(j)] := ((appIDaddr shl 4)&0xF0)+6;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w0 := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage2('ApplicationID @ 0x80%04X:  0x%04X\r' + LineEnding + '', appIDaddr, w0);
  PrintMessage(strings[S_CodeReading1]);
  PrintStatusSetup();
  High := 0;
  for i := 0 to (dim) - 1 do
  begin
   if (i shr 17) not =High then
   begin
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := (i shr 21)&0xFF;
    bufferU[Inc(j)] := (i shr 13)&0xF0;
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(2);
    j := 0;
    High := i shr 17;
   end;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   if i<dim-16 then
   begin
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := REGOUT;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(4);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =REGOUT and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+1] := bufferI[z+1];
    memCODE[k] := bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+2] := bufferI[z+2];
    memCODE[k+6] := bufferI[z+1];
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+5] := bufferI[z+1];
    memCODE[k+4] := bufferI[z+2];
    k := k + 8;
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+1] := bufferI[z+1];
    memCODE[k+0] := bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+2] := bufferI[z+2];
    memCODE[k+6] := bufferI[z+1];
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+5] := bufferI[z+1];
    memCODE[k+4] := bufferI[z+2];
    k := k + 8;
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+1] := bufferI[z+1];
    memCODE[k+0] := bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+2] := bufferI[z+2];
    memCODE[k+6] := bufferI[z+1];
   end;
   if z<DIMBUF-2 then
   begin
    memCODE[k+5] := bufferI[z+1];
    memCODE[k+4] := bufferI[z+2];
    k := k + 8;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   i := i + 24;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadCodeErr2], dim, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  if executiveArea then
  begin
   j := 0;
   PrintMessage(strings[S_Read_EXE_A]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, '' + LineEnding + 'Executive area:' + LineEnding + '');
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := $45;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $87;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   j := 0;
   for i := 0,k=0 to (executiveArea) - 1 do
   begin
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG5;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := REGOUT;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(3);
    j := 0;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
    // init: z=0
    while bufferI[z] not =REGOUT and z<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: z++; *)
    end;
    if z<DIMBUF-2 then
    begin
     memExec[k+1] := bufferI[z+1];
     memExec[k] := bufferI[z+2];
    end;
    if z<DIMBUF-2 then
    begin
     memExec[k+2] := bufferI[z+2];
     memExec[k+6] := bufferI[z+1];
    end;
    if z<DIMBUF-2 then
    begin
     memExec[k+5] := bufferI[z+1];
     memExec[k+4] := bufferI[z+2];
    end;
    if z<DIMBUF-2 then
    begin
     memExec[k+9] := bufferI[z+1];
     memExec[k+8] := bufferI[z+2];
    end;
    if z<DIMBUF-2 then
    begin
     memExec[k+10] := bufferI[z+2];
     memExec[k+14] := bufferI[z+1];
    end;
    if z<DIMBUF-2 then
    begin
     memExec[k+13] := bufferI[z+1];
     memExec[k+12] := bufferI[z+2];
    end;
    PrintStatus(strings[S_CodeReading2], i*100/executiveArea, 0x800000+i/2);
    if RWstop then
     i := dim;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
    i := i + 16;
   end;
   if k not =executiveArea then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage2(strings[S_ReadCodeErr2], executiveArea, k);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  j := 0;
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'User ID:' + LineEnding + '');
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $86;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $DB;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $D3;
  bufferU[Inc(j)] := $D6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $DB;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $D3;
  bufferU[Inc(j)] := $D6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(3);
  j := 0;
  k := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
  begin
   UID[k+1] := bufferI[z+1];
   UID[k] := bufferI[z+2];
  end;
  if z<DIMBUF-2 then
  begin
   UID[k+2] := bufferI[z+2];
   UID[k+6] := bufferI[z+1];
  end;
  if z<DIMBUF-2 then
  begin
   UID[k+5] := bufferI[z+1];
   UID[k+4] := bufferI[z+2];
  end;
  if z<DIMBUF-2 then
  begin
   UID[k+9] := bufferI[z+1];
   UID[k+8] := bufferI[z+2];
  end;
  if z<DIMBUF-2 then
  begin
   UID[k+10] := bufferI[z+2];
   UID[k+14] := bufferI[z+1];
  end;
  if z<DIMBUF-2 then
  begin
   UID[k+13] := bufferI[z+1];
   UID[k+12] := bufferI[z+2];
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  stop := GetTickCount();
  PrintStatusClear();
  for i := 0 to (10) - 1 do
  begin
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE24F(dim);
  if executiveArea then
  begin
   empty := 1;
   aux := malloc((executiveArea/COL+1)*2*(16+COL*9));
   aux[0] := 0;
   s[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ExeMem]);
   for i := 0 to (executiveArea) - 1 do
   begin
    valid := 0;
    for j := i to (i+COL*2 and j<executiveArea) - 1 do
    begin
     d := (memExec[j+3] shl 24)+(memExec[j+2] shl 16)+(memExec[j+1] shl 8)+memExec[j];
     sprintf(t, '%08X ', d);
     strcat(s, t);
     if d not =0xffffffff then
      valid := 1;
     j := j + 4;
    end;
    i := i + COL*2;
   end;
   FreeMem(aux);
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double);
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
  confword: Integer;
  if(confword==1)bufferU[j++]=0x3A: Telse;
  if(confword==2)bufferU[j++]=0x4A: Telse;
  if(confword==3)bufferU[j++]=0x8A: Telse;
  Nconf: Integer;
  value: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := options&0xF;
  config := (options shr 4)&0xF;
  EEbaseAddr := 0x1000-dim2;
  newTABLPAG := IfThen(options&0x100000, 1, 0);
  err := 0;
  if FWVersion<0x700 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.7.0');
   Exit;
  end;
  if dim>0x80000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if j%(rowSize*4) then
  begin
   size := (j/(rowSize*4)+1)*rowSize*4;
   memCODE := realloc(memCODE, size);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<size;j++) memCODE[j]=0xFF *)
   // init: 
   while j<size do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
  end;
  if sizeEE<0x1000 then
   dim2 := 0;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  if config>2 then
  begin
   PrintMessage(strings[S_ConfigMem]);
   if config = 3 or config = 4 or config = 6 then
   begin
    PrintMessage1('0xF80000: FBS = 0x%02X\r' + LineEnding + '', memCONFIG[0]);
    if config = 4 then
    begin
     PrintMessage1('0xF80002: FSS = 0x%02X\r' + LineEnding + '', memCONFIG[4]);
    end;
    PrintMessage1('0xF80006: FOSCSEL = 0x%02X\r' + LineEnding + '', memCONFIG[12]);
    PrintMessage1('0xF80008: FOSC = 0x%02X\r' + LineEnding + '', memCONFIG[16]);
    PrintMessage1('0xF8000A: FWDT = 0x%02X\r' + LineEnding + '', memCONFIG[20]);
    PrintMessage1('0xF8000C: FPOR = 0x%02X\r' + LineEnding + '', memCONFIG[24]);
    PrintMessage1('0xF8000E: FICD = 0x%02X\r' + LineEnding + '', memCONFIG[28]);
    if config = 3 then
    begin
     PrintMessage1('0xF80010: FDS = 0x%02X\r' + LineEnding + '', memCONFIG[32]);
    end
    else if config = 4 then
    begin
     PrintMessage1('0xF80010: UID0 = 0x%02X\r' + LineEnding + '', memCONFIG[32]);
     PrintMessage1('0xF80012: UID1 = 0x%02X\r' + LineEnding + '', memCONFIG[36]);
     PrintMessage1('0xF80014: UID2 = 0x%02X\r' + LineEnding + '', memCONFIG[40]);
     PrintMessage1('0xF80016: UID3 = 0x%02X\r' + LineEnding + '', memCONFIG[44]);
    end;
   end
   else if config = 5 then
   begin
    PrintMessage2('0xF80000: FOSC = 0x%02X%02X\r' + LineEnding + '', memCONFIG[1], memCONFIG[0]);
    PrintMessage2('0xF80002: FWDT = 0x%02X%02X\r' + LineEnding + '', memCONFIG[5], memCONFIG[4]);
    PrintMessage2('0xF80004: FBORPOR = 0x%02X%02X\r' + LineEnding + '', memCONFIG[9], memCONFIG[8]);
    PrintMessage2('0xF80006: FBS = 0x%02X%02X\r' + LineEnding + '', memCONFIG[13], memCONFIG[12]);
    PrintMessage2('0xF80008: FSS = 0x%02X%02X\r' + LineEnding + '', memCONFIG[17], memCONFIG[16]);
    PrintMessage2('0xF8000A: FGS = 0x%02X%02X\r' + LineEnding + '', memCONFIG[21], memCONFIG[20]);
    PrintMessage2('0xF8000C: FICD = 0x%02X%02X\r' + LineEnding + '', memCONFIG[25], memCONFIG[24]);
   end;
  end
  else
  begin
   PrintMessage2('CONFIG1: 0x%04X\r' + LineEnding + 'CONFIG2: 0x%04X\r' + LineEnding + '', (memCODE[dim-3] shl 8)+memCODE[dim-4]\, (memCODE[dim-7] shl 8)+memCODE[dim-8]);
   if config = 1 then
   begin
    PrintMessage1('CONFIG3: 0x%04X\r' + LineEnding + '', (memCODE[dim-11] shl 8)+memCODE[dim-12]);
   end;
  end;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  if (entry = 0) or (entry = 3) then
  begin
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
  end
  else
   PrintMessage(strings[S_HVICSP]);
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 30000 shr 8;
  bufferU[Inc(j)] := 30000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  if entry = 2 then
  begin
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := ICSP_NOP;
  end
  else
  begin
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(37);
  j := 0;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX_LONG;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w0 := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z+=3
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w1 := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage2('DevID: 0x%04X\r' + LineEnding + 'DevRev: 0x%04X\r' + LineEnding + '', w0, w1);
  PIC24_ID(w0);
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := $44;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := (appIDaddr shr 4)&0xFF;
  bufferU[Inc(j)] := ((appIDaddr shl 4)&0xF0)+6;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := SIX_LONG;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w0 := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage2('ApplicationID @ 0x80%04X:  0x%04X\r' + LineEnding + '', appIDaddr, w0);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'ERASE:' + LineEnding + '');
  erase := (options&0xF00) shr 8;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $24;
  if erase = 0 then
  begin
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $4A;
  end
  else if erase = 1 then
  begin
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $FA;
  end
  else if erase>=2 then
  begin
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $FA;
  end;
  bufferU[Inc(j)] := $3B;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := SIX_LONG;
  bufferU[Inc(j)] := $BB;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  if erase>=2 then
  begin
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $61;
   bufferU[Inc(j)] := WAIT_T3;
   if erase = 3 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(20);
    msDelay(200);
    j := 0;
   end;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $A9;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $61;
  end
  else
  begin
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $61;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3C;
   bufferU[Inc(j)] := $22;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := REGOUT;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(7);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  w0 := bufferI[z+1]&0x80;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $3B;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $3C;
  bufferU[Inc(j)] := $22;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0;erase<2&&i<100&&w0;i++){ 		PacketIO(5); 		for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++); 		w0=bufferI[z+1]&0x80; 		msDelay(10); 	} 	if(saveLog)	fprintf(logfile,"\nErase time: %dms\n",i*12) *)
  // init: i=0
  while erase<2 and i<100 and w0 do
  begin
   PacketIO(5);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =REGOUT and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   w0 := bufferI[z+1]&0x80;
   msDelay(10);
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  msDelay(10);
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := IfThen(erase>0, $1A, $4A);
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $3B;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'WRITE CODE:' + LineEnding + '');
  PrintStatusSetup();
  High := 0;
  for i := 0,k=0 to (dim) - 1 do
  begin
   if k = 0 then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;!valid&&i<dim;i+=valid?0:rowSize*4){ 					for(k2=0;k2<rowSize*4&&!valid;k2++) if(memCODE[i+k2]<0xFF) valid=1; 				} 				if(i>=dim) break *)
    // init: valid=0
    while  not valid and i<dim do
    begin
     for k2 := 0 to (rowSize*4 and  not valid) - 1 do
     begin
     end;
     i := i + IfThen(valid, 0, rowSize*4);
    end;
   end;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0x20+((i shr 13)&0xF);
   bufferU[Inc(j)] := (i shr 5)&0xFF;
   bufferU[Inc(j)] := ((i shl 3)&0xF0)+7;
   bufferU[Inc(j)] := 0x20+((memCODE[i+1] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+1] shl 4)&0xF0)+((memCODE[i] shr 4)&0xF);
   bufferU[Inc(j)] := (memCODE[i] shl 4)&0xF0;
   bufferU[Inc(j)] := 0x20+((memCODE[i+6] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+6] shl 4)&0xF0)+((memCODE[i+2] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+2] shl 4)&0xF0)+1;
   bufferU[Inc(j)] := 0x20+((memCODE[i+5] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+5] shl 4)&0xF0)+((memCODE[i+4] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+4] shl 4)&0xF0)+2;
   bufferU[Inc(j)] := 0x20+((memCODE[i+9] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+9] shl 4)&0xF0)+((memCODE[i+8] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+8] shl 4)&0xF0)+3;
   bufferU[Inc(j)] := 0x20+((memCODE[i+14] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+14] shl 4)&0xF0)+((memCODE[i+10] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+10] shl 4)&0xF0)+4;
   bufferU[Inc(j)] := 0x20+((memCODE[i+13] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+13] shl 4)&0xF0)+((memCODE[i+12] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+12] shl 4)&0xF0)+5;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $B6;
   (* TODO gtk2laz: unrecognised statement: k++ *)
   if k = rowSize/4 then
   begin
    if erase>1 then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(3);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := IfThen(erase>0, $1A, $4A);
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $04;
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $00;
    end
    else
    begin
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $04;
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
    end;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(3);
   j := 0;
   PrintStatus(strings[S_CodeWriting2], i*100/(dim+dim2), i/2);
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i/2, i/2, k, k);
   end;
   i := i + 4*4;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'VERIFY CODE:' + LineEnding + '');
  PrintStatusSetup();
  High := $E0000000;
  r0 := 0;
  r1 := 0;
  r2 := 0;
  r3 := 0;
  for i := 0 to (dim) - 1 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;!valid&&i<dim;i+=valid?0:16){ 			for(k2=0;k2<16&&!valid;k2++) if(memCODE[i+k2]<0xFF) valid=1; 		} 		if(i>=dim) break *)
   // init: valid=0
   while  not valid and i<dim do
   begin
    for k2 := 0 to (16 and  not valid) - 1 do
    begin
    end;
    i := i + IfThen(valid, 0, 16);
   end;
   if (i shr 17) not =High then
   begin
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := (i shr 21)&0xFF;
    bufferU[Inc(j)] := (i shr 13)&0xF0;
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $88;
    if newTABLPAG then
    begin
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $A0;
    end
    else
    begin
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $90;
    end;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(2);
    j := 0;
    High := i shr 17;
   end;
   bufferU[Inc(j)] := 0x20+((i shr 13)&0xF);
   bufferU[Inc(j)] := (i shr 5)&0xFF;
   bufferU[Inc(j)] := ((i shl 3)&0xF0)+6;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(3);
   PrintStatus(strings[S_CodeV2], i*100/(dim+dim2), i/2);
   if RWstop then
    i := dim;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =REGOUT and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-2 then
   begin
    r0 := (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    r0 := r0 + bufferI[z+2] shl 16;
    r1 := bufferI[z+1] shl 16;
   end;
   if z<DIMBUF-2 then
   begin
    r1 := r1 + (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    r2 := (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    r2 := r2 + bufferI[z+2] shl 16;
    r3 := bufferI[z+1] shl 16;
   end;
   if z<DIMBUF-2 then
   begin
    r3 := r3 + (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   w1 := (memCODE[i+6] shl 16)+(memCODE[i+5] shl 8)+memCODE[i+4];
   w2 := (memCODE[i+10] shl 16)+(memCODE[i+9] shl 8)+memCODE[i+8];
   w3 := (memCODE[i+14] shl 16)+(memCODE[i+13] shl 8)+memCODE[i+12];
   CheckData(w0, r0, i/2, &err);
   CheckData(w1, r1, i/2+2, &err);
   CheckData(w2, r2, i/2+4, &err);
   CheckData(w3, r3, i/2+6, &err);
   PrintStatus(strings[S_CodeV2], i*100/dim, i/2);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i/2, i/2, k, k, err);
   end;
   i := i + 16;
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if err>=max_err then
  begin
   PrintMessage1(strings[S_MaxErr], err);
  end;
  j := 0;
  if config>2 and config<5 and err<max_err then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
    fprintf(logfile, '' + LineEnding + 'WRITE CONFIG:' + LineEnding + '');
   confword := (options&0xF0000) shr 16;
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $88;
   if newTABLPAG then
   begin
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
   end
   else
   begin
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $90;
   end;
   bufferU[Inc(j)] := $00;
   if confword = 0 then
    bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := ICSP_NOP;
   for i := 0 to (12) - 1 do
   begin
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := (memCONFIG[i*4] shr 4)&0xF;
    bufferU[Inc(j)] := (memCONFIG[i*4] shl 4)&0xF0;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $BB;
    bufferU[Inc(j)] := $1B;
    bufferU[Inc(j)] := $80;
    if memCONFIG[i*4]<0xFF then
    begin
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := ICSP_NOP;
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    msDelay(27);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   PrintStatusClear();
   err := err + errC;
  end
  else if config>=5 and err<max_err then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
    fprintf(logfile, '' + LineEnding + 'WRITE CONFIG:' + LineEnding + '');
   Nconf := IfThen(config = 5, 7, 8);
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $88;
   if newTABLPAG then
   begin
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
   end
   else
   begin
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $90;
   end;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := ICSP_NOP;
   for i := 0 to (Nconf) - 1 do
   begin
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $2F;
    bufferU[Inc(j)] := $FF;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $BB;
    bufferU[Inc(j)] := $1B;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := SIX_N;
    bufferU[Inc(j)] := 6;
    bufferU[Inc(j)] := $24;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $8A;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $3B;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $05;
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $3B;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $A8;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $3B;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $A8;
    bufferU[Inc(j)] := $E7;
    bufferU[Inc(j)] := $61;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $A9;
    bufferU[Inc(j)] := $E7;
    bufferU[Inc(j)] := $61;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(3);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $07;
   for i := 0 to (Nconf) - 1 do
   begin
    value := memCONFIG[i*4]+(memCONFIG[i*4+1] shl 8);
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := 0x20+(value shr 12);
    bufferU[Inc(j)] := (value shr 4);
    bufferU[Inc(j)] := (value shl 4);
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $BB;
    bufferU[Inc(j)] := $1B;
    bufferU[Inc(j)] := $80;
    if value<0xFFFF then
    begin
     bufferU[Inc(j)] := SIX_N;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $8A;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := ICSP_NOP;
     bufferU[Inc(j)] := SIX_LONG;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(3);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(3);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   PrintStatusClear();
   err := err + errC;
  end;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double);
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
  if FWVersion<0x900 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.9.0');
   Exit;
  end;
  if dim>0x100000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  for i := 0 to (10) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 55000 shr 8;
  bufferU[Inc(j)] := 55000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(65);
  j := 0;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w0 := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z+=3
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w1 := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage2('DevID: 0x%04X\r' + LineEnding + 'DevRev: 0x%04X\r' + LineEnding + '', w0, w1);
  PIC24_ID(w0);
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := $44;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := 0x20+((appIDaddr shr 12)&0xF);
  bufferU[Inc(j)] := (appIDaddr shr 4)&0xFF;
  bufferU[Inc(j)] := ((appIDaddr shl 4)&0xF0)+6;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
   w0 := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage2('ApplicationID @ 0x80%04X:  0x%04X\r' + LineEnding + '', appIDaddr, w0);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'ERASE:' + LineEnding + '');
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $DA;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $4A;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $7C;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $71;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $A1;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $71;
  bufferU[Inc(j)] := SIX_LONG5;
  bufferU[Inc(j)] := $A8;
  bufferU[Inc(j)] := $E7;
  bufferU[Inc(j)] := $29;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $7C;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(4);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =REGOUT and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  w0 := bufferI[z+1]&0x80;
  w0 := 1;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $7C;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := REGOUT;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  j := 0;
  for i := 0 to (50 and w0) - 1 do
  begin
   PacketIO(5);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =REGOUT and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   w0 := bufferI[z+1]&0x80;
   msDelay(10);
  end;
  msDelay(70);
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := ICSP_NOP;
  bufferU[Inc(j)] := SIX_N;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $1A;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $4A;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'WRITE CODE:' + LineEnding + '');
  PrintStatusSetup();
  High := 0;
  for i := 0,k=0 to (dim) - 1 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;!valid&&i<dim;i+=valid?0:2*4){ 			for(k2=0;k2<2*4&&!valid;k2++) if(memCODE[i+k2]<0xFF) valid=1; 		} 		if(i>=dim) break *)
   // init: valid=0
   while  not valid and i<dim do
   begin
    for k2 := 0 to (2*4 and  not valid) - 1 do
    begin
    end;
    i := i + IfThen(valid, 0, 2*4);
   end;
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := 0x20+((memCODE[i+1] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+1] shl 4)&0xF0)+((memCODE[i] shr 4)&0xF);
   bufferU[Inc(j)] := (memCODE[i] shl 4)&0xF0;
   bufferU[Inc(j)] := 0x20+((memCODE[i+6] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+6] shl 4)&0xF0)+((memCODE[i+2] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+2] shl 4)&0xF0)+1;
   bufferU[Inc(j)] := 0x20+((memCODE[i+5] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+5] shl 4)&0xF0)+((memCODE[i+4] shr 4)&0xF);
   bufferU[Inc(j)] := ((memCODE[i+4] shl 4)&0xF0)+2;
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := $84;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := SIX_N;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0x20+((i shr 13)&0xF);
   bufferU[Inc(j)] := (i shr 5)&0xFF;
   bufferU[Inc(j)] := ((i shl 3)&0xF0)+3;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := (i shr 21)&0xFF;
   bufferU[Inc(j)] := ((i shr 13)&0xF0)+4;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $53;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $64;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $51;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $71;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $A1;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $71;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $29;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   j := 0;
   PrintStatus(strings[S_CodeWriting2], i*100/(dim+dim2), i/2);
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i/2, i/2, k, k);
   end;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $42;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $42;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   j := 0;
   PacketIO(2);
   i := i + 2*4;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, '' + LineEnding + 'VERIFY CODE:' + LineEnding + '');
  PrintStatusSetup();
  High := $E0000000;
  r0 := 0;
  r1 := 0;
  r2 := 0;
  r3 := 0;
  for i := 0 to (dim) - 1 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;!valid&&i<dim;i+=valid?0:16){ 			for(k2=0;k2<16&&!valid;k2++) if(memCODE[i+k2]<0xFF) valid=1; 		} 		if(i>=dim) break *)
   // init: valid=0
   while  not valid and i<dim do
   begin
    for k2 := 0 to (16 and  not valid) - 1 do
    begin
    end;
    i := i + IfThen(valid, 0, 16);
   end;
   if (i shr 17) not =High then
   begin
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := (i shr 21)&0xFF;
    bufferU[Inc(j)] := (i shr 13)&0xF0;
    bufferU[Inc(j)] := SIX;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := SIX_LONG;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := ICSP_NOP;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(2);
    j := 0;
    High := i shr 17;
   end;
   bufferU[Inc(j)] := 0x20+((i shr 13)&0xF);
   bufferU[Inc(j)] := (i shr 5)&0xFF;
   bufferU[Inc(j)] := ((i shl 3)&0xF0)+6;
   bufferU[Inc(j)] := SIX;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $87;
   bufferU[Inc(j)] := ICSP_NOP;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := REGOUT;
   bufferU[Inc(j)] := SIX_LONG5;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(4);
   PrintStatus(strings[S_CodeV2], i*100/(dim+dim2), i/2);
   if RWstop then
    i := dim;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=REGOUT&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =REGOUT and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-2 then
   begin
    r0 := (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    r0 := r0 + bufferI[z+2] shl 16;
    r1 := bufferI[z+1] shl 16;
   end;
   if z<DIMBUF-2 then
   begin
    r1 := r1 + (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    r2 := (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-2 then
   begin
    r2 := r2 + bufferI[z+2] shl 16;
    r3 := bufferI[z+1] shl 16;
   end;
   if z<DIMBUF-2 then
   begin
    r3 := r3 + (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   w1 := (memCODE[i+6] shl 16)+(memCODE[i+5] shl 8)+memCODE[i+4];
   w2 := (memCODE[i+10] shl 16)+(memCODE[i+9] shl 8)+memCODE[i+8];
   w3 := (memCODE[i+14] shl 16)+(memCODE[i+13] shl 8)+memCODE[i+12];
   CheckData(w0, r0, i/2, &err);
   CheckData(w1, r1, i/2+2, &err);
   CheckData(w2, r2, i/2+4, &err);
   CheckData(w3, r3, i/2+6, &err);
   PrintStatus(strings[S_CodeV2], i*100/dim, i/2);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i/2, i/2, k, k, err);
   end;
   i := i + 16;
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if err>=max_err then
  begin
   PrintMessage1(strings[S_MaxErr], err);
  end;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

end.

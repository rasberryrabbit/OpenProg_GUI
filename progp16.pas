unit progp16;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

const
  LOAD_PC_ADDR = $80;
  BULK_ERASE_PROGRAM_MEM = $18;
  ROW_ERASE_PROGRAM_MEM = $F0;
  LOAD_NVM = $00;
  LOAD_NVM_INC = $02;
  READ_NVM = $FC;
  READ_NVM_INC = $FE;
  INC_ADDR8 = $F8;
  BEGIN_INT_PROG = $E0;
  BEGIN_EXT_PROG = $C0;
  END_EXT_PROG = $82;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  v: array[0..256-1] of Char;
  k: Integer;
  k2: Integer;
  z: Integer;
  ee2200: Integer;
  aux: Char;
  start: Cardinal;
  stop: Cardinal;

// --- function declarations ---
procedure PIC16_ID(id: Integer);
procedure DisplayCODE16F(size: Integer);
procedure Read16F1xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer);
procedure Read16F18xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer);
procedure Write12F6xx(dim: Integer; dim2: Integer);
procedure Write16F8x(dim: Integer; dim2: Integer);
procedure Write16F62x(dim: Integer; dim2: Integer);
procedure Write12F62x(dim: Integer; dim2: Integer);
procedure Write16F87x(dim: Integer; dim2: Integer);
procedure Write16F87xA(dim: Integer; dim2: Integer; seq: Integer);
procedure Write16F81x(dim: Integer; dim2: Integer);
procedure Write12F61x(dim: Integer; d: Integer; d2: Integer);
procedure Write16F88x(dim: Integer; dim2: Integer);
procedure Write16F7x(dim: Integer; vdd: Integer);
procedure Write16F71x(dim: Integer; vdd: Integer);
procedure Write16F72x(dim: Integer; d: Integer; d2: Integer);
procedure Write16F1xxx(dim: Integer; dim2: Integer; options: Integer);
procedure Write16F18xxx(dim: Integer; dim2: Integer; options: Integer);

implementation

procedure PIC16_ID(id: Integer);
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (sizeof(PIC16LIST)/sizeof(PIC16LIST[0])) - 1 do
  begin
   if PIC16LIST[i].revmask and (id shr 5) = PIC16LIST[i].id then
   begin
    sprintf(s, PIC16LIST[i].device, id&PIC16LIST[i].revmask);
    PrintMessage(s);
    Exit;
   end
   else if  not PIC16LIST[i].revmask and id = PIC16LIST[i].id then
   begin
    sprintf(s, PIC16LIST[i].device);
    PrintMessage(s);
    Exit;
   end;
  end;
  PrintMessage(s);
end;

procedure DisplayCODE16F(size: Integer);
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
  PrintMessage(aux): Telse;
begin
  (* TODO gtk2laz: array initializer: s[256]=""; *)
  (* TODO gtk2laz: array initializer: t[256]=""; *)
  aux := malloc((size/COL+1)*(16+COL*5));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  for i := 0 to (size and i<sizeW) - 1 do
  begin
   valid := 0;
   for j := i to (i+COL and j<sizeW and i<size) - 1 do
   begin
    sprintf(t, '%04X ', memCODE_W[j]);
    strcat(s, t);
    if (memCODE_W[j]&0x3fff)<0x3fff then
     valid := 1;
   end;
   i := i + COL;
  end;
  FreeMem(aux);
end;

procedure Read16F1xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer);
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  F18x: Integer;
  start: Cardinal;
  stop: Cardinal;
  valid: Integer;
  empty: Integer;
  PrintMessage(aux): Telse;
begin
  k := 0;
  k2 := 0;
  z := 0;
  F18x := options&16;
  if F18x and FWVersion<0xA00 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.10.0');
   Exit;
  end;
  if dim>0x8000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read16F1xxx(%d,%d,%d,%d)' + LineEnding + '', dim, dim2, dim3, options);
  end;
  sizeW := $8200;
  if F18x then
   sizeW := $E004;
  sizeEE := dim2;
  if memCODE_W then
   FreeMem(memCODE_W);
  memCODE_W := malloc(sizeof(WORD)*sizeW);
  for i := 0 to (sizeW) - 1 do
  begin
  end;
  if memEE then
   FreeMem(memEE);
  memEE := malloc(sizeEE);
  for i := 0 to (sizeEE) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  if (options&2) = 0 then
  begin
   if (options&1) = 0 then
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_CodeReading1]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := READ_DATA_PROG;
   bufferU[Inc(j)] := INC_ADDR;
   if j>DIMBUF*2/4-3 or i = dim-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = READ_DATA_PROG then
     begin
      memCODE_W[Inc(k)] := (bufferI[z+1] shl 8)+bufferI[z+2];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadCodeErr], dim, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_Read_CONFIG_A]);
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  for i := $8000 to (0x8000+dim3) - 1 do
  begin
   bufferU[Inc(j)] := READ_DATA_PROG;
   bufferU[Inc(j)] := INC_ADDR;
   if j>DIMBUF*2/4-3 or i = 0x8000+dim3-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = READ_DATA_PROG then
     begin
      memCODE_W[0x8000+Inc(k2)] := (bufferI[z+1] shl 8)+bufferI[z+2];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if F18x then
  begin
   k2 := 0;
   PrintMessage(strings[S_Read_CONFIG_A]);
   bufferU[Inc(j)] := LOAD_PC;
   bufferU[Inc(j)] := $E0;
   bufferU[Inc(j)] := $00;
   for i := 0 to (4) - 1 do
   begin
   end;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   for z := 0 to (DIMBUF-2) - 1 do
   begin
    if bufferI[z] = READ_DATA_INC then
    begin
     memCODE_W[0xE000+Inc(k2)] := (bufferI[z+1] shl 8)+bufferI[z+2];
     z := z + 2;
    end;
   end;
   if saveLog then
   begin
    fprintf(logfile, 'Calibration area @0xE000' + LineEnding + '');
   end;
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  for i := 0 to (4) - 1 do
  begin
   PrintMessage4('ID%d: 0x%04X' + #9 + 'ID%d: 0x%04X\r' + LineEnding + '', i, memCODE_W[0x8000+i], i+1, memCODE_W[0x8000+i+1]);
   i := i + 2;
  end;
  if memCODE_W[0x8005]<0x3FFF then
   PrintMessage1(strings[S_DevREV], memCODE_W[0x8005]);
  PIC16_ID(memCODE_W[0x8006]);
  PrintMessage2(strings[S_ConfigWordX], 1, memCODE_W[0x8007]);
  PrintMessage2(strings[S_ConfigWordX], 2, memCODE_W[0x8008]);
  if (options&0xC) = 0 and F18x = 0 then
  begin
   PrintMessage2(strings[S_CalibWordX], 1, memCODE_W[0x8009]);
   PrintMessage2(strings[S_CalibWordX], 2, memCODE_W[0x800A]);
   if memCODE_W[0x800B]<0x3FFF then
    PrintMessage2(strings[S_CalibWordX], 3, memCODE_W[0x800B]);
  end
  else if (options&0xC) = 4 and F18x = 0 then
  begin
   PrintMessage2(strings[S_ConfigWordX], 3, memCODE_W[0x8009]);
   PrintMessage2(strings[S_CalibWordX], 1, memCODE_W[0x800A]);
   PrintMessage2(strings[S_CalibWordX], 2, memCODE_W[0x800B]);
   PrintMessage2(strings[S_CalibWordX], 3, memCODE_W[0x800C]);
  end
  else if (options&0xC) = 8 then
  begin
   PrintMessage2(strings[S_ConfigWordX], 3, memCODE_W[0x8009]);
   PrintMessage2(strings[S_ConfigWordX], 4, memCODE_W[0x800A]);
  end;
  DisplayCODE16F(dim);
  if dim3>15 then
  begin
   valid := 0;
   empty := 1;
   s[0] := 0;
   aux := malloc(dim3/COL*(16+COL*5));
   aux[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ConfigResMem]);
   for i := $8000 to (0x8000+dim3) - 1 do
   begin
    valid := 0;
    for j := i to (i+COL and j<0x8000+dim3) - 1 do
    begin
     sprintf(t, '%04X ', memCODE_W[j]);
     strcat(s, t);
     if memCODE_W[j]<0x3fff then
      valid := 1;
    end;
    i := i + COL;
   end;
   FreeMem(aux);
  end;
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Read16F18xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer);
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  useDCI: Integer;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  useDCI := IfThen((options&0x10) = 0, 1, 0);
  if FWVersion<0xB00 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.11.0');
   Exit;
  end;
  if dim>0x8000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  sizeW := $8220;
  if memCODE_W then
   FreeMem(memCODE_W);
  memCODE_W := malloc(sizeof(WORD)*sizeW);
  for i := 0 to (sizeW) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  if (options&2) = 0 then
  begin
   if (options&1) = 0 then
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_CodeReading1]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   if (j+1)/2*3+3>DIMBUF or i = dim-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = ICSP8_READ then
     begin
      memCODE_W[Inc(k)] := (bufferI[z+1] shl 8)+bufferI[z+2];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadCodeErr], dim, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_Read_CONFIG_A]);
  bufferU[Inc(j)] := ICSP8_LOAD;
  bufferU[Inc(j)] := LOAD_PC_ADDR;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $00;
  k2 := 0;
  for i := $8000 to ($8010) - 1 do
  begin
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   if (j+1)/2*3+3>DIMBUF or i = 0x800F then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = ICSP8_READ then
     begin
      memCODE_W[0x8000+Inc(k2)] := (bufferI[z+1] shl 8)+bufferI[z+2];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if useDCI then
  begin
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, 'Read device info area @0x8100' + LineEnding + '');
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := $00;
   k2 := 0;
   for i := $8100 to ($8120) - 1 do
   begin
    bufferU[Inc(j)] := ICSP8_READ;
    bufferU[Inc(j)] := READ_NVM_INC;
    if (j+1)/2*3+3>DIMBUF or i = 0x811F then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(5);
     for z := 0 to (DIMBUF-2) - 1 do
     begin
      if bufferI[z] = ICSP8_READ then
      begin
       memCODE_W[0x8100+Inc(k2)] := (bufferI[z+1] shl 8)+bufferI[z+2];
       z := z + 2;
      end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
   end;
   if saveLog then
    fprintf(logfile, 'Read Device Configuration Information @0x8200' + LineEnding + '');
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := $82;
   bufferU[Inc(j)] := $00;
   k2 := 0;
   for i := $8200 to ($8220) - 1 do
   begin
    bufferU[Inc(j)] := ICSP8_READ;
    bufferU[Inc(j)] := READ_NVM_INC;
    if (j+1)/2*3+3>DIMBUF or i = 0x821F then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(5);
     for z := 0 to (DIMBUF-2) - 1 do
     begin
      if bufferI[z] = ICSP8_READ then
      begin
       memCODE_W[0x8200+Inc(k2)] := (bufferI[z+1] shl 8)+bufferI[z+2];
       z := z + 2;
      end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
   end;
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  for i := 0 to (4) - 1 do
  begin
   PrintMessage4('ID%d: 0x%04X' + #9 + 'ID%d: 0x%04X\r' + LineEnding + '', i, memCODE_W[0x8000+i], i+1, memCODE_W[0x8000+i+1]);
   i := i + 2;
  end;
  if memCODE_W[0x8005]<0x3FFF then
   PrintMessage1(strings[S_DevREV], memCODE_W[0x8005]);
  PIC16_ID(memCODE_W[0x8006]);
  for i := 0 to (5) - 1 do
  begin
   PrintMessage2(strings[S_ConfigWordX], i+1, memCODE_W[0x8007+i]);
  end;
  DisplayCODE16F(dim);
  if dim2 then
   DisplayEE();
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write12F6xx(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  calib1: Word;
  calib2: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  bufferU: array[0..j++-1] of Telse;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  err_e: Integer;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+3]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+4]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+4]);	 							err_e++; 							if(max_err&&err+err_e>max_err){ 								PrintMessage1(strings[S_MaxErr],err+err_e);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=5; 					}: Telse;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  calib1 := $3fff;
  calib2 := $3fff;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  calib1 := (bufferI[z+1] shl 8)+bufferI[z+2];
  if calib1<0x3fff then
  begin
   PrintMessage1(strings[S_CalibWord1], calib1);
  end;
  calib2 := (bufferI[z+1] shl 8)+bufferI[z+2];
  if calib2<0x3fff then
  begin
   PrintMessage1(strings[S_CalibWord2], calib2);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := WAIT_T3;
  if programID or load_calibword or ICDenable then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if load_calibword then
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    if load_calibword = 2 then
     bufferU[Inc(j)] := $09;
    (* TODO gtk2laz: array initializer: bufferU[j++]=0x08; *)
   end;
  end;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := BULK_ERASE_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  if dim2 then
  begin
   bufferU[Inc(j)] := BULK_ERASE_DATA;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 4000 shr 8;
  bufferU[Inc(j)] := 4000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(50);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG;			 			bufferU *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-12 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*5+2);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := SET_PARAMETER;
   bufferU[Inc(j)] := SET_T3;
   bufferU[Inc(j)] := 8000 shr 8;
   bufferU[Inc(j)] := 8000&0xff;
   bufferU[Inc(j)] := BULK_ERASE_DATA;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 0x2100-0x2001;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=2,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG;			 				bufferU[j++]=WAIT_T3;				 				 *)
   // init: w=2,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-12 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*9+2);
     w := 0;
     for z := 0 to (DIMBUF-4) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   err := err + err_e;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], err_e);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := 0x2800+(ICDaddr&0x7FF);
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 4000 shr 8;
  bufferU[Inc(j)] := 4000&0xff;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 4;
  end;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if load_calibword then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := READ_DATA_PROG;
   bufferU[Inc(j)] := INC_ADDR;
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2009] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2009]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(35);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F8x(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  config: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  r: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+3]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+4]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+4]);	 							err++; 							if(max_err&&err>max_err){ 								PrintMessage1(strings[S_MaxErr],err);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=5; 					}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 25000 shr 8;
  bufferU[Inc(j)] := 25000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(140);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  config := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_ConfigWord], config);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  if config<0x3FF0 then
  begin
   PrintMessage(strings[S_ProtErase]);
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
  end
  else if devID shr 5 = 0x2B then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := $3f;
   bufferU[Inc(j)] := $ff;
   bufferU[Inc(j)] := BULK_ERASE_PROG;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   if dim2 then
   begin
    bufferU[Inc(j)] := LOAD_DATA_DATA;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := BULK_ERASE_DATA;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := $3f;
   bufferU[Inc(j)] := $ff;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   if dim2 then
   begin
    bufferU[Inc(j)] := LOAD_DATA_DATA;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $07;
   end;
  end;
  bufferU[Inc(j)] := SET_T3;
  r := IfThen((devID shr 5 = 0x2B), 8000, 20000);
  bufferU[Inc(j)] := r shr 8;
  bufferU[Inc(j)] := r&0xff;
  bufferU[Inc(j)] := FLUSH;
  r := r / 1000;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen( not programID, 140, 60));
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG;			 			bufferU *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-10 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*r+4);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 1;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=0,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG;			 				bufferU[j++]=WAIT_T3;				 				 *)
   // init: w=0,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-10 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*r+5);
     w := 0;
     for z := 0 to (DIMBUF-4) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], i-k);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(programID, 125, 35));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
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
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F62x(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  config: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+3]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+4]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+4]);	 							err++; 							if(max_err&&err>max_err){ 								PrintMessage1(strings[S_MaxErr],err);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=5; 					}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(12);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  config := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_ConfigWord], config);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 5000 shr 8;
  bufferU[Inc(j)] := 5000&0xff;
  if config<0x3C00 then
  begin
   PrintMessage(strings[S_ProtErase]);
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
  end
  else
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := $3f;
   bufferU[Inc(j)] := $ff;
   bufferU[Inc(j)] := BULK_ERASE_PROG;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   if dim2 then
   begin
    bufferU[Inc(j)] := LOAD_DATA_DATA;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := BULK_ERASE_DATA;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
   end;
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 8000 shr 8;
  bufferU[Inc(j)] := 8000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(60);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG2;			 			buffer *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-10 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*9+2);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $2;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=0,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG2;			 				bufferU[j++]=WAIT_T3;				 			 *)
   // init: w=0,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG2;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-10 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*14+1);
     w := 0;
     for z := 0 to (DIMBUF-4) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], i-k);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG2;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(programID, 125, 35));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage3(strings[S_IDErr],i,memCODE_W[0x2000+i] *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
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
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write12F62x(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  config: Word;
  osccal: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+3]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+4]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+4]);	 							err++; 							if(max_err&&err>max_err){ 								PrintMessage1(strings[S_MaxErr],err);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=5; 					}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  for i := 0 to (dim-0xff) - 1 do
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $ff;
   i := i + $ff;
  end;
  bufferU[Inc(j)] := dim-1-i;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  osccal := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  config := (bufferI[z+1] shl 8)+bufferI[z+1];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  if programID then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 3000 shr 8;
  bufferU[Inc(j)] := 3000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(40);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  if  not load_osccal then
   memCODE_W[dim-1] := osccal;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG;			 			bufferU *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-10 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*6.5+j*0.1);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  err := err + i-k;
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := SET_PARAMETER;
   bufferU[Inc(j)] := SET_T3;
   bufferU[Inc(j)] := 6000 shr 8;
   bufferU[Inc(j)] := 6000&0xff;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := BULK_ERASE_DATA;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=3,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG;			 				bufferU[j++]=WAIT_T3;				 				 *)
   // init: w=3,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-10 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*7+2);
     w := 0;
     for z := 0 to (DIMBUF-4) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], i-k);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(35);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage3(strings[S_IDErr],i,memCODE_W[0x2000+i] *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F87x(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  config: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  ee2200: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  err_e: Integer;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  ee2200 := 0;
  if dim2<0 then
  begin
   dim2 := -dim2;
   ee2200 := 1;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(60);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  config := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_ConfigWord], config);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 8000 shr 8;
  bufferU[Inc(j)] := 8000&0xff;
  if (config&0x3130) not =0x3130 then
  begin
   PrintMessage(strings[S_ProtErase]);
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := NOP;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $5;
  end
  else
  begin
   if ICDenable or programID then
   begin
    bufferU[Inc(j)] := LOAD_CONF;
    bufferU[Inc(j)] := $3F;
    bufferU[Inc(j)] := $FF;
   end;
   bufferU[Inc(j)] := $3f;
   bufferU[Inc(j)] := $ff;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $07;
   if dim2 then
   begin
    bufferU[Inc(j)] := LOAD_DATA_DATA;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $07;
   end;
  end;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 4000 shr 8;
  bufferU[Inc(j)] := 4000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(60);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG2;			 			buffer *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-10 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*5+2);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 1;
   if ee2200 then
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := $FF;
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := 1;
   end;
   err := err + err_e;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], err_e);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := 0x2800+(ICDaddr&0x7FF);
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 8000 shr 8;
  bufferU[Inc(j)] := 8000&0xff;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 4;
  end;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG2;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(programID, 125, 35));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage3(strings[S_IDErr],i,memCODE_W[0x2000+i] *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F87xA(dim: Integer; dim2: Integer; seq: Integer);
var
  err: Integer;
  devID: Word;
  config: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+4]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+5]<<8)+bufferI[z+6]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+5]<<8)+bufferI[z+6]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=7; 				}: Telse;
  err_e: Integer;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+3]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+4]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+4]);	 							err_e++; 							if(max_err&&err>max_err){ 								PrintMessage1(strings[S_MaxErr],err);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=5; 					}: Telse;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  bufferU[0] := 0;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 25000 shr 8;
  bufferU[Inc(j)] := 25000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if seq = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(seq = 0, 90, 40));
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  config := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_ConfigWord], config);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 15000 shr 8;
  bufferU[Inc(j)] := 15000&0xff;
  if ICDenable or programID then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := $1F;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 1200 shr 8;
  bufferU[Inc(j)] := 1200&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(60);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG2;			 			buffer *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-11 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*1.5+(6-w)*0.2+2);
    w := 0;
    for z := 0 to (DIMBUF-6) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := SET_PARAMETER;
   bufferU[Inc(j)] := SET_T3;
   bufferU[Inc(j)] := 12000 shr 8;
   bufferU[Inc(j)] := 12000&0xff;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 1;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=0,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG;			 				bufferU[j++]=WAIT_T3;				 				 *)
   // init: w=0,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-10 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*12.5+5);
     w := 0;
     for z := 0 to (DIMBUF-4) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   err := err + err_e;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], err_e);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := 0x2800+(ICDaddr&0x7FF);
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 12000 shr 8;
  bufferU[Inc(j)] := 12000&0xff;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 4;
  end;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if sizeW>0x2008 and memCODE_W[0x2008] not =0x3fff then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  i := 28;
  if programID then
   i := i + 50;
  if ICDenable then
   i := i + 13;
  PacketIO(i);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage3(strings[S_IDErr],i,memCODE_W[0x2000+i] *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F81x(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  config: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+4]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+5]<<8)+bufferI[z+6]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+5]<<8)+bufferI[z+6]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=7; 				}: Telse;
  err_e: Integer;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+4]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+5]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+5]);	 							err_e++; 							if(max_err&&err>max_err){ 								PrintMessage1(strings[S_MaxErr],err);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=6; 					}: Telse;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 25000 shr 8;
  bufferU[Inc(j)] := 25000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(40);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  config := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_ConfigWord], config);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  if programID or ICDenable then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG2;			 			buffer *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-11 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*2.5+3);
    w := 0;
    for z := 0 to (DIMBUF-6) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := LOAD_DATA_DATA;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := BULK_ERASE_DATA;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=0,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG2;			 				bufferU[j++]=WAIT_T3;				 			 *)
   // init: w=0,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG2;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := CUST_CMD;
     bufferU[Inc(j)] := $17;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-10 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*2.5+5);
     w := 0;
     for z := 0 to (DIMBUF-5) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   err := err + err_e;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], err_e);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := 0x2800+(ICDaddr&0x7FF);
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := CUST_CMD;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 4;
  end;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG2;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := CUST_CMD;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if sizeW>0x2008 and memCODE_W[0x2008] not =0x3fff then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG2;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage3(strings[S_IDErr],i,memCODE_W[0x2000+i] *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write12F61x(dim: Integer; d: Integer; d2: Integer);
var
  err: Integer;
  devID: Word;
  devREV: Word;
  calib1: Word;
  calib2: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+5]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+6]<<8)+bufferI[z+7]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=8; 				}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  devREV := $3fff;
  calib1 := $3fff;
  calib2 := $3fff;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devREV := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  if devREV<0x3FFF then
   PrintMessage1(strings[S_DevREV], devREV);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  calib1 := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  calib2 := (bufferI[z+1] shl 8)+bufferI[z+2];
  if calib1<0x3fff then
   PrintMessage1(strings[S_CalibWord1], calib1);
  if calib2<0x3fff then
   PrintMessage1(strings[S_CalibWord2], calib2);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  if programID or load_calibword then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if load_calibword then
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := $08;
   end;
  end;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 4000 shr 8;
  bufferU[Inc(j)] := 4000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(40);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG2;			 			buffer *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG;
    bufferU[Inc(j)] := WAIT_T2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-12 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*5+2.5);
    w := 0;
    for z := 0 to (DIMBUF-7) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG;
    bufferU[Inc(j)] := WAIT_T2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG2;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := END_PROG;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if load_calibword then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG2;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := END_PROG;
   bufferU[Inc(j)] := WAIT_T2;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(35);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F88x(dim: Integer; dim2: Integer);
var
  err: Integer;
  devID: Word;
  calib1: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  if(bufferI[z]==LOAD_DATA_DATA&&bufferI[z+3]==READ_DATA_DATA){ 						if (memCODE_W[k]!=bufferI[z+4]){ 							PrintMessage("\r\n"); 							PrintMessage3(strings[S_CodeWError3],k,memCODE_W[k],bufferI[z+4]);	 							err++; 							if(max_err&&err>max_err){ 								PrintMessage1(strings[S_MaxErr],err);	 								PrintMessage(strings[S_IntW]);	 								i=0x2200; 								z=DIMBUF; 							} 						} 						k++; 						z+=5; 					}: Telse;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  calib1 := $3fff;
  k := 0;
  z := 0;
  if sizeW<0x2009 then
  begin
   PrintMessage(strings[S_NoConfigW4]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 6000 shr 8;
  bufferU[Inc(j)] := 6000&0xff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  calib1 := (bufferI[z+1] shl 8)+bufferI[z+2];
  if calib1<0x3fff then
  begin
   PrintMessage1(strings[S_CalibWord1], calib1);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  if programID or load_calibword or ICDenable then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if load_calibword then
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := 9;
   end;
  end;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 3000 shr 8;
  bufferU[Inc(j)] := 3000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(40);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG;			 			bufferU *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-12 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*3+2);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := SET_PARAMETER;
   bufferU[Inc(j)] := SET_T3;
   bufferU[Inc(j)] := 6000 shr 8;
   bufferU[Inc(j)] := 6000&0xff;
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := BULK_ERASE_DATA;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 1;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=2,i=k=0x2100;i<0x2100+dim2;i++){ 			if(memCODE_W[i]<0xff){ 				bufferU[j++]=LOAD_DATA_DATA; 				bufferU[j++]=memCODE_W[i]&0xff; 				bufferU[j++]=BEGIN_PROG;			 				bufferU[j++]=WAIT_T3;				 				 *)
   // init: w=2,i=k=0x2100
   while i<0x2100+dim2 do
   begin
    if memCODE_W[i]<0xff then
    begin
     bufferU[Inc(j)] := LOAD_DATA_DATA;
     bufferU[Inc(j)] := memCODE_W[i]&0xff;
     bufferU[Inc(j)] := BEGIN_PROG;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := READ_DATA_DATA;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end;
    if j>DIMBUF-12 or i = 0x2100+dim2-1 then
    begin
     PrintStatus(strings[S_CodeWriting], (i-0x2100+dim)*100/(dim+dim2), i);
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(w*6.5+2);
     w := 0;
     for z := 0 to (DIMBUF-4) - 1 do
     begin
      if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xff then
       (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], i-k);
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := 0x2800+(ICDaddr&0x7FF);
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 3000 shr 8;
  bufferU[Inc(j)] := 3000&0xff;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 4;
  end;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if load_calibword then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2009] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2009]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(35);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  if ~memCODE_W[0x2008]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2008], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F7x(dim: Integer; vdd: Integer);
var
  err: Integer;
  devID: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+4]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+5]<<8)+bufferI[z+6]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+5]<<8)+bufferI[z+6]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=7; 				}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if vdd = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(vdd, 20, 70));
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if vdd = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := BULK_ERASE_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(vdd, 50, 100));
  PrintMessage(strings[S_Compl]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if vdd = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 1000 shr 8;
  bufferU[Inc(j)] := 1000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(vdd, 2, 52));
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG;			 			bufferU *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-10 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*1.5+2);
    w := 0;
    for z := 0 to (DIMBUF-6) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := END_PROG2;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if sizeW>0x2008 and memCODE_W[0x2008]<0x3fff then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := END_PROG2;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F71x(dim: Integer; vdd: Integer);
var
  err: Integer;
  devID: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+5]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+6]<<8)+bufferI[z+7]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+6]<<8)+bufferI[z+7]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=8; 				}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  k := 0;
  z := 0;
  if sizeW<0x2007 then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if vdd = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(vdd, 20, 70));
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if vdd = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  if programID then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if vdd = 0 then
  begin
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  bufferU[Inc(j)] := $5;
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
  PacketIO(IfThen(vdd, 30, 130));
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG2;			 			buffer *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG2;
    bufferU[Inc(j)] := WAIT_T2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-11 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*2.5+2);
    w := 0;
    for z := 0 to (DIMBUF-7) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG2;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG2;
    bufferU[Inc(j)] := WAIT_T2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG2;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := END_PROG2;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if sizeW>0x2008 and memCODE_W[0x2008]<0x3fff then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG2;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := END_PROG2;
   bufferU[Inc(j)] := WAIT_T2;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(15);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F72x(dim: Integer; d: Integer; d2: Integer);
var
  err: Integer;
  devID: Word;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+3]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+4]<<8)+bufferI[z+5]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+4]<<8)+bufferI[z+5]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim; 							z=DIMBUF; 						} 					} 					k++; 					z+=6; 				}: Telse;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  k := 0;
  z := 0;
  if  not CheckV33Regulator() then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := CUST_CMD;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 6000 shr 8;
  bufferU[Inc(j)] := 6000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(3);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  if programID or ICDenable then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := BULK_ERASE_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := CUST_CMD;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2500 shr 8;
  bufferU[Inc(j)] := 2500&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(18);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0,j=0;i<dim;i++){ 		if(memCODE_W[i]<0x3fff){ 			bufferU[j++]=LOAD_DATA_PROG; 			bufferU[j++]=memCODE_W[i]>>8;		 			bufferU[j++]=memCODE_W[i]&0xff;		 			bufferU[j++]=BEGIN_PROG;			 			bufferU *)
  // init: w=i=k=0,j=0
  while i<dim do
  begin
   if memCODE_W[i]<0x3fff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-12 or i = dim-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*2.5+2);
    w := 0;
    for z := 0 to (DIMBUF-5) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0x3fff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  PrintStatusEnd();
  PrintMessage1(strings[S_ComplErr], err);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := 0x2800+(ICDaddr&0x7FF);
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 6000 shr 8;
  bufferU[Inc(j)] := 6000&0xff;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := INC_ADDR;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := 4;
  end;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0x2007] shr 8;
  bufferU[Inc(j)] := memCODE_W[0x2007]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  if sizeW>0x2008 then
  begin
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0x2008] shr 8;
   bufferU[Inc(j)] := memCODE_W[0x2008]&0xff;
   bufferU[Inc(j)] := BEGIN_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := READ_DATA_PROG;
   bufferU[Inc(j)] := FLUSH;
  end;
  PacketIO(45);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0,z=0;programID&&i<4;i++){ 		for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++); 		if (memCODE_W[0x2000+i]!=(bufferI[z+1]<<8)+bufferI[z+2]){ 			PrintMessage("\r\n"); 			PrintMessage3(strings[S_IDE *)
  // init: i=0,z=0
  while programID and i<4 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: 
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if memCODE_W[0x2000+i] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage3(strings[S_IDErr], i, memCODE_W[0x2000+i], (bufferI[z+1] shl 8)+bufferI[z+2]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  if ~memCODE_W[0x2007]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr3], memCODE_W[0x2007], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  PrintMessage1(strings[S_ComplErr], err_c);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F1xxx(dim: Integer; dim2: Integer; options: Integer);
var
  err: Integer;
  devID: Word;
  devREV: Word;
  calib1: Word;
  calib2: Word;
  calib3: Word;
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  F18x: Integer;
  start: Cardinal;
  calib: array[0..4-1] of Word;
  dly: Integer;
  valid: Integer;
  inc: Integer;
  if(bufferI[z]==READ_DATA_PROG){ 					if(memCODE_W[k]<0x3FFF&&(memCODE_W[k]!=(bufferI[z+1]<<8)+bufferI[z+2])){ 						PrintMessage3(strings[S_CodeWError2],k,memCODE_W[k],(bufferI[z+1]<<8)+bufferI[z+2]);	 						err++; 					} 					z+=2; 				}: Telse;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  devREV := $3fff;
  calib1 := $3fff;
  calib2 := $3fff;
  calib3 := $3fff;
  k := 0;
  k2 := 0;
  z := 0;
  F18x := options&16;
  if F18x and FWVersion<0xA00 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.10.0');
   Exit;
  end;
  if (options&2) = 0 then
  begin
   if  not StartHVReg(8.5) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-1);
  for i := 0 to (0x800C and i<sizeW) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  if (options&2) = 0 then
  begin
   if (options&1) = 0 then
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := LOAD_CONF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := INC_ADDR_N;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := INC_ADDR;
  if options&4 then
   bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2500 shr 8;
  bufferU[Inc(j)] := 2500&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  devREV := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  if devREV<0x3FFF then
   PrintMessage1(strings[S_DevREV], devREV);
  PIC16_ID(devID);
  if memCODE_W[0x8006]<0x3FFF and devID not =memCODE_W[0x8006] then
   PrintMessage(strings[S_DevMismatch]);
  if  not F18x then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: z+=3
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   calib1 := (bufferI[z+1] shl 8)+bufferI[z+2];
   if calib1<0x3fff then
    PrintMessage2(strings[S_CalibWordX], 1, calib1);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: z+=3
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   calib2 := (bufferI[z+1] shl 8)+bufferI[z+2];
   if calib2<0x3fff then
    PrintMessage2(strings[S_CalibWordX], 2, calib2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: z+=3
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   calib3 := (bufferI[z+1] shl 8)+bufferI[z+2];
   if calib3<0x3fff then
    PrintMessage2(strings[S_CalibWordX], 3, calib3);
  end
  else
  begin
   (* TODO gtk2laz: array initializer: calib[4]={0x3FFF,0x3FFF,0x3FFF,0x3FFF}; *)
   bufferU[Inc(j)] := LOAD_PC;
   bufferU[Inc(j)] := $E0;
   bufferU[Inc(j)] := $00;
   for i := 0 to (4) - 1 do
   begin
   end;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'Calibration area @0xE000' + LineEnding + '');
   end;
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  dly := 8;
  j := 0;
  if programID then
  begin
   bufferU[Inc(j)] := LOAD_CONF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end
  else if  not F18x then
  begin
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $16;
  end
  else
  begin
   bufferU[Inc(j)] := LOAD_PC;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
  end;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  if F18x then
  begin
   bufferU[Inc(j)] := LOAD_PC;
   bufferU[Inc(j)] := $F0;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := BULK_ERASE_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   dly := dly + 6;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(dly);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  fflush(logfile);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;dim>0&&memCODE_W[dim]>=0x3fff;dim--) *)
  // init: 
  while dim>0 and memCODE_W[dim]>=0x3fff do
  begin
   (* TODO gtk2laz: unrecognised statement: dim--; *)
  end;
  if  not F18x then
  begin
   if dim%8 then
    dim := dim + 8-dim%8;
   for i := k=0,j=0 to (dim) - 1 do
   begin
    valid := inc=0;
    (* TODO gtk2laz: complex for loop: for(;i<dim&&!valid;){	 			valid=0; 			for(k=0;k<8;k++) if(memCODE_W[i+k]<0x3fff) valid=1; 			if(!valid){ 				inc+=8; 				i+=8; 			} 			if(inc&&(valid||inc==248)){	 				bufferU[j++]=INC_ADDR_N; 				buf *)
    i := i + 8;
   end;
  end
  else
  begin
   if dim%32 then
    dim := dim + 32-dim%32;
   for i := k=0,j=0 to (dim) - 1 do
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;i<dim&&!valid;i+=valid?0:32){	 				valid=0; 				for(k=0;k<32;k++) if(memCODE_W[i+k]<0x3fff) valid=1; 			} 			bufferU[j++]=LOAD_PC *)
    // init: valid=0
    while i<dim and  not valid do
    begin
     valid := 0;
     for k := 0 to (32) - 1 do
     begin
     end;
     i := i + IfThen(valid, 0, 32);
    end;
    bufferU[Inc(j)] := i shr 8;
    bufferU[Inc(j)] := i&0xFF;
    for k := 0 to (32 and i<dim) - 1 do
    begin
     bufferU[Inc(j)] := IfThen(k<31, LOAD_DATA_INC, LOAD_DATA_PROG);
     bufferU[Inc(j)] := memCODE_W[i+k] shr 8;
     bufferU[Inc(j)] := memCODE_W[i+k]&0xff;
     if j>DIMBUF-4 then
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
     end;
    end;
    i := i + 32;
   end;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_CodeV]);
  j := 0;
  if  not F18x then
  begin
   bufferU[Inc(j)] := CUST_CMD;
   bufferU[Inc(j)] := $16;
  end
  else
  begin
   bufferU[Inc(j)] := LOAD_PC;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  for i := k=0 to (dim) - 1 do
  begin
   if j = 0 then
   begin
    (* TODO gtk2laz: complex for loop: for(valid=0;i<dim&&!valid;){ 				for(k2=0;k2<255&&!valid;k2++) if(memCODE_W[i+k2]<0x3fff) valid=1; 				if(k2>16){			 					bufferU[j++]=INC_ADDR_N; 					bufferU[j++]=k2; 					i+=k2; 					k+=k2; 				} 	 *)
   end;
   bufferU[Inc(j)] := INC_ADDR;
   if j>DIMBUF*2/4-3 or i = dim-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = INC_ADDR then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
  end;
  if k<dim then
  begin
   PrintMessage2(strings[S_CodeVError3], dim, k);
  end;
  if err>=max_err then
  begin
   PrintMessage1(strings[S_MaxErr], err);
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write16F18xxx(dim: Integer; dim2: Integer; options: Integer);
var
  err: Integer;
  devID: Word;
  devREV: Word;
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  useDCI: Integer;
  bulkEraseField: Integer;
  reboot: Integer;
  rowN: Integer;
  start: Cardinal;
  DIA: array[0..0x20-1] of Word;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  DCI: array[0..0x20-1] of Word;
  valid: Integer;
  errEE: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  devREV := $3fff;
  k := 0;
  k2 := 0;
  z := 0;
  useDCI := IfThen((options&0x10) = 0, 1, 0);
  bulkEraseField := IfThen((options&0x20), 1, 0);
  reboot := IfThen((options&0x40), 1, 0);
  rowN := 32;
  if FWVersion<0xB00 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.11.0');
   Exit;
  end;
  if dim2>0x1000 then
   dim2 := $100;
  if (options&2) = 0 then
  begin
   if  not StartHVReg(8.5) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-1);
  for i := 0 to (0x800C and i<sizeW) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  if (options&2) = 0 then
  begin
   if (options&1) = 0 then
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := ICSP8_LOAD;
  bufferU[Inc(j)] := LOAD_PC_ADDR;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := ICSP8_READ;
  bufferU[Inc(j)] := READ_NVM_INC;
  bufferU[Inc(j)] := ICSP8_READ;
  bufferU[Inc(j)] := READ_NVM_INC;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  if  not bulkEraseField then
  begin
   bufferU[Inc(j)] := 2800 shr 8;
   bufferU[Inc(j)] := 2800&0xff;
  end
  else
  begin
   bufferU[Inc(j)] := 7000 shr 8;
   bufferU[Inc(j)] := 7000&0xff;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  for z := 0 to (DIMBUF-2 and bufferI[z] not =ICSP8_READ) - 1 do
  begin
  end;
  devREV := (bufferI[z+1] shl 8)+bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=ICSP8_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =ICSP8_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  PrintMessage1(strings[S_DevID], devID);
  if devREV<0x3FFF then
   PrintMessage1(strings[S_DevREV], devREV);
  PIC16_ID(devID);
  if memCODE_W[0x8006]<0x3FFF and devID not =memCODE_W[0x8006] then
   PrintMessage(strings[S_DevMismatch]);
  if useDCI then
  begin
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, 'Device Information Area @0x8100' + LineEnding + '');
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := $00;
   k := 0;
   for i := 0 to ($20) - 1 do
   begin
    bufferU[Inc(j)] := ICSP8_READ;
    bufferU[Inc(j)] := READ_NVM_INC;
    if (j+1)/2*3+3>DIMBUF or i = 0x1F then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(5);
     for z := 0 to (DIMBUF-2) - 1 do
     begin
      if bufferI[z] = ICSP8_READ then
      begin
       DIA[Inc(k)] := (bufferI[z+1] shl 8)+bufferI[z+2];
       z := z + 2;
      end;
     end;
    end;
   end;
   s[0] := 0;
   for i := 0 to ($20) - 1 do
   begin
    sprintf(t, '%04X: ', 0x8100+i);
    strcat(s, t);
    for j := i to (i+COL and j<0x20) - 1 do
    begin
     sprintf(t, '%04X ', DIA[j]);
     strcat(s, t);
    end;
    i := i + COL;
   end;
   if saveLog then
    fprintf(logfile, 'Device Configuration Information @0x8200' + LineEnding + '');
   j := 0;
   k := 0;
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := $82;
   bufferU[Inc(j)] := $00;
   for i := 0 to ($20) - 1 do
   begin
    bufferU[Inc(j)] := ICSP8_READ;
    bufferU[Inc(j)] := READ_NVM_INC;
    if (j+1)/2*3+3>DIMBUF or i = 0x1F then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(5);
     for z := 0 to (DIMBUF-2) - 1 do
     begin
      if bufferI[z] = ICSP8_READ then
      begin
       DCI[Inc(k)] := (bufferI[z+1] shl 8)+bufferI[z+2];
       z := z + 2;
      end;
     end;
    end;
   end;
   s[0] := 0;
   for i := 0 to ($20) - 1 do
   begin
    sprintf(t, '%04X: ', 0x8200+i);
    strcat(s, t);
    for j := i to (i+COL and j<0x20) - 1 do
    begin
     sprintf(t, '%04X ', DCI[j]);
     strcat(s, t);
    end;
    i := i + COL;
   end;
   PrintMessage1('Erase row size: %d words\r' + LineEnding + '', DCI[0]);
   PrintMessage1('Write latches: %d\r' + LineEnding + '', DCI[1]);
   PrintMessage1('User rows: %d\r' + LineEnding + '', DCI[2]);
   PrintMessage1('->%d Flash words\r' + LineEnding + '', DCI[0]*DCI[2]);
   PrintMessage1('EE data memory size: %d\r' + LineEnding + '', DCI[3]);
   PrintMessage1('Pin count: %d\r' + LineEnding + '', DCI[4]);
   if DCI[0]*DCI[2] not =dim then
    PrintMessage(strings[S_WarnFlashSize]);
   if dim2>DCI[3] then
    dim2 := DCI[3];
  end;
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  if  not bulkEraseField then
  begin
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   if programID then
   begin
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $00;
   end
   else
   begin
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $00;
   end;
   bufferU[Inc(j)] := BULK_ERASE_PROGRAM_MEM;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   if dim2 then
   begin
    bufferU[Inc(j)] := ICSP8_LOAD;
    bufferU[Inc(j)] := LOAD_PC_ADDR;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := ICSP8_SHORT;
    bufferU[Inc(j)] := BULK_ERASE_PROGRAM_MEM;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := BULK_ERASE_PROGRAM_MEM;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := IfThen(programID, $0F, $0B);
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := WAIT_T3;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(30);
  PrintMessage(strings[S_Compl]);
  if reboot then
  begin
   j := 0;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := SET_CK_D;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := 4;
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
  end;
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  fflush(logfile);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;dim>0&&memCODE_W[dim-1]>=0x3fff;dim--) *)
  // init: 
  while dim>0 and memCODE_W[dim-1]>=0x3fff do
  begin
   (* TODO gtk2laz: unrecognised statement: dim--; *)
  end;
  if dim%rowN then
   dim := dim + rowN-dim%rowN;
  for i := k=0,j=0 to (dim) - 1 do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;i<dim&&!valid;i+=valid?0:rowN){	 			valid=0; 			for(k=0;k<rowN;k++) if(memCODE_W[i+k]<0x3fff) valid=1; 		} 		bufferU[j++]=ICSP8_LOAD *)
   // init: valid=0
   while i<dim and  not valid do
   begin
    valid := 0;
    for k := 0 to (rowN) - 1 do
    begin
    end;
    i := i + IfThen(valid, 0, rowN);
   end;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := i shr 8;
   bufferU[Inc(j)] := i&0xFF;
   for k := 0 to (rowN and i<dim) - 1 do
   begin
    bufferU[Inc(j)] := ICSP8_LOAD;
    bufferU[Inc(j)] := IfThen(k<(rowN-1), LOAD_NVM_INC, LOAD_NVM);
    bufferU[Inc(j)] := memCODE_W[i+k] shr 8;
    bufferU[Inc(j)] := memCODE_W[i+k]&0xff;
    if j>DIMBUF-5 then
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
    end;
   end;
   i := i + rowN;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_CodeV]);
  j := 0;
  bufferU[Inc(j)] := ICSP8_LOAD;
  bufferU[Inc(j)] := LOAD_PC_ADDR;
  bufferU[Inc(j)] := $00;
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
  for i := k=0 to (dim) - 1 do
  begin
   if j = 0 then
   begin
    for k2 := i to (dim and memCODE_W[k2]>=0x3fff) - 1 do
    begin
    end;
    if k2>i+10 then
    begin
     i := k2;
     k := i;
     bufferU[Inc(j)] := ICSP8_LOAD;
     bufferU[Inc(j)] := LOAD_PC_ADDR;
     bufferU[Inc(j)] := (i shr 8)&0xFF;
     bufferU[Inc(j)] := i&0xFF;
    end;
   end;
   bufferU[Inc(j)] := READ_NVM_INC;
   if (j+1)/2*3+3>DIMBUF or i = dim-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = ICSP8_READ then
     begin
      if memCODE_W[k] not =(bufferI[z+1] shl 8)+bufferI[z+2] then
      begin
       PrintMessage3(strings[S_CodeWError2], k, memCODE_W[k], (bufferI[z+1] shl 8)+bufferI[z+2]);
       (* TODO gtk2laz: unrecognised statement: err++ *)
      end;
      (* TODO gtk2laz: unrecognised statement: k++ *)
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if err>=max_err then
  begin
   PrintMessage1(strings[S_MaxErr], err);
  end
  else if dim2 and err<max_err then
  begin
   errEE := 0;
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := SET_PARAMETER;
   bufferU[Inc(j)] := SET_T3;
   bufferU[Inc(j)] := 5600 shr 8;
   bufferU[Inc(j)] := 5600&0xff;
   bufferU[Inc(j)] := ICSP8_LOAD;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := $F0;
   bufferU[Inc(j)] := $00;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=i=k=0;i<dim2;i++){ 			if(memEE[i]<0xff){ 				bufferU[j++]=ICSP8_LOAD; 				bufferU[j++]=LOAD_NVM; 				bufferU[j++]=0;  		 				bufferU[j++]=memEE[i]&0xff;		 				bufferU[j++]=ICSP8_SHORT; 				buffe *)
   // init: w=i=k=0
   while i<dim2 do
   begin
    if memEE[i]<0xff then
    begin
     bufferU[Inc(j)] := ICSP8_LOAD;
     bufferU[Inc(j)] := LOAD_NVM;
     bufferU[Inc(j)] := 0;
     bufferU[Inc(j)] := memEE[i]&0xff;
     bufferU[Inc(j)] := ICSP8_SHORT;
     bufferU[Inc(j)] := BEGIN_INT_PROG;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := ICSP8_READ;
     bufferU[Inc(j)] := READ_NVM_INC;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end
    else
    begin
     bufferU[Inc(j)] := ICSP8_SHORT;
     bufferU[Inc(j)] := INC_ADDR8;
    end;
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], errEE);
   if max_err and err+errEE>max_err then
   begin
    PrintMessage1(strings[S_MaxErr], err+errEE);
   end;
  end;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

end.

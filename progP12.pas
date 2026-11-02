unit progp12;

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

// --- function declarations ---
procedure Read12F5xx(dim: Integer; dim2: Integer);
procedure Write12F5xx(dim: Integer; OscAddr: Integer);
procedure Write12C5xx(dim: Integer; dummy: Integer);

implementation

procedure Read12F5xx(dim: Integer; dim2: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  PrintMessage(strings[S_WDTOFF]): Telse;
  PrintMessage(strings[S_CPON]): Telse;
  PrintMessage(strings[S_MCLROFF]): Telse;
  stop: Cardinal;
  valid: Integer;
  empty: Integer;
  aux: PChar;
  PrintMessage(aux): Telse;
  PrintMessage(aux): Telse;
begin
  k := 0;
  z := 0;
  if dim2<4 then
   dim2 := 4;
  sizeW := $1000;
  if memCODE_W then
   FreeMem(memCODE_W);
  memCODE_W := malloc(sizeof(WORD)*sizeW);
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read12F5xx(%d,%d)' + LineEnding + '', dim, dim2);
  end;
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
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  if z<DIMBUF-2 then
  begin
   memCODE_W[0xfff] := (bufferI[z+1] shl 8)+bufferI[z+2];
   PrintMessage('\r' + LineEnding + '');
   PrintMessage1(strings[S_ConfigWord], memCODE_W[0xfff]);
   case memCODE_W[0xfff]&0x03 of
    0:
    begin
     PrintMessage(strings[S_LPOsc]);
    end;
    1:
    begin
     PrintMessage(strings[S_XTOsc]);
    end;
    2:
    begin
     PrintMessage(strings[S_IntOsc]);
    end;
    3:
    begin
     PrintMessage(strings[S_RCOsc]);
    end;
   end;
   if memCODE_W[0xfff]&0x08 then
    PrintMessage(strings[S_CPOFF]);
   if memCODE_W[0xfff]&0x10 then
    PrintMessage(strings[S_MCLRON]);
  end
  else
   PrintMessage(strings[S_NoConfigW]);
  PrintMessage(strings[S_CodeReading1]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim+dim2) - 1 do
  begin
   bufferU[Inc(j)] := READ_DATA_PROG;
   bufferU[Inc(j)] := INC_ADDR;
   if j>DIMBUF*2/4-3 or i = dim+dim2-1 then
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
  PacketIO(1);
  stop := GetTickCount();
  for i := k to ($fff) - 1 do
  begin
  end;
  if k not =dim+dim2 then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadErr], dim+dim2, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  for i := 0 to (4) - 1 do
  begin
   PrintMessage4(strings[S_ChipID], i, memCODE_W[dim+i], i+1, memCODE_W[dim+i+1]);
   i := i + 2;
  end;
  s[0] := 0;
  valid := 0;
  empty := 1;
  aux := malloc((dim/COL+1)*(16+COL*5));
  aux[0] := 0;
  for i := 0 to (dim) - 1 do
  begin
   valid := 0;
   for j := i to (i+COL and j<dim) - 1 do
   begin
    sprintf(t, '%03X ', memCODE_W[j]);
    strcat(s, t);
    if memCODE_W[j]<0xfff then
     valid := 1;
   end;
   i := i + COL;
  end;
  FreeMem(aux);
  if dim2>5 then
  begin
   aux := malloc((dim2/COL+1)*(16+COL*5));
   aux[0] := 0;
   s[0] := 0;
   PrintMessage(strings[S_ConfigResMem]);
   empty := 1;
   for i := dim to (dim+dim2) - 1 do
   begin
    valid := 0;
    for j := i to (i+COL and j<dim+64) - 1 do
    begin
     sprintf(t, '%03X ', memCODE_W[j]);
     strcat(s, t);
     if memCODE_W[j]<0xfff then
      valid := 1;
    end;
    i := i + COL;
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

procedure Write12F5xx(dim: Integer; OscAddr: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  err: Integer;
  osccal: Word;
  BKosccal: Word;
  start: Cardinal;
  dim1: Integer;
  if(use_osccal) memCODE_W[OscAddr]=osccal: Telse;
  if(bufferI[z]==LOAD_DATA_PROG&&bufferI[z+5]==READ_DATA_PROG){ 					if (memCODE_W[k]!=(bufferI[z+6]<<8)+bufferI[z+7]){ 						PrintMessage("\r\n"); 						PrintMessage3(strings[S_CodeWError],k,memCODE_W[k],(bufferI[z+6]<<8)+bufferI[z+7]);	 						err++; 						if(max_err&&err>max_err){ 							PrintMessage1(strings[S_MaxErr],err);	 							PrintMessage(strings[S_IntW]);	 							i=dim1; 							z=DIMBUF; 						} 					} 					k++; 					z+=8; 				}: Telse;
  err_c: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  osccal := -1;
  BKosccal := -1;
  if OscAddr>dim then
   OscAddr := dim-1;
  if OscAddr = -1 then
   use_BKosccal := use_osccal=0;
  if sizeW<0x1000 then
  begin
   PrintMessage(strings[S_NoConfigW2]);
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
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  if OscAddr not =-1 then
  begin
   for i := -1 to (OscAddr-0xff) - 1 do
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := $ff;
    i := i + $ff;
   end;
   bufferU[Inc(j)] := OscAddr-i;
   bufferU[Inc(j)] := READ_DATA_PROG;
   if OscAddr<dim then
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := dim-OscAddr;
   end;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := READ_DATA_PROG;
  end;
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
  if OscAddr not =-1 then
  begin
   for z := 4 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
   begin
   end;
   if z<DIMBUF-2 then
    osccal := (bufferI[z+1] shl 8)+bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=READ_DATA_PROG;z++) *)
   // init: z+=3
   while z<DIMBUF-2 and bufferI[z] not =READ_DATA_PROG do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-2 then
    BKosccal := (bufferI[z+1] shl 8)+bufferI[z+2];
   if osccal = -1 or BKosccal = -1 then
   begin
    PrintMessage(strings[S_ErrOsccal]);
    PrintMessage('\r' + LineEnding + '');
    Exit;
   end;
   PrintMessage1(strings[S_BKOsccal], BKosccal);
  end;
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  if dim>OscAddr+1 then
  begin
   bufferU[Inc(j)] := BULK_ERASE_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   for i := -1 to (dim-0xff) - 1 do
   begin
    bufferU[Inc(j)] := INC_ADDR_N;
    bufferU[Inc(j)] := $ff;
    i := i + $ff;
   end;
   bufferU[Inc(j)] := dim-i-1;
   bufferU[Inc(j)] := BULK_ERASE_PROG;
   bufferU[Inc(j)] := WAIT_T3;
   if programID then
   begin
    bufferU[Inc(j)] := INC_ADDR;
    bufferU[Inc(j)] := BULK_ERASE_PROG;
    bufferU[Inc(j)] := WAIT_T3;
   end;
  end
  else
  begin
   if programID then
   begin
    for i := -1 to (dim-0xff) - 1 do
    begin
     bufferU[Inc(j)] := INC_ADDR_N;
     bufferU[Inc(j)] := $ff;
     i := i + $ff;
    end;
    bufferU[Inc(j)] := dim-i;
    bufferU[Inc(j)] := BULK_ERASE_PROG;
    bufferU[Inc(j)] := WAIT_T3;
   end
   else
   begin
    bufferU[Inc(j)] := BULK_ERASE_PROG;
    bufferU[Inc(j)] := WAIT_T3;
   end;
  end;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := INC_ADDR;
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
  PacketIO(IfThen((dim>OscAddr+1), 50, 30));
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  dim1 := dim;
  if programID then
   dim1 := dim+5;
  if memCODE_W[dim+4]>=0xFFF then
   memCODE_W[dim+4] := BKosccal;
  if use_BKosccal then
   memCODE_W[OscAddr] := BKosccal;
  for i := k=w=0,j=0 to (dim1) - 1 do
  begin
   if memCODE_W[i]<0xfff then
   begin
    bufferU[Inc(j)] := LOAD_DATA_PROG;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := END_PROG2;
    bufferU[Inc(j)] := WAIT_T2;
    bufferU[Inc(j)] := READ_DATA_PROG;
    (* TODO gtk2laz: unrecognised statement: w++ *)
   end;
   if j>DIMBUF-10 or i = dim1-1 then
   begin
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(w*3+3);
    w := 0;
    for z := 0 to (DIMBUF-7) - 1 do
    begin
     if bufferI[z] = INC_ADDR and memCODE_W[k]>=0xfff then
      (* TODO gtk2laz: unrecognised statement: k++ *)
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
  end;
  err := err + i-k;
  PrintMessage1(strings[S_ComplErr], err);
  PrintMessage(strings[S_ConfigW]);
  err_c := 0;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := LOAD_DATA_PROG;
  bufferU[Inc(j)] := memCODE_W[0xfff] shr 8;
  bufferU[Inc(j)] := memCODE_W[0xfff]&0xff;
  bufferU[Inc(j)] := BEGIN_PROG;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := END_PROG2;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := READ_DATA_PROG;
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
  PacketIO(20);
  stop := GetTickCount();
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  if ~memCODE_W[0xfff]&((bufferI[z+1] shl 8)+bufferI[z+2]) then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ConfigWErr], memCODE_W[0xfff], (bufferI[z+1] shl 8)+bufferI[z+2]);
   (* TODO gtk2laz: unrecognised statement: err_c++ *)
  end;
  if z>DIMBUF-2 then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage(strings[S_ConfigWErr2]);
  end;
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log8], i, i, k, k, err);
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write12C5xx(dim: Integer; dummy: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  osccal: Word;
  OscAddr: Integer;
  start: Cardinal;
  N: Integer;
  Nt: Integer;
  Nmin: Integer;
  Nmax: Integer;
  xN: Integer;
  dim1: Integer;
  err_c: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  osccal := -1;
  OscAddr := dim-1;
  if FWVersion<0x800 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.8.0');
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_MN;
  bufferU[Inc(j)] := 8;
  bufferU[Inc(j)] := 11;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  for i := -1 to (OscAddr-0xff) - 1 do
  begin
   bufferU[Inc(j)] := INC_ADDR_N;
   bufferU[Inc(j)] := $ff;
   i := i + $ff;
  end;
  bufferU[Inc(j)] := OscAddr-i;
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
  j := 0;
  for z := 4 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  if z<DIMBUF-2 then
   osccal := (bufferI[z+1] shl 8)+bufferI[z+2];
  if osccal = -1 then
  begin
   PrintMessage(strings[S_ErrOsccal]);
   PrintMessage('\r' + LineEnding + '');
   Exit;
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := READ_ADC;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  Nt := 0;
  Nmin := 255;
  Nmax := 0;
  xN := 0;
  dim1 := dim;
  if programID then
   dim1 := dim+5;
  if use_osccal then
   memCODE_W[OscAddr] := osccal;
  for i := k=0,j=0 to (dim1) - 1 do
  begin
   if memCODE_W[i]<0xfff then
   begin
    bufferU[Inc(j)] := PROG_C;
    bufferU[Inc(j)] := memCODE_W[i] shr 8;
    bufferU[Inc(j)] := memCODE_W[i]&0xff;
    bufferU[Inc(j)] := READ_DATA_PROG;
    bufferU[Inc(j)] := READ_ADC;
    bufferU[Inc(j)] := INC_ADDR;
   end
   else
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;memCODE_W[i]>=0xfff&&j<DIMBUF-1&&i<dim1;i++) bufferU[j++]=INC_ADDR *)
    // init: 
    while memCODE_W[i]>=0xfff and j<DIMBUF-1 and i<dim1 do
    begin
     (* TODO gtk2laz: unrecognised statement: i++; *)
    end;
    (* TODO gtk2laz: unrecognised statement: i-- *)
   end;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(10+3);
   j := 0;
   if bufferI[1] = PROG_C and bufferI[3] = READ_DATA_PROG then
   begin
    N := bufferI[2];
    if N<0xF0 then
    begin
     Nt := Nt + N;
     (* TODO gtk2laz: unrecognised statement: xN++ *)
     if N<Nmin then
      Nmin := N;
     if N>Nmax then
      Nmax := N;
    end;
   end
   else
    (* TODO gtk2laz: complex for loop: for(z=0 *)
  end;
  err := err + i-k;
  PrintMessage1(strings[S_ComplErr], err);
  if saveLog  and  xN then
   fprintf(logfile, "Programming pulses: avg %.1f, min %d, max %d\r\n", Nt/xN, Nmin, Nmax);
  if memCODE_W[0xfff]<0xfff then
  begin
   PrintMessage(strings[S_ConfigW]);
   err_c := 0;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := LOAD_DATA_PROG;
   bufferU[Inc(j)] := memCODE_W[0xfff] shr 8;
   bufferU[Inc(j)] := memCODE_W[0xfff]&0xff;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(12);
   j := 0;
   for i := 0 to (20) - 1 do
   begin
    bufferU[Inc(j)] := BEGIN_PROG;
    bufferU[Inc(j)] := WAIT_T2;
    bufferU[Inc(j)] := END_PROG2;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   j := 0;
   for i := 0 to (5) - 1 do
   begin
    PacketIO(3);
   end;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   j := 0;
   if ~memCODE_W[0xfff]&((bufferI[2] shl 8)+bufferI[3]) then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage2(strings[S_ConfigWErr], memCODE_W[0xfff], (bufferI[2] shl 8)+bufferI[3]);
    (* TODO gtk2laz: unrecognised statement: err_c++ *)
   end;
  end;
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
  j := 0;
  stop := GetTickCount();
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log8], i, i, k, k, err);
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

end.

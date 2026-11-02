unit progavr;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

const
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

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
  din: Integer;

// --- function declarations ---
procedure AtmelID(id: Byte);
procedure WriteATfuseSlow(fuse: Integer);
function SyncSPI: Double;
procedure ReadAT(dim: Integer; dim2: Integer; options: Integer);
procedure ReadAT_HV(dim: Integer; dim2: Integer; options: Integer);
procedure WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer);
procedure WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer);
procedure WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer);

implementation

procedure AtmelID(id: Byte);
var
  str: array[0..128-1] of Char;
  i: Integer;
  idw: Integer;
  strcat(str,"\r\n"): Telse;
begin
  (* TODO gtk2laz: array initializer: str[128]=""; *)
  idw := (id[1] shl 8)+id[2];
  if id[0] = 0 and id[1] = 1 and id[2] = 2 then
  begin
   PrintMessage(strings[S_Protected]);
   Exit;
  end;
  for i := 0 to (sizeof(AVRLIST)/sizeof(AVRLIST[0])) - 1 do
  begin
   if idw = AVRLIST[i].id then
   begin
    strcat(str, AVRLIST[i].device);
    i := 1000;
   end;
  end;
  PrintMessage(str);
end;

procedure WriteATfuseSlow(fuse: Integer);
var
  j: Integer;
  d: Integer;
begin
  fuse := fuse and $FF;
  if FWVersion<0x900 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.9.0');
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $F5;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := CLOCK_GEN;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  msDelay(20);
  SWSPI($AC, SPEED);
  SWSPI($53, SPEED);
  d := SWSPI(0, SPEED);
  SWSPI(0, SPEED);
  if d not =0x53 then
  begin
   j := 0;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   PrintMessage(strings[S_SyncErr]);
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  SWSPI($A0, SPEED);
  SWSPI($00, SPEED);
  SWSPI(fuse, SPEED);
  msDelay(9);
  SWSPI($50, SPEED);
  SWSPI($00, SPEED);
  SWSPI($00, SPEED);
  d := SWSPI(0, SPEED);
  if d not =fuse then
  begin
   PrintMessage3(strings[S_WErr1], 'fuse', fuse, d);
  end;
  bufferU[Inc(j)] := CLOCK_GEN;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  PrintMessage(strings[S_Compl]);
end;

function SyncSPI: Double;
var
  z: Integer;
  i: Integer;
  j: Integer;
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
  (* TODO gtk2laz: do-while without while: double Tbyte *)
  j := 0;
  bufferU[Inc(j)] := SPI_INIT;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(2);
  for i := 1 to (256) - 1 do
  begin
   if i>10 then
    (* TODO gtk2laz: unrecognised statement: i++ *)
   if i>20 then
    i := i + 2;
   if i>40 then
    i := i + 4;
   if i>80 then
    i := i + 4;
   if i>160 then
    i := i + 8;
   Tbyte := (20+i*4)/1000.0;
   j := 0;
   bufferU[Inc(j)] := CLOCK_GEN;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := SET_PARAMETER;
   bufferU[Inc(j)] := SET_T1T2;
   bufferU[Inc(j)] := i;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := RST;
   bufferU[Inc(j)] := WAIT_T3;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := CLOCK_GEN;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   // return value of PacketIO() ignored
   PacketIO(9);
   // return value of msDelay() ignored
   msDelay(20);
   j := 0;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $53;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 11;
   bufferU[Inc(j)] := $55;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $AA;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $55;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $AA;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $53;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   // return value of PacketIO() ignored
   PacketIO(1.5+32*Tbyte*1.1);
   for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
   begin
   end;
   d0 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d1 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d2 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d3 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d4 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d5 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d6 := bufferI[z+2];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=bufferI[z+1]+1;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=bufferI[z+1]+1
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   d7 := bufferI[z+2];
   if d0 = 0x53 and d6 = 0x53 and d1 = d2 and d1 = d3 and d1 = d4 and d1 = d5 and d1 = d7 then
    (* TODO gtk2laz: unrecognised statement: break *)
  end;
  i := i + i/10;
  if i>255 then
   i := 255;
  Tbyte := (20+i*4)/1000.0;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := i;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  // return value of PacketIO() ignored
  PacketIO(2);
  // return value of sprintf() ignored
  sprintf(str, strings_it[I_AT_COMM], 8/Tbyte);
  // return value of PrintMessage() ignored
  PrintMessage(str);
  if saveLog then
   // return value of fprintf() ignored
   fprintf(logfile, str);
  Exit(Tbyte);
end;

procedure ReadAT(dim: Integer; dim2: Integer; options: Integer);
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  signature: array of Byte;
  start: Cardinal;
  c: Integer;
  n: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  (* TODO gtk2laz: do-while without while: double Tbyte *)
  (* TODO gtk2laz: array initializer: signature[]={0,0,0}; *)
  if dim>0x20000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  sizeEE := dim2;
  if memCODE then
   FreeMem(memCODE);
  memCODE := malloc(dim);
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim2);
  for j := 0 to (size) - 1 do
  begin
  end;
  for j := 0 to (sizeEE) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := VREG_DIS;
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
  Tbyte := SyncSPI();
  if Tbyte = 0 then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  if options&LOCK then
  begin
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1.5+7*4.5*Tbyte);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
  begin
  end;
  signature[0] := bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[1] := bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[2] := bufferI[z+2];
  PrintMessage3('CHIP ID:%02X%02X%02X\r' + LineEnding + '', signature[0], signature[1], signature[2]);
  AtmelID(signature);
  if options&LOCK then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
   // init: z+=3
   while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   PrintMessage1('LOCK bits:' + #9 + '  0x%02X\r' + LineEnding + '', bufferI[z+2]);
  end;
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_CodeReading1]);
  PrintStatusSetup();
  c := (DIMBUF-5)/2;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := AT_READ_DATA;
   bufferU[Inc(j)] := IfThen(i<(dim-2*c), c, (dim-i)/2);
   bufferU[Inc(j)] := i shr 9;
   bufferU[Inc(j)] := i shr 1;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(1.5+240*Tbyte);
   if bufferI[0] = AT_READ_DATA then
   begin
    for z := 2 to (bufferI[1]*2+2 and z<DIMBUF) - 1 do
    begin
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   i := i + c*2;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadCodeErr2], dim, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  if dim2 then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_ReadEE]);
   PrintStatusSetup();
   n := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(k2=0,i=0,j=0;i<dim2;i++){ 			bufferU[j++]=SPI_WRITE;		 			bufferU[j++]=3; 			bufferU[j++]=0xA0; 			bufferU[j++]=i>>8; 			bufferU[j++]=i; 			bufferU[j++]=SPI_READ; 			bufferU[j++]=1; 			n++; 			if( *)
   // init: k2=0,i=0,j=0
   while i<dim2 do
   begin
    bufferU[Inc(j)] := SPI_WRITE;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := i shr 8;
    bufferU[Inc(j)] := i;
    bufferU[Inc(j)] := SPI_READ;
    bufferU[Inc(j)] := 1;
    (* TODO gtk2laz: unrecognised statement: n++ *)
    if j>DIMBUF-9 or i = dim-1 then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(1.5+4*n*Tbyte*1.3);
     for z := 0 to (DIMBUF-2) - 1 do
     begin
      if bufferI[z] = SPI_READ and bufferI[z+1] = 1 then
      begin
       memEE[Inc(k2)] := bufferI[z+2];
       z := z + 3;
      end;
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
    (* TODO gtk2laz: unrecognised statement: i++; *)
   end;
   if k2 not =dim2 then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage2(strings[S_ReadEEErr], dim2, k2);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 0;
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
  PrintMessage(strings[S_CodeMem]);
  DisplayCODEAVR(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure ReadAT_HV(dim: Integer; dim2: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  signature: array of Byte;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  (* TODO gtk2laz: array initializer: signature[]={0,0,0}; *)
  if FWVersion<0x900 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.9.0');
   Exit;
  end;
  sizeEE := dim2;
  if memCODE then
   FreeMem(memCODE);
  memCODE := malloc(dim);
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim2);
  for j := 0 to (size) - 1 do
  begin
  end;
  for j := 0 to (sizeEE) - 1 do
  begin
  end;
  if  not StartHVReg(12) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $FC;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  if options&LOCK then
  begin
   bufferU[Inc(j)] := AT_HV_RTX;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7C;
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
  for z := 0 to (DIMBUF-1 and bufferI[z] not =AT_HV_RTX) - 1 do
  begin
  end;
  signature[0] := bufferI[z+1];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=2;z<DIMBUF-1&&bufferI[z]!=AT_HV_RTX;z++) *)
  // init: z+=2
  while z<DIMBUF-1 and bufferI[z] not =AT_HV_RTX do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[1] := bufferI[z+1];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=2;z<DIMBUF-1&&bufferI[z]!=AT_HV_RTX;z++) *)
  // init: z+=2
  while z<DIMBUF-1 and bufferI[z] not =AT_HV_RTX do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[2] := bufferI[z+1];
  PrintMessage3('CHIP ID:%02X%02X%02X\r' + LineEnding + '', signature[0], signature[1], signature[2]);
  AtmelID(signature);
  if options&LOCK then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=2;z<DIMBUF-1&&bufferI[z]!=AT_HV_RTX;z++) *)
   // init: z+=2
   while z<DIMBUF-1 and bufferI[z] not =AT_HV_RTX do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   PrintMessage1('LOCK byte:' + #9 + '  0x%02X\r' + LineEnding + '', bufferI[z+1]);
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  j := 0;
  PacketIO(2);
  z := 0;
  if options&FUSE_X then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;z<DIMBUF-1&&bufferI[z]!=AT_HV_RTX;z++) *)
   // init: 
   while z<DIMBUF-1 and bufferI[z] not =AT_HV_RTX do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   PrintMessage1('Extended FUSE byte: 0x%02X\r' + LineEnding + '', bufferI[z+1]);
   z := z + 2;
  end;
  PrintMessage(strings[S_CodeReading1]);
  PrintStatusSetup();
  j := 0;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: complex for loop: for(i=0;i<dim;){ 		if((i&511)==0){  			bufferU[j++]=AT_HV_RTX; 			bufferU[j++]=1; 			bufferU[j++]=0x1C; 			bufferU[j++]=i>>9; 			bufferU[j++]=FLUSH; 			for(;j<DIMBUF;j++) bufferU[j]=0x0; 			PacketIO(2 *)
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadCodeErr], dim, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  if dim2 then
  begin
   if saveLog then
    fprintf(logfile, 'READ EEPROM' + LineEnding + '');
   PrintMessage(strings[S_ReadEE]);
   PrintStatusSetup();
   j := 0;
   k := 0;
   bufferU[Inc(j)] := AT_HV_RTX;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if (i&255) = 0 then
    begin
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(2);
     j := 0;
    end;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := $0C;
    bufferU[Inc(j)] := i&0xFF;
    bufferU[Inc(j)] := $68;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $6C;
    bufferU[Inc(j)] := $00;
    if j>DIMBUF-8 or i>=dim2-2 then
    begin
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(2);
     for z := 0 to (DIMBUF-1) - 1 do
     begin
      if bufferI[z] = AT_HV_RTX then
      begin
       memEE[Inc(k)] := bufferI[z+1];
       z := z + 1;
      end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
    end;
   end;
   if k not =dim2 then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage2(strings[S_ReadEEErr], dim2, k);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 0;
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
  PrintMessage(strings[S_CodeMem]);
  DisplayCODEAVR(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  signature: array of Byte;
  errEE: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  (* TODO gtk2laz: do-while without while: double Tbyte *)
  (* TODO gtk2laz: array initializer: signature[]={0,0,0}; *)
  if dim>0x8000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if dim2>sizeEE then
   dim2 := sizeEE;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := VREG_DIS;
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
  Tbyte := SyncSPI();
  if Tbyte = 0 then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1+3*4*Tbyte);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
  begin
  end;
  signature[0] := bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[1] := bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[2] := bufferI[z+2];
  PrintMessage3('CHIP ID:%02X%02X%02X\r' + LineEnding + '', signature[0], signature[1], signature[2]);
  AtmelID(signature);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
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
  PacketIO(1+4*Tbyte);
  msDelay(25);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   if memCODE[i] not =0xFF then
   begin
    bufferU[Inc(j)] := SPI_WRITE;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := IfThen(0x40+(i&1, 8, 0));
    bufferU[Inc(j)] := i shr 9;
    bufferU[Inc(j)] := i shr 1;
    bufferU[Inc(j)] := memCODE[i];
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := SPI_WRITE;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := IfThen(0x20+(i&1, 8, 0));
    bufferU[Inc(j)] := i shr 9;
    bufferU[Inc(j)] := i shr 1;
    bufferU[Inc(j)] := SPI_READ;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    j := 0;
    PacketIO(7+2*4*Tbyte);
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
    begin
    end;
    if z = DIMBUF-2 or memCODE[i] not =bufferI[z+2] then
    begin
     (* TODO gtk2laz: unrecognised statement: err++ *)
    end;
   end;
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   PrintStatusSetup();
   errEE := 0;
   for i := 0,j=0 to (dim2) - 1 do
   begin
    if memEE[i] not =0xFF then
    begin
     bufferU[Inc(j)] := SPI_WRITE;
     bufferU[Inc(j)] := 4;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := SPI_WRITE;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $A0;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := SPI_READ;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     PacketIO(7+2*4*Tbyte);
     PrintStatus(strings[S_CodeWriting], i*100/dim2, i);
     for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
     begin
     end;
     if z = DIMBUF-2 or memEE[i] not =bufferI[z+2] then
     begin
      (* TODO gtk2laz: unrecognised statement: errEE++ *)
     end;
    end;
   end;
   PrintMessage1(strings[S_ComplErr], errEE);
   err := err + errEE;
  end;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 0;
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

procedure WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  Rtry: Integer;
  maxTry: Integer;
  signature: array of Byte;
  w: Integer;
  v: Integer;
  c: Integer;
  err++: Telse;
  errEE: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  (* TODO gtk2laz: do-while without while: double Tbyte *)
  err := 0;
  Rtry := 0;
  maxTry := 0;
  (* TODO gtk2laz: array initializer: signature[]={0,0,0}; *)
  if dim>0x20000 or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  else{ 		size := dim; 		memCODE=(unsigned char*)realloc(memCODE,dim); 	} 	if(size%(page*2)){	 		j=size; 		dim=(j/(page*2)+1)*page*2; 		memCODE=(unsigned char*)realloc(memCODE,dim); 		for(;j<dim;Inc(j)) memCODE[j]=0xFF; 	} 	if(dim2>sizeEE) dim2=sizeEE;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := VREG_DIS;
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
  Tbyte := SyncSPI();
  if Tbyte = 0 then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1.5+3*4.5*Tbyte);
  if saveLog then
   WriteLogIO();
  for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
  begin
  end;
  signature[0] := bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[1] := bufferI[z+2];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;z<DIMBUF-2&&bufferI[z]!=SPI_READ;z++) *)
  // init: z+=3
  while z<DIMBUF-2 and bufferI[z] not =SPI_READ do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[2] := bufferI[z+2];
  PrintMessage3('CHIP ID:%02X%02X%02X\r' + LineEnding + '', signature[0], signature[1], signature[2]);
  AtmelID(signature);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 5000 shr 8;
  bufferU[Inc(j)] := 5000&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1+4*Tbyte);
  msDelay(15);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_StartCodeProg]);
  PrintStatusSetup();
  w := 0;
  for i := 0 to (dim) - 1 do
  begin
   for z := i,v=0 to (i+page*2) - 1 do
   begin
   end;
   if v then
   begin
    for k := 0,j=0,v=0 to (page) - 1 do
    begin
     w := IfThen((page-k)<(DIMBUF-6)/2, (page-k), (DIMBUF-6)/2);
     bufferU[Inc(j)] := AT_LOAD_DATA;
     bufferU[Inc(j)] := w;
     bufferU[Inc(j)] := k shr 8;
     bufferU[Inc(j)] := k;
     for z := 0 to (w*2) - 1 do
     begin
     end;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     PacketIO(1.5+w*9*Tbyte);
     k := k + w;
    end;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $4C;
    bufferU[Inc(j)] := i shr 9;
    bufferU[Inc(j)] := i shr 1;
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := WAIT_T3;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    j := 0;
    PacketIO(6+4*Tbyte);
    PrintStatus(strings[S_CodeWriting], i*100/dim, i);
    if RWstop then
     i := dim;
    c := (DIMBUF-5)/2;
    for k := 0,j=0 to (page) - 1 do
    begin
     for Rtry := 0 to (5) - 1 do
     begin
      bufferU[Inc(j)] := AT_READ_DATA;
      bufferU[Inc(j)] := IfThen(k<(page-c), c, page-k);
      bufferU[Inc(j)] := (i+k*2) shr 9;
      bufferU[Inc(j)] := (i+k*2) shr 1;
      bufferU[Inc(j)] := FLUSH;
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
      // init: 
      while j<DIMBUF do
      begin
       (* TODO gtk2laz: unrecognised statement: j++; *)
      end;
      PacketIO(1.5+240*Tbyte);
      if bufferI[0] = AT_READ_DATA then
      begin
       (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(w=0,z=2;z<bufferI[1]*2+2&&z<DIMBUF;z++){ 							if(memCODE[i+k*2+w]!=bufferI[z]){ 								if(Rtry<4)	z=DIMBUF; 								else err++; 							} 							w++; 						} 						if(z<DIMBUF) Rtry=100 *)
       // init: w=0,z=2
       while z<bufferI[1]*2+2 and z<DIMBUF do
       begin
        if memCODE[i+k*2+w] not =bufferI[z] then
        begin
         if Rtry<4 then
          z := DIMBUF;
        end;
        (* TODO gtk2laz: unrecognised statement: z++; *)
       end;
      end;
     end;
     k := k + c;
    end;
   end;
   i := i + page*2;
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
   PrintStatusSetup();
   errEE := 0;
   for i := 0,j=0 to (dim2) - 1 do
   begin
    if memEE[i] not =0xFF then
    begin
     bufferU[Inc(j)] := SPI_WRITE;
     bufferU[Inc(j)] := 4;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := WAIT_T3;
     bufferU[Inc(j)] := SPI_WRITE;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $A0;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := SPI_READ;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     PacketIO(11+8.5*Tbyte);
     PrintStatus(strings[S_CodeWriting], i*100/dim2, i);
     for z := 0 to (DIMBUF-2 and bufferI[z] not =SPI_READ) - 1 do
     begin
     end;
     if z = DIMBUF-2 or memEE[i] not =bufferI[z+2] then
     begin
      if Rtry<4 then
      begin
       (* TODO gtk2laz: unrecognised statement: Rtry++ *)
       if Rtry>maxTry then
        maxTry := Rtry;
       (* TODO gtk2laz: unrecognised statement: i-- *)
      end
      else
      begin
       (* TODO gtk2laz: unrecognised statement: errEE++ *)
       Rtry := 0;
      end;
     end;
    end;
   end;
   PrintMessage1(strings[S_ComplErr], errEE);
   err := err + errEE;
  end;
  if AVRlock<0x100 or AVRfuse<0x100 or AVRfuse_h<0x100 or AVRfuse_x<0x100 then
  begin
   PrintMessage(strings[S_FuseAreaW]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_FuseAreaW]);
  end;
  if AVRlock<0x100 or AVRfuse<0x100 or AVRfuse_h<0x100 or AVRfuse_x<0x100 then
  begin
   PrintMessage1(strings[S_ComplErr], err_f);
  end;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 0;
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

procedure WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  t: Integer;
  sdo: Integer;
  err: Integer;
  signature: array of Byte;
  currPage: Integer;
  errEE: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  (* TODO gtk2laz: array initializer: signature[]={0,0,0}; *)
  if FWVersion<0x900 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.9.0');
   Exit;
  end;
  else{ 		size := dim; 		memCODE=(unsigned char*)realloc(memCODE,dim); 	} 	if(page and (size%(page*2))){	 		j=size; 		dim=(j/(page*2)+1)*page*2; 		memCODE=(unsigned char*)realloc(memCODE,dim); 		for(;j<dim;Inc(j)) memCODE[j]=0xFF; 	} 	if(dim2>sizeEE) dim2=sizeEE;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $FC;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SCI;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(8);
  for z := 0 to (DIMBUF-1 and bufferI[z] not =AT_HV_RTX) - 1 do
  begin
  end;
  signature[0] := bufferI[z+1];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=2;z<DIMBUF-1&&bufferI[z]!=AT_HV_RTX;z++) *)
  // init: z+=2
  while z<DIMBUF-1 and bufferI[z] not =AT_HV_RTX do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[1] := bufferI[z+1];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=2;z<DIMBUF-1&&bufferI[z]!=AT_HV_RTX;z++) *)
  // init: z+=2
  while z<DIMBUF-1 and bufferI[z] not =AT_HV_RTX do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  signature[2] := bufferI[z+1];
  PrintMessage3('CHIP ID:%02X%02X%02X\r' + LineEnding + '', signature[0], signature[1], signature[2]);
  AtmelID(signature);
  if saveLog then
   fprintf(logfile, 'CHIP ERASE' + LineEnding + '');
  j := 0;
  bufferU[Inc(j)] := AT_HV_RTX;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $64;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := READ_B;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  bufferU[Inc(j)] := READ_B;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  for t := 0,sdo=0 to (20 and sdo = 0) - 1 do
  begin
   PacketIO(2);
   for z := 0 to (DIMBUF-1 and bufferI[z] not =READ_B) - 1 do
   begin
   end;
   sdo := bufferI[z+1]&2;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, 'WRITE CODE' + LineEnding + '');
  currPage := -1;
  j := 0;
  if page = 0 then
  begin
   for i := 0,k=0 to (dim) - 1 do
   begin
    if memCODE[i] not =0xFF or memCODE[i+1] not =0xFF then
    begin
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $10;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := i shr 9;
     bufferU[Inc(j)] := $0C;
     bufferU[Inc(j)] := (i/2)&0xFF;
     bufferU[Inc(j)] := $2C;
     bufferU[Inc(j)] := memCODE[i];
     bufferU[Inc(j)] := $64;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := READ_B;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(2);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     for t := 0,sdo=0 to (20 and sdo = 0) - 1 do
     begin
      PacketIO(2);
      for z := 0 to (DIMBUF-1 and bufferI[z] not =READ_B) - 1 do
      begin
      end;
      sdo := bufferI[z+1]&2;
     end;
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $3C;
     bufferU[Inc(j)] := memCODE[i+1];
     bufferU[Inc(j)] := $74;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $7C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := READ_B;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(2);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     for t := 0,sdo=0 to (20 and sdo = 0) - 1 do
     begin
      PacketIO(2);
      for z := 0 to (DIMBUF-1 and bufferI[z] not =READ_B) - 1 do
      begin
      end;
      sdo := bufferI[z+1]&2;
     end;
     PrintStatus(strings[S_CodeWriting], i*100/dim, i);
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $68;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $78;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $7C;
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
     k := i;
     for z := 0 to (DIMBUF-1) - 1 do
     begin
      if bufferI[z] = AT_HV_RTX then
      begin
       if memCODE[k] not =bufferI[z+1] then
       begin
        PrintMessage4(strings[S_CodeVError], k, k, memCODE[k], bufferI[z+1]);
        (* TODO gtk2laz: unrecognised statement: err++ *)
       end;
       (* TODO gtk2laz: unrecognised statement: z++ *)
      end;
     end;
    end;
    i := i + 2;
   end;
  end
  else
  begin
   for i := 0 to (dim) - 1 do
   begin
    for k := 0 to (page) - 1 do
    begin
     if memCODE[i+k*2] not =0xFF or memCODE[i+k*2+1] not =0xFF then
      k := page;
    end;
    i := i + page*2;
   end;
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   errEE := 0;
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
    fprintf(logfile, 'WRITE EEPROM' + LineEnding + '');
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if memEE[i] not =0xFF then
    begin
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 7;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $11;
     bufferU[Inc(j)] := $0C;
     bufferU[Inc(j)] := i&0xFF;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := $2C;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := $6D;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $64;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := READ_B;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     PacketIO(2);
     PrintStatus(strings[S_CodeWriting], i*100/dim2, i);
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     j := 0;
     for t := 0,sdo=0 to (20 and sdo = 0) - 1 do
     begin
      PacketIO(2);
      for z := 0 to (DIMBUF-1 and bufferI[z] not =READ_B) - 1 do
      begin
      end;
      sdo := bufferI[z+1]&2;
     end;
     bufferU[Inc(j)] := AT_HV_RTX;
     bufferU[Inc(j)] := 5;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $03;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := i shr 8;
     bufferU[Inc(j)] := $0C;
     bufferU[Inc(j)] := i&0xFF;
     bufferU[Inc(j)] := $68;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := FLUSH;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(2);
     for z := 0 to (DIMBUF-1 and bufferI[z] not =AT_HV_RTX) - 1 do
     begin
     end;
     if memEE[i] not =bufferI[z+1] then
     begin
      PrintMessage4(strings[S_CodeVError], i, i, memEE[i], bufferI[z+1]);
      (* TODO gtk2laz: unrecognised statement: errEE++ *)
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
   end;
   err := err + errEE;
   if err>=max_err then
   begin
    PrintMessage('\r' + LineEnding + '');
    PrintMessage1(strings[S_MaxErr], err);
   end;
  end;
  if AVRlock<0x100 or AVRfuse<0x100 or AVRfuse_h<0x100 or AVRfuse_x<0x100 then
   PrintMessage(strings[S_FuseAreaW]);
  if AVRfuse<0x100 then
  begin
   if saveLog then
    fprintf(logfile, 'WRITE FUSE' + LineEnding + '');
   bufferU[Inc(j)] := AT_HV_RTX;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $40;
   bufferU[Inc(j)] := $2C;
   bufferU[Inc(j)] := AVRfuse;
   bufferU[Inc(j)] := $64;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := READ_B;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   j := 0;
   PacketIO(2);
   for z := 0 to (DIMBUF-1 and bufferI[z] not =READ_B) - 1 do
   begin
   end;
   sdo := bufferI[z+1]&2;
   bufferU[Inc(j)] := READ_B;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   for i := 0 to (20 and sdo = 0) - 1 do
   begin
    PacketIO(2);
    for z := 0 to (DIMBUF-1 and bufferI[z] not =READ_B) - 1 do
    begin
    end;
    sdo := bufferI[z+1]&2;
   end;
   j := 0;
   bufferU[Inc(j)] := AT_HV_RTX;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $68;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
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
   for z := 0 to (DIMBUF-1 and bufferI[z] not =AT_HV_RTX) - 1 do
   begin
   end;
   if z = DIMBUF-1 or AVRfuse not =bufferI[z+1] then
   begin
    PrintMessage3(strings[S_WErr1], 'fuse', AVRfuse, bufferI[z+1]);
    (* TODO gtk2laz: unrecognised statement: err_f++ *)
   end;
  end;
  if AVRlock<0x100 or AVRfuse<0x100 or AVRfuse_h<0x100 or AVRfuse_x<0x100 then
  begin
   PrintMessage1(strings[S_ComplErr], err_f);
  end;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 0;
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

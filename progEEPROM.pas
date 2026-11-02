unit progeeprom;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

const
  PRE = $08;
  S = $10;
  W = $20;
  ORG = $20;
  CS = 8;
  HLD = 16;
  WP = $40;
  READ_ROM = $33;
  MATCH_ROM = $55;
  SKIP_ROM = $CC;
  SEARCH_ROM = $F0;
  WRITE_SCRATCHPAD = $0F;
  READ_SCRATCHPAD = $AA;
  COPY_SCRATCHPAD = $55;
  READ_MEMORY = $F0;
  WRITE_APP_REGISTER = $99;
  READ_STAT_REGISTER = $66;
  READ_APP_REGISTER = $C3;
  COPY_LOCK_APP_REGISTER = $5A;
  READ_SCRATCHPAD2 = $BE;
  CONVERT_TEMP = $44;
  RECALL_EE = $B8;
  READ_PWSUP = $B4;
  UNIO_READ = $03;
  UNIO_CRRD = $06;
  UNIO_WRITE = $6C;
  UNIO_WREN = $96;
  UNIO_WRDI = $91;
  UNIO_RDSR = $05;
  UNIO_WRSR = $6E;
  UNIO_ERAL = $6D;
  UNIO_SETAL = $67;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

// --- function declarations ---
procedure ReadI2C(dim: Integer; addr: Integer);
procedure WriteI2C(dim: Integer; addr: Integer; page: Integer);
procedure Read93x(dim: Integer; na: Integer; options: Integer);
procedure Write93Sx(dim: Integer; na: Integer; page: Integer);
procedure Write93Cx(dim: Integer; na: Integer; options: Integer);
procedure Read25xx(dim: Integer);
procedure Write25xx(dim: Integer; options: Integer);
procedure OW_ID(id: Integer);
procedure ReadOneWireMem(dim: Integer; options: Integer);
procedure WriteOneWireMem(dim: Integer; options: Integer);
procedure ReadDS1820;
procedure Read11xx(dim: Integer);
procedure Write11xx(dim: Integer; page: Integer);

implementation

procedure ReadI2C(dim: Integer; addr: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  AX: Integer;
  addr17: Integer;
  start: Cardinal;
  inc: Integer;
  inc: Telse;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  AX := (addr shr 4)&7;
  addr17 := (addr shr 8)&0xF;
  addr := addr and 1;
  if dim>0x30000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  hvreg := 0;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := I2C_INIT;
  bufferU[Inc(j)] := AX;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   if i<0x10000 and i>0x10000-(DIMBUF-4) then
    inc := 0x10000-i;
   inc := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   if  not addr then
   begin
    bufferU[Inc(j)] := I2C_READ;
    bufferU[Inc(j)] := inc;
    bufferU[Inc(j)] := 0xA0+((i shr 7)&0x0E);
    bufferU[Inc(j)] := i&0xFF;
   end
   else
   begin
    bufferU[Inc(j)] := I2C_READ2;
    bufferU[Inc(j)] := inc;
    bufferU[Inc(j)] := IfThen(0xA0+(i>0xFFFF, addr17, 0));
    bufferU[Inc(j)] := (i shr 8)&0xFF;
    bufferU[Inc(j)] := i&0xFF;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(8);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =I2C_READ and bufferI[j] not =I2C_READ2) - 1 do
   begin
   end;
   if j<DIMBUF-1 and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to (j+2+bufferI[j+1] and z<DIMBUF) - 1 do
    begin
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   i := i + inc;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
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
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
  end;
  PrintMessage1('Checksum: 0x%X\r' + LineEnding + '', sum&0xFFFF);
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure WriteI2C(dim: Integer; addr: Integer; page: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  AX: Integer;
  addr17: Integer;
  ack: Integer;
  ack: Telse;
  inc: Integer;
  inc: Telse;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  AX := (addr shr 4)&7;
  addr17 := (addr shr 8)&0xF;
  addr := addr and 1;
  hvreg := 0;
  if dim>0x30000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := I2C_INIT;
  bufferU[Inc(j)] := AX;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;page>=DIMBUF-6;page>>=1) *)
  // init: 
  while page>=DIMBUF-6 do
  begin
   (* TODO gtk2laz: unrecognised statement: page>>=1; *)
  end;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := I2C_WRITE;
   if  not addr then
   begin
    bufferU[Inc(j)] := page;
    bufferU[Inc(j)] := 0xA0+((i shr 7)&0x0E);
    bufferU[Inc(j)] := i&0xFF;
   end
   else
   begin
    bufferU[Inc(j)] := page+1;
    bufferU[Inc(j)] := IfThen(0xA0+(i>0xFFFF, addr17, 0));
    bufferU[Inc(j)] := (i shr 8)&0xFF;
    bufferU[Inc(j)] := i&0xFF;
   end;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(3);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =I2C_WRITE) - 1 do
   begin
   end;
   if bufferI[j] not =I2C_WRITE or bufferI[j+1]>=0xFA then
    i := dim+10;
   PrintStatus(strings[S_CodeWriting2], i*100/(dim), i);
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   ack := $FD;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(j=0;ack==0xFD&&j<20;j++){	 			PacketIO(2); 			for(j=0;j<DIMBUF-1&&bufferI[j]!=I2C_WRITE;j++); 			if(bufferI[j]!=I2C_WRITE||bufferI[j+1]>=0xFA) ack=0xFD; 			else ack=bufferI[j+1]; 		} 		j=0 *)
   // init: j=0
   while ack = 0xFD and j<20 do
   begin
    PacketIO(2);
    for j := 0 to (DIMBUF-1 and bufferI[j] not =I2C_WRITE) - 1 do
    begin
    end;
    if bufferI[j] not =I2C_WRITE or bufferI[j+1]>=0xFA then
     ack := $FD;
    ack := bufferI[j+1];
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   i := i + page;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  k := 0;
  for i := 0,j=0 to (dim) - 1 do
  begin
   if i<0x10000 and i>0x10000-(DIMBUF-4) then
    inc := 0x10000-i;
   inc := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   if  not addr then
   begin
    bufferU[Inc(j)] := I2C_READ;
    bufferU[Inc(j)] := inc;
    bufferU[Inc(j)] := 0xA0+((i shr 7)&0x0E);
    bufferU[Inc(j)] := i&0xFF;
   end
   else
   begin
    bufferU[Inc(j)] := I2C_READ2;
    bufferU[Inc(j)] := inc;
    bufferU[Inc(j)] := IfThen(0xA0+(i>0xFFFF, addr17, 0));
    bufferU[Inc(j)] := (i shr 8)&0xFF;
    bufferU[Inc(j)] := i&0xFF;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(8);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =I2C_READ and bufferI[j] not =I2C_READ2) - 1 do
   begin
   end;
   if (bufferI[j] = I2C_READ or bufferI[j] = I2C_READ2) and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to ((j+2+bufferI[j+1]) and z<DIMBUF) - 1 do
    begin
     if memEE[Inc(k)] not =bufferI[z] then
     begin
      PrintMessage('\r' + LineEnding + '');
      PrintMessage4(strings[S_CodeVError], i+z-3, i+z-3, memEE[k-1], bufferI[z]);
      (* TODO gtk2laz: unrecognised statement: err++ *)
     end;
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   i := i + inc;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Read93x(dim: Integer; na: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  x8: Integer;
  start: Cardinal;
  dim2: Integer;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if dim>0x3000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read93x(%d,%d,%d)    (0x%X,0x%X)' + LineEnding + '', dim, na, options, dim, na);
  end;
  sizeEE := dim;
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := uW_INIT;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(x8, S, S+ORG);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();
  dim2 := IfThen(x8, dim, dim/2);
  (* TODO gtk2laz: complex for loop: for(i=0;i<dim2;){ 		for(j=0;j<DIMBUF-14&&i<dim2;){ 			bufferU[j++]=uWTX; 			bufferU[j++]=na+3;				 			bufferU[j++]=0xC0+((i>>(na-5))&0x1F);				 			bufferU[j++]=(i<<(13-na))&0xFF; 			bufferU[j++]=uWRX; *)
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
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
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
  end;
  PrintMessage1('Checksum: 0x%X\r' + LineEnding + '', sum&0xFFFF);
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write93Sx(dim: Integer; na: Integer; page: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  addr: Integer;
  n: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  if dim>0x1000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if page>48 then
   page := 48;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write93Sx(%d,%d,%d)    (0x%X,0x%X)' + LineEnding + '', dim, na, page, dim, na);
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uW_INIT;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := S+W;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $98;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := W;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := S+W+PRE;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $98;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := W+PRE;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := S+W+PRE;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := W+PRE;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := S+W;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $98;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := W;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := S+W+PRE;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $C0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWRX;
  bufferU[Inc(j)] := 10;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := W+PRE;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();
  addr := 0;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := W;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := S+W;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := uWTX;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $E0;
   bufferU[Inc(j)] := uWTX;
   bufferU[Inc(j)] := na;
   bufferU[Inc(j)] := addr shr 8;
   if na>8 then
    bufferU[Inc(j)] := addr&0xFF;
   bufferU[Inc(j)] := uWTX;
   bufferU[Inc(j)] := 8*page;
   for k := 0 to (page) - 1 do
   begin
    bufferU[Inc(j)] := memEE[i+k+1];
    bufferU[Inc(j)] := memEE[i+k];
    k := k + 2;
   end;
   bufferU[Inc(j)] := W;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := S+W;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   j := 0;
   for j := 0 to (DIMBUF-1 and bufferI[j] not =uWTX) - 1 do
   begin
   end;
   if bufferI[j] not =uWTX or bufferI[j+1]>=0xFA then
    i := dim+10;
   bufferU[Inc(j)] := uWRX;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   for z := 0,k=0 to (30 and  not k) - 1 do
   begin
    PacketIO(2);
    for j := 0 to (DIMBUF-1 and bufferI[j] not =uWRX) - 1 do
    begin
    end;
    if bufferI[j] = uWRX then
     k := bufferI[j+2];
   end;
   PrintStatus(strings[S_CodeWriting2], i*100/(dim), i);
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   i := i + page,addr+=(0x10000 shr na)*page/2;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  j := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := S;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $C0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  k := 0;
  n := (DIMBUF-2);
  if n>30 then
   n := 30;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := uWRX;
   bufferU[Inc(j)] := IfThen(i<(dim-n), n*8, (dim-i)*8);
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(j=0;bufferI[j]!=uWRX&&j<DIMBUF-1;j++) *)
   // init: j=0
   while bufferI[j] not =uWRX and j<DIMBUF-1 do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   if bufferI[j] = uWRX then
   begin
    for z := j+2 to (j+2+bufferI[j+1]/8 and z<DIMBUF) - 1 do
    begin
     if memEE[k+1] not =bufferI[z] then
     begin
      PrintMessage('\r' + LineEnding + '');
      PrintMessage4(strings[S_CodeVError], i+z-3, i+z-3, memEE[k+1], bufferI[z]);
      (* TODO gtk2laz: unrecognised statement: err++ *)
     end;
     z := z + 2,k+=2;
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   i := i + n;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write93Cx(dim: Integer; na: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  addr: Integer;
  dim2: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  if dim>0x1000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write93Cx(%d,%d,%d)    (0x%X,0x%X)' + LineEnding + '', dim, na, options, dim, na);
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uW_INIT;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, S+ORG+PRE, S+PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $98;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, ORG+PRE, PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, S+ORG+PRE, S+PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWTX;
  bufferU[Inc(j)] := na+3;
  bufferU[Inc(j)] := $90;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, ORG+PRE, PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, S+ORG+PRE, S+PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := uWRX;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := uWRX;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  for i := 0,k=0 to (30 and  not k) - 1 do
  begin
   PacketIO(2);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =uWRX) - 1 do
   begin
   end;
   if bufferI[j] = uWRX then
    k := bufferI[j+2];
  end;
  PrintStatusSetup();
  addr := 0;
  j := 0;
  for i := 0 to (dim) - 1 do
  begin
   if memEE[i]<0xFF or (options = 0 and memEE[i+1]<0xFF) then
   begin
    bufferU[Inc(j)] := EXT_PORT;
    bufferU[Inc(j)] := IfThen(options = 0, ORG+PRE, PRE);
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := EXT_PORT;
    bufferU[Inc(j)] := IfThen(options = 0, S+ORG+PRE, S+PRE);
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := uWTX;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := uWTX;
    bufferU[Inc(j)] := na;
    bufferU[Inc(j)] := addr shr 8;
    if na>8 then
     bufferU[Inc(j)] := addr&0xFF;
    bufferU[Inc(j)] := uWTX;
    if options = 0 then
    begin
     bufferU[Inc(j)] := 16;
     bufferU[Inc(j)] := memEE[i+1];
     bufferU[Inc(j)] := memEE[i];
    end
    else
    begin
     bufferU[Inc(j)] := 8;
     bufferU[Inc(j)] := memEE[i];
    end;
    bufferU[Inc(j)] := IfThen(options = 0, ORG+PRE, PRE);
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := EXT_PORT;
    bufferU[Inc(j)] := IfThen(options = 0, S+ORG+PRE, S+PRE);
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := uWRX;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(2);
    PrintStatus(strings[S_CodeWriting2], i*100/(dim), i);
    if RWstop then
     i := dim;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    for z := 0,k=0 to (30 and  not k) - 1 do
    begin
     PacketIO(2);
     for j := 0 to (DIMBUF-1 and bufferI[j] not =uWRX) - 1 do
     begin
     end;
     if bufferI[j] = uWRX then
      k := bufferI[j+2];
    end;
   end;
   i := i + IfThen(options = 0, 2, 1,addr+=0x10000 shr na);
  end;
  PrintStatusEnd();
  if i not =dim then
  begin
   PrintMessage2(strings[S_CodeWError4], i, dim);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  j := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, ORG+PRE, PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := IfThen(options = 0, S+ORG+PRE, S+PRE);
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  k := 0;
  dim2 := IfThen(options = 0, dim/2, dim);
  (* TODO gtk2laz: complex for loop: for(i=0;i<dim2;){ 		for(j=0;j<DIMBUF-14&&i<dim2;){ 			bufferU[j++]=uWTX; 			bufferU[j++]=na+3;				 			bufferU[j++]=0xC0+((i>>(na-5))&0x1F);				 			bufferU[j++]=(i<<(13-na))&0xFF; 			bufferU[j++]=uWRX; *)
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Read25xx(dim: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  ID: Integer;
  start: Cardinal;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if dim>0x1000000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := SPI_INIT;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $9F;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_WRITE;
  if dim>0x10000 then
  begin
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end
  else if dim>0x200 then
  begin
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end
  else
  begin
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  for z := 0 to (DIMBUF-4 and bufferI[z] not =SPI_READ) - 1 do
  begin
  end;
  ID := (bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  if ID>0 and ID not =0xFFFFFF then
   PrintMessage1('DEVICE ID=0x%06X\r' + LineEnding + '', ID);
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(4);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =SPI_READ) - 1 do
   begin
   end;
   if bufferI[j] = SPI_READ and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to (j+2+bufferI[j+1] and z<DIMBUF) - 1 do
    begin
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   i := i + DIMBUF-4;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
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
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
  end;
  PrintMessage1('Checksum: 0x%X\r' + LineEnding + '', sum&0xFFFF);
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write25xx(dim: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  ID: Integer;
  err: Integer;
  page: Integer;
  pp: Integer;
  pp: Integer;
  i0: Integer;
  k2: Integer;
  valid: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  page := options&0xFFF;
  if dim>0x1000000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := SPI_INIT;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $9F;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := WP;
  if options&0x2000 then
  begin
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $35;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  for z := 0 to (DIMBUF-4 and bufferI[z] not =SPI_READ) - 1 do
  begin
  end;
  ID := (bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  if ID>0 and ID not =0xFFFFFF then
  begin
   PrintMessage1('DEVICE ID=0x%06X\r' + LineEnding + '', ID);
   if saveLog then
    fprintf(logfile, 'DEVICE ID=0x%06X' + LineEnding + '', ID);
  end;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 6;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := WP;
  if options&0x2000 then
  begin
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end
  else
  begin
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 0;
  end;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := SPI_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := SPI_READ;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := CS+HLD;
  bufferU[Inc(j)] := WP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  if options&0x1000 then
  begin
   PrintMessage(strings[S_StartErase]);
   if saveLog then
    fprintf(logfile, '%s' + LineEnding + '', strings[S_StartErase]);
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   if options&0x2000 then
   begin
    bufferU[Inc(j)] := EXT_PORT;
    bufferU[Inc(j)] := HLD;
    bufferU[Inc(j)] := WP;
    bufferU[Inc(j)] := SPI_WRITE;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $35;
    bufferU[Inc(j)] := SPI_READ;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := EXT_PORT;
    bufferU[Inc(j)] := CS+HLD;
    bufferU[Inc(j)] := WP;
   end;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $C7;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(pp=1,j=0;pp&&j<400;j++){	 			PacketIO(2); 			msDelay(100); 			for(z=0;z<DIMBUF-1&&bufferI[z]!=SPI_READ;z++); 			pp=bufferI[z+2]&1;	 			PrintStatus(strings[S_StartErase],0,0);	 		} 		if(saveLog) fp *)
   // init: pp=1,j=0
   while pp and j<400 do
   begin
    PacketIO(2);
    msDelay(100);
    for z := 0 to (DIMBUF-1 and bufferI[z] not =SPI_READ) - 1 do
    begin
    end;
    pp := bufferI[z+2]&1;
    PrintStatus(strings[S_StartErase], 0, 0);
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PrintMessage(strings[S_Compl]);
   PrintStatus(strings[S_Compl], 0, 0);
  end;
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_EEAreaW]);
  for i := 0,j=0 to (dim) - 1 do
  begin
   if options&0x1000 then
   begin
    (* TODO gtk2laz: complex for loop: for(k=page;k==page&&i<dim-page;){ 				for(k=0;k<page;k++){ if(memEE[i+k]<0xFF) k=page;} 				if(k==page) i+=page; 			} *)
   end;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   if dim>0x10000 then
   begin
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := 2;
    bufferU[Inc(j)] := i shr 16;
    bufferU[Inc(j)] := (i shr 8)&0xFF;
    bufferU[Inc(j)] := i&0xFF;
   end
   else if dim>0x200 then
   begin
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := 2;
    bufferU[Inc(j)] := i shr 8;
    bufferU[Inc(j)] := i&0xFF;
   end
   else
   begin
    bufferU[Inc(j)] := 2;
    bufferU[Inc(j)] := IfThen(2+(i&0x100, 8, 0));
    bufferU[Inc(j)] := i&0xFF;
   end;
   (* TODO gtk2laz: complex for loop: for(k=0;k<page;){ 			bufferU[j++]=SPI_WRITE; 			bufferU[j++]=pp; 			for(;k<page&&pp;k++,pp--) bufferU[j++]=memEE[i+k]; 			bufferU[j++]=FLUSH; 			for(;j<DIMBUF;j++) bufferU[j]=0x0; 			PacketIO(2); 			f *)
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(2);
   j := 0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := SPI_WRITE;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS+HLD;
   bufferU[Inc(j)] := WP;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(pp=1,j=0;pp&&j<50;j++){	 			PacketIO(2); 			for(z=0;z<DIMBUF-1&&bufferI[z]!=SPI_READ;z++); 			pp=bufferI[z+2]&1;	 		} 		PrintStatus(strings[S_CodeWriting2],i*100/(dim),i) *)
   // init: pp=1,j=0
   while pp and j<50 do
   begin
    PacketIO(2);
    for z := 0 to (DIMBUF-1 and bufferI[z] not =SPI_READ) - 1 do
    begin
    end;
    pp := bufferI[z+2]&1;
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
   i := i + page;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_EEV]);
  PrintStatusSetup();
  j := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := HLD;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := SPI_WRITE;
  if dim>0x10000 then
  begin
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end
  else if dim>0x200 then
  begin
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end
  else
  begin
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := 0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  k := 0;
  for i := 0,j=0 to (dim) - 1 do
  begin
   if options&0x1000 then
   begin
    i0 := i;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(valid=0;!valid&&i<dim;i+=valid?0:DIMBUF-4){		 				for(k2=0;k2<DIMBUF-4&&!valid&&i+k2<dim;k2++) if(memEE[i+k2]<0xFF) valid=1; 			} 			if(i>=dim) break *)
    // init: valid=0
    while  not valid and i<dim do
    begin
     for k2 := 0 to (DIMBUF-4 and  not valid and i+k2<dim) - 1 do
     begin
     end;
     i := i + IfThen(valid, 0, DIMBUF-4);
    end;
    if i>i0 then
    begin
     j := 0;
     bufferU[Inc(j)] := EXT_PORT;
     bufferU[Inc(j)] := CS+HLD;
     bufferU[Inc(j)] := WP;
     bufferU[Inc(j)] := EXT_PORT;
     bufferU[Inc(j)] := HLD;
     bufferU[Inc(j)] := 0;
     bufferU[Inc(j)] := SPI_WRITE;
     if dim>0x10000 then
     begin
      bufferU[Inc(j)] := 4;
      bufferU[Inc(j)] := 3;
      bufferU[Inc(j)] := i shr 16;
      bufferU[Inc(j)] := (i shr 8)&0xFF;
      bufferU[Inc(j)] := i&0xFF;
     end
     else if dim>0x200 then
     begin
      bufferU[Inc(j)] := 3;
      bufferU[Inc(j)] := 3;
      bufferU[Inc(j)] := i shr 8;
      bufferU[Inc(j)] := i&0xFF;
     end
     else
     begin
      bufferU[Inc(j)] := 2;
      bufferU[Inc(j)] := IfThen(3+(i&0x100, 8, 0));
      bufferU[Inc(j)] := i&0xFF;
     end;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
     // init: 
     while j<DIMBUF do
     begin
      (* TODO gtk2laz: unrecognised statement: j++; *)
     end;
     PacketIO(2);
     j := 0;
    end;
   end;
   bufferU[Inc(j)] := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(4);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =SPI_READ) - 1 do
   begin
   end;
   if bufferI[j] = SPI_READ and bufferI[j+1]<0xFA then
   begin
    for z := 0 to (bufferI[j+1] and z<DIMBUF) - 1 do
    begin
     if memEE[i+z] not =bufferI[z+j+2] then
     begin
      PrintMessage4(strings[S_CodeVError], i+z, i+z, memEE[i+z], bufferI[z+3]);
      (* TODO gtk2laz: unrecognised statement: err++ *)
     end;
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   i := i + DIMBUF-4;
  end;
  if i<dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, i);
  end;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure OW_ID(id: Integer);
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (sizeof(OW_LIST)/sizeof(OW_LIST[0])) - 1 do
  begin
   if id = OW_LIST[i].id then
   begin
    sprintf(s, OW_LIST[i].device, id);
    PrintMessage(s);
    Exit;
   end;
  end;
  PrintMessage(s);
end;

procedure ReadOneWireMem(dim: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  start: Cardinal;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if FWVersion<0x800 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.8.0');
   Exit;
  end;
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := uW_INIT;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := OW_RESET;
  bufferU[Inc(j)] := OW_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := READ_ROM;
  bufferU[Inc(j)] := OW_READ;
  bufferU[Inc(j)] := 8;
  if dim<=32 then
  begin
   bufferU[Inc(j)] := OW_WRITE;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := READ_MEMORY;
   bufferU[Inc(j)] := 0;
  end
  else
  begin
   bufferU[Inc(j)] := OW_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := READ_MEMORY;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(12);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=OW_RESET&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =OW_RESET and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if bufferI[z] = OW_RESET and bufferI[z+1] = 0 then
  begin
   PrintMessage(strings[S_ComErr]);
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
   Exit;
  end;
  if bufferI[z] = OW_READ and z<DIMBUF-9 then
  begin
   PrintMessage1('Family code: 0x%02X ', bufferI[z+2]);
   OW_ID(bufferI[z+2]);
   PrintMessage3('Serial ID: 0x%02X%02X%02X', bufferI[z+3], bufferI[z+4], bufferI[z+5]);
   PrintMessage3('%02X%02X%02X', bufferI[z+6], bufferI[z+7], bufferI[z+8]);
   PrintMessage1('\r' + LineEnding + 'CRC: 0x%02X\r' + LineEnding + '', bufferI[z+9]);
  end;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := OW_READ;
   bufferU[Inc(j)] := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(37);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(j=0;bufferI[j]!=OW_READ&&j<DIMBUF;j++) *)
   // init: j=0
   while bufferI[j] not =OW_READ and j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   if bufferI[j] = OW_READ and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to (j+2+bufferI[j+1] and z<DIMBUF) - 1 do
    begin
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   i := i + DIMBUF-4;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
   sizeEE := k;
  end;
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
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
  end;
  PrintMessage1('Checksum: 0x%X\r' + LineEnding + '', sum&0xFFFF);
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure WriteOneWireMem(dim: Integer; options: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  page: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  hvreg := 0;
  if FWVersion<0x800 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.8.0');
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := uW_INIT;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := OW_RESET;
  bufferU[Inc(j)] := OW_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := READ_ROM;
  bufferU[Inc(j)] := OW_READ;
  bufferU[Inc(j)] := 8;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(12);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=OW_RESET&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =OW_RESET and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if bufferI[z] = OW_RESET and bufferI[z+1] = 0 then
  begin
   PrintMessage(strings[S_ComErr]);
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
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  if bufferI[z] = OW_READ then
  begin
   PrintMessage1('Family code: 0x%02X ', bufferI[z+2]);
   OW_ID(bufferI[z+2]);
   PrintMessage3('Serial ID: 0x%02X%02X%02X', bufferI[z+3], bufferI[z+4], bufferI[z+5]);
   PrintMessage3('%02X%02X%02X', bufferI[z+6], bufferI[z+7], bufferI[z+8]);
   PrintMessage1('\r' + LineEnding + 'CRC: 0x%02X\r' + LineEnding + '', bufferI[z+9]);
  end;
  page := IfThen(options = 0, 8, 32);
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := OW_RESET;
   bufferU[Inc(j)] := OW_WRITE;
   bufferU[Inc(j)] := IfThen(page+(dim<=32, 3, 4));
   bufferU[Inc(j)] := SKIP_ROM;
   bufferU[Inc(j)] := WRITE_SCRATCHPAD;
   bufferU[Inc(j)] := i&0xFF;
   if dim>32 then
    bufferU[Inc(j)] := i shr 8;
   for k := 0 to (page) - 1 do
   begin
   end;
   bufferU[Inc(j)] := OW_RESET;
   bufferU[Inc(j)] := OW_WRITE;
   bufferU[Inc(j)] := IfThen(dim<=32, 3, 5);
   bufferU[Inc(j)] := SKIP_ROM;
   bufferU[Inc(j)] := COPY_SCRATCHPAD;
   if dim<=32 then
    bufferU[Inc(j)] := $A5;
   else{ 			bufferU[Inc(j)] := i&0xFF; 			bufferU[Inc(j)]=i shr 8; 			bufferU[Inc(j)]=page-1; 		} 		bufferU[Inc(j)]=FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(6+0.8*page);
   msDelay(10);
   j := 0;
   PrintStatus(strings[S_CodeWriting2], i*100/(dim), i);
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
   i := i + page;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_EEV]);
  PrintStatusSetup();
  k := 0;
  bufferU[Inc(j)] := OW_RESET;
  bufferU[Inc(j)] := OW_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := SKIP_ROM;
  if dim<=32 then
  begin
   bufferU[Inc(j)] := OW_WRITE;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := READ_MEMORY;
   bufferU[Inc(j)] := 0;
  end
  else
  begin
   bufferU[Inc(j)] := OW_WRITE;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := READ_MEMORY;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(10);
  j := 0;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := OW_READ;
   bufferU[Inc(j)] := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(37);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(j=0;bufferI[j]!=OW_READ&&j<DIMBUF;j++) *)
   // init: j=0
   while bufferI[j] not =OW_READ and j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   if bufferI[j] = OW_READ and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to (j+2+bufferI[j+1] and z<DIMBUF) - 1 do
    begin
     if memEE[Inc(k)] not =bufferI[z] then
     begin
      PrintMessage('\r' + LineEnding + '');
      PrintMessage4(strings[S_CodeVError], i+z-(j+2), i+z-(j+2), memEE[k-1], bufferI[z]);
      (* TODO gtk2laz: unrecognised statement: err++ *)
     end;
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   i := i + DIMBUF-4;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
   sizeEE := k;
  end;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure ReadDS1820;
var
  z: Integer;
  j: Integer;
  if(bufferI[z+2]==0x28) TLSB=0.0625: Telse;
  T: Integer;
  stop: Cardinal;
begin
  z := 0;
  (* TODO gtk2laz: do-while without while: double TLSB=0.5 *)
  hvreg := 0;
  if FWVersion<0x800 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.8.0');
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := uW_INIT;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := OW_RESET;
  bufferU[Inc(j)] := OW_WRITE;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := READ_ROM;
  bufferU[Inc(j)] := OW_READ;
  bufferU[Inc(j)] := 8;
  bufferU[Inc(j)] := OW_RESET;
  bufferU[Inc(j)] := OW_WRITE;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := SKIP_ROM;
  bufferU[Inc(j)] := CONVERT_TEMP;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(16);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=OW_RESET&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =OW_RESET and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if bufferI[z] = OW_RESET and bufferI[z+1] = 0 then
  begin
   PrintMessage(strings[S_ComErr]);
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
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  if z<DIMBUF-9 then
  begin
   PrintMessage1('Family code: 0x%02X ', bufferI[z+2]);
   OW_ID(bufferI[z+2]);
   if bufferI[z+2] = 0x10 then
    TLSB := 0.5;
   PrintMessage3('Serial ID: 0x%02X%02X%02X', bufferI[z+3], bufferI[z+4], bufferI[z+5]);
   PrintMessage3('%02X%02X%02X', bufferI[z+6], bufferI[z+7], bufferI[z+8]);
   PrintMessage1('\r' + LineEnding + 'CRC: 0x%02X\r' + LineEnding + '', bufferI[z+9]);
  end;
  bufferU[Inc(j)] := OW_RESET;
  bufferU[Inc(j)] := OW_WRITE;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := SKIP_ROM;
  bufferU[Inc(j)] := READ_SCRATCHPAD2;
  bufferU[Inc(j)] := OW_READ;
  bufferU[Inc(j)] := 8;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(10);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=OW_READ&&z<DIMBUF-2;z++) *)
  // init: z=0
  while bufferI[z] not =OW_READ and z<DIMBUF-2 do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  T := bufferI[z+2]+(bufferI[z+3] shl 8);
  if T>0xF000 then
   T := T or $FFFF0000;
  PrintMessage2('T=%.4f�C  (0x%04X)\r' + LineEnding + '', T*TLSB, T);
  PrintMessage2('T=%.4f°C  (0x%04X)\r' + LineEnding + '', T*TLSB, T);
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
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Read11xx(dim: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  start: Cardinal;
  stop: Cardinal;
  sum: Integer;
begin
  k := 0;
  z := 0;
  hvreg := 0;
  if FWVersion<0x800 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.8.0');
   Exit;
  end;
  if memEE then
   FreeMem(memEE);
  memEE := malloc(dim);
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := UNIO_COM;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := UNIO_RDSR;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := UNIO_COM;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := IfThen(i<dim-(DIMBUF-5), DIMBUF-5, dim-i);
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := UNIO_READ;
   bufferU[Inc(j)] := i shr 8;
   bufferU[Inc(j)] := i&0xFF;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(14);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =UNIO_COM) - 1 do
   begin
   end;
   if bufferI[j] = UNIO_COM and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to (j+2+bufferI[j+1] and z<DIMBUF) - 1 do
    begin
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   i := i + DIMBUF-5;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
   sizeEE := k;
  end
  else
   PrintMessage(strings[S_Compl]);
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
  DisplayEE();
  sum := 0;
  for i := 0 to (sizeEE) - 1 do
  begin
  end;
  PrintMessage1('Checksum: 0x%X\r' + LineEnding + '', sum&0xFFFF);
  sprintf(str, strings[S_End], (stop-start)/1000.0);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write11xx(dim: Integer; page: Integer);
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  status: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  if FWVersion<0x800 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.8.0');
   Exit;
  end;
  if dim>=0x10000 or dim<0 then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := VREG_DIS;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := UNIO_STBY;
  bufferU[Inc(j)] := UNIO_COM;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := UNIO_WREN;
  bufferU[Inc(j)] := UNIO_COM;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := UNIO_RDSR;
  bufferU[Inc(j)] := UNIO_COM;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := UNIO_WRSR;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := UNIO_COM;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := UNIO_RDSR;
  bufferU[Inc(j)] := UNIO_COM;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := UNIO_WREN;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(25);
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;page>=DIMBUF-8;page>>=1) *)
  // init: 
  while page>=DIMBUF-8 do
  begin
   (* TODO gtk2laz: unrecognised statement: page>>=1; *)
  end;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := UNIO_COM;
   bufferU[Inc(j)] := 4+page;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := UNIO_WRITE;
   bufferU[Inc(j)] := i shr 8;
   bufferU[Inc(j)] := i&0xFF;
   for k := 0 to (page) - 1 do
   begin
   end;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO((5+page)*0.2+2);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =UNIO_COM) - 1 do
   begin
   end;
   if bufferI[j] not =UNIO_COM or bufferI[j+1]>=0xFA then
    i := dim+10;
   PrintStatus(strings[S_CodeWriting2], i*100/(dim), i);
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := UNIO_RDSR;
   bufferU[Inc(j)] := UNIO_COM;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := UNIO_WREN;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   status := 1;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(k=0;status&&k<20;k++){	 			PacketIO(2); 			for(j=0;j<DIMBUF-1&&bufferI[j]!=UNIO_COM;j++); 			if(bufferI[j]==UNIO_COM) status=bufferI[j+2]&1; 		} 		j=0 *)
   // init: k=0
   while status and k<20 do
   begin
    PacketIO(2);
    for j := 0 to (DIMBUF-1 and bufferI[j] not =UNIO_COM) - 1 do
    begin
    end;
    if bufferI[j] = UNIO_COM then
     status := bufferI[j+2]&1;
    (* TODO gtk2laz: unrecognised statement: k++; *)
   end;
   i := i + page;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  k := 0;
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := UNIO_COM;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := IfThen(i<dim-(DIMBUF-4), DIMBUF-4, dim-i);
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := UNIO_READ;
   bufferU[Inc(j)] := i shr 8;
   bufferU[Inc(j)] := i&0xFF;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(14);
   for j := 0 to (DIMBUF-1 and bufferI[j] not =UNIO_COM) - 1 do
   begin
   end;
   if bufferI[j] = UNIO_COM and bufferI[j+1]<0xFA then
   begin
    for z := j+2 to (j+2+bufferI[j+1] and z<DIMBUF) - 1 do
    begin
     if memEE[Inc(k)] not =bufferI[z] then
     begin
      PrintMessage('\r' + LineEnding + '');
      PrintMessage4(strings[S_CodeVError], i+z-3, i+z-3, memEE[k-1], bufferI[z]);
      (* TODO gtk2laz: unrecognised statement: err++ *)
     end;
    end;
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   i := i + DIMBUF-4;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
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
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

end.
